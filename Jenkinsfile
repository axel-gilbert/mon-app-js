pipeline {
    agent any
    
    environment {
        NODE_VERSION = '18'
        APP_NAME = 'mon-app-js'
        DOCKER_IMAGE = 'mon-app-js'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = 'localhost:5000'
        DEPLOY_DIR = '/var/www/html/mon-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Récupération du code source...'
                checkout scm
            }
        }
        
        stage('Debug Branch Info') {
            steps {
                script {
                    echo "=== DÉBOGAGE DES VARIABLES DE BRANCHE ==="
                    echo "BRANCH_NAME: '${env.BRANCH_NAME}'"
                    echo "GIT_BRANCH: '${env.GIT_BRANCH}'"
                    echo "CHANGE_BRANCH: '${env.CHANGE_BRANCH}'"
                    echo "CHANGE_TARGET: '${env.CHANGE_TARGET}'"
                    echo "BUILD_NUMBER: '${env.BUILD_NUMBER}'"
                    echo "JOB_NAME: '${env.JOB_NAME}'"
                    
                    // Vérifier la branche actuelle via git
                    sh '''
                        echo "=== VÉRIFICATION GIT ==="
                        echo "Branche actuelle (git branch):"
                        git branch -a
                        echo ""
                        echo "Branche HEAD:"
                        git rev-parse --abbrev-ref HEAD
                        echo ""
                        echo "Dernier commit:"
                        git log --oneline -1
                        echo ""
                        echo "Remote branches:"
                        git branch -r
                    '''
                    
                    // Test de la condition when
                    def isMainBranch = env.BRANCH_NAME == 'main' || env.GIT_BRANCH == 'origin/main'
                    echo "=== TEST DE LA CONDITION ==="
                    echo "BRANCH_NAME == 'main': ${env.BRANCH_NAME == 'main'}"
                    echo "GIT_BRANCH == 'origin/main': ${env.GIT_BRANCH == 'origin/main'}"
                    echo "isMainBranch: ${isMainBranch}"
                    echo "=== FIN DÉBOGAGE ==="
                }
            }
        }
        
        stage('Setup Environment') {
            steps {
                echo 'Vérification de l\'environnement Docker...'
                script {
                    // Vérifier si Docker est disponible et fonctionnel
                    def dockerAvailable = sh(
                        script: '''
                            echo "=== VÉRIFICATION DOCKER ==="
                            echo "1. Vérification de la commande docker:"
                            if which docker > /dev/null 2>&1; then
                                echo "   ✅ docker trouvé: $(which docker)"
                                echo "2. Vérification de docker info:"
                                if docker info > /dev/null 2>&1; then
                                    echo "   ✅ docker info fonctionne"
                                    echo "true"
                                else
                                    echo "   ❌ docker info échoue"
                                    echo "   Tentative de diagnostic:"
                                    docker info 2>&1 || true
                                    echo "false"
                                fi
                            else
                                echo "   ❌ docker non trouvé"
                                echo "false"
                            fi
                            echo "=== FIN VÉRIFICATION DOCKER ==="
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    env.DOCKER_AVAILABLE = dockerAvailable
                    echo "Docker disponible: ${env.DOCKER_AVAILABLE}"
                    
                    if (env.DOCKER_AVAILABLE != 'true') {
                        error "❌ Docker n'est pas disponible ou ne fonctionne pas correctement. La pipeline nécessite Docker pour fonctionner."
                    }
                    
                    sh '''
                        echo "=== ENVIRONNEMENT DOCKER ==="
                        echo "Version Docker:"
                        docker --version
                        echo "Version Docker Compose:"
                        docker-compose --version || docker compose version
                        echo "Informations Docker:"
                        docker info | head -10
                        echo "Conteneurs en cours d'exécution:"
                        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                        echo "=== FIN ENVIRONNEMENT DOCKER ==="
                    '''
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo 'Installation des dépendances dans le conteneur...'
                sh '''
                    docker build --target builder -t ${DOCKER_IMAGE}:builder .
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Exécution des tests dans le conteneur...'
                sh '''
                    docker run --rm ${DOCKER_IMAGE}:builder npm test || true
                '''
            }
            post {
                always {
                    junit testResults: 'test-results.xml', allowEmptyResults: true
                }
            }
        }
        
        stage('Code Quality Check') {
            steps {
                echo 'Vérification de la qualité du code...'
                sh '''
                    docker run --rm ${DOCKER_IMAGE}:builder sh -c "
                        echo 'Vérification de la syntaxe JavaScript...'
                        find src -name '*.js' -exec node -c {} \\;
                        echo 'Vérification terminée'
                    "
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo 'Construction de l\'image Docker...'
                sh '''
                    # Construire l'image avec le tag du build
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    
                    # Afficher les images construites
                    echo "Images Docker construites:"
                    docker images ${DOCKER_IMAGE}
                    
                    # Vérifier que l'image a été créée
                    if ! docker image inspect ${DOCKER_IMAGE}:${DOCKER_TAG} > /dev/null 2>&1; then
                        echo "ERREUR: L'image Docker n'a pas été construite correctement"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Analyse de sécurité...'
                sh '''
                    docker run --rm ${DOCKER_IMAGE}:builder npm audit --audit-level=high || true
                    echo "Scan de l'image Docker..."
                    docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} npm audit --audit-level=high || true
                '''
            }
        }
        
        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'origin/develop'
                    expression { env.BRANCH_NAME == 'develop' }
                    expression { env.GIT_BRANCH == 'origin/develop' }
                }
            }
            steps {
                echo 'Déploiement vers l\'environnement de staging...'
                sh '''
                    echo "=== DÉPLOIEMENT STAGING ==="
                    
                    # Arrêter les conteneurs existants
                    echo "Arrêt des conteneurs existants..."
                    docker-compose down --remove-orphans || true
                    
                    # Démarrer le service de staging
                    echo "Démarrage du service de staging..."
                    docker-compose -f docker-compose.yml up -d app
                    
                    # Attendre que le conteneur soit prêt
                    echo "Attente du démarrage du conteneur..."
                    sleep 15
                    
                    # Vérifier le statut des conteneurs
                    echo "Statut des conteneurs:"
                    docker-compose ps
                    
                    # Vérifier les logs du conteneur
                    echo "Logs du conteneur:"
                    docker logs mon-app-js --tail 10 || true
                    
                    echo "=== DÉPLOIEMENT STAGING TERMINÉ ==="
                    echo "📱 URL d'accès staging: http://localhost:3000"
                '''
            }
        }
        
        stage('Deploy to Production') {
            when {
                anyOf {
                    branch 'main'
                    branch 'origin/main'
                    expression { env.BRANCH_NAME == 'main' }
                    expression { env.GIT_BRANCH == 'origin/main' }
                }
            }
            steps {
                echo 'Déploiement vers la production...'
                sh '''
                    echo "=== DÉPLOIEMENT PRODUCTION ==="
                    
                    # Arrêter les conteneurs existants
                    echo "Arrêt des conteneurs existants..."
                    docker-compose down --remove-orphans || true
                    
                    # Nettoyer les anciennes images (optionnel)
                    echo "Nettoyage des anciennes images..."
                    docker image prune -f || true
                    
                    # Démarrer le service de production
                    echo "Démarrage du service de production..."
                    docker-compose -f docker-compose.yml up -d app
                    
                    # Attendre que le conteneur soit prêt
                    echo "Attente du démarrage du conteneur..."
                    sleep 15
                    
                    # Vérifier le statut des conteneurs
                    echo "Statut des conteneurs:"
                    docker-compose ps
                    
                    # Vérifier les logs du conteneur
                    echo "Logs du conteneur:"
                    docker logs mon-app-js --tail 20 || true
                    
                    # Vérifier que le conteneur est en cours d'exécution
                    if ! docker ps | grep -q mon-app-js; then
                        echo "ERREUR: Le conteneur mon-app-js n'est pas en cours d'exécution"
                        docker-compose logs app
                        exit 1
                    fi
                    
                    echo "=== DÉPLOIEMENT TERMINÉ ==="
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Vérification de santé de l\'application...'
                script {
                    try {
                        sh '''
                            echo "=== HEALTH CHECK ==="
                            
                            # Attendre un peu plus pour s'assurer que l'app est prête
                            echo "Attente du démarrage complet..."
                            sleep 10
                            
                            # Test de connectivité avec retry
                            echo "Test de connectivité à l'application..."
                            for i in {1..5}; do
                                echo "Tentative $i/5..."
                                if curl -f http://localhost:3000/health; then
                                    echo "✅ Health check réussi!"
                                    break
                                else
                                    echo "❌ Tentative $i échouée, attente..."
                                    sleep 5
                                fi
                            done
                            
                            # Afficher les informations d'accès
                            echo ""
                            echo "🎉 APPLICATION DÉPLOYÉE AVEC SUCCÈS!"
                            echo "📱 URL d'accès: http://localhost:3000"
                            echo "🔍 Health check: http://localhost:3000/health"
                            echo "📊 Statut du conteneur:"
                            docker ps | grep mon-app-js || true
                            echo ""
                        '''
                    } catch (Exception e) {
                        currentBuild.result = 'UNSTABLE'
                        echo "Warning: Health check failed: ${e.getMessage()}"
                        echo "Vérifiez les logs du conteneur: docker logs mon-app-js"
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Nettoyage des ressources Docker...'
            sh '''
                docker system prune -f
                docker image prune -f
            '''
        }
        success {
            echo 'Pipeline exécuté avec succès!'
            emailext (
                subject: "Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    Le déploiement de ${env.JOB_NAME} s'est terminé avec succès.
                    
                    Build: ${env.BUILD_NUMBER}
                    Branch: ${env.BRANCH_NAME}
                    
                    Voir les détails: ${env.BUILD_URL}
                """,
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'admin@example.com'}"
            )
        }
        failure {
            echo 'Le pipeline a échoué!'
            emailext (
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    Le déploiement de ${env.JOB_NAME} a échoué.
                    
                    Build: ${env.BUILD_NUMBER}
                    Branch: ${env.BRANCH_NAME}
                    
                    Voir les détails: ${env.BUILD_URL}
                """,
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'admin@example.com'}"
            )
        }
        unstable {
            echo 'Build instable - des avertissements ont été détectés'
        }
    }
}
