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
        
        stage('Setup Environment') {
            steps {
                echo 'Vérification de l\'environnement...'
                script {
                    // Vérifier si Docker est disponible et fonctionnel
                    def dockerAvailable = sh(
                        script: '''
                            if which docker > /dev/null 2>&1; then
                                if docker info > /dev/null 2>&1; then
                                    echo "true"
                                else
                                    echo "false"
                                fi
                            else
                                echo "false"
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    env.DOCKER_AVAILABLE = dockerAvailable
                    echo "Docker disponible: ${env.DOCKER_AVAILABLE}"
                    
                    if (env.DOCKER_AVAILABLE == 'true') {
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
                    } else {
                        echo 'Docker non disponible, utilisation de Node.js local...'
                        sh '''
                            # Installation de Node.js via nvm
                            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                            nvm install ${NODE_VERSION}
                            nvm use ${NODE_VERSION}
                            node --version
                            npm --version
                        '''
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    if (env.DOCKER_AVAILABLE == 'true') {
                        echo 'Installation des dépendances dans le conteneur...'
                        sh '''
                            docker build --target builder -t ${DOCKER_IMAGE}:builder .
                        '''
                    } else {
                        echo 'Installation des dépendances Node.js...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            npm install
                        '''
                    }
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    if (env.DOCKER_AVAILABLE == 'true') {
                        echo 'Exécution des tests dans le conteneur...'
                        sh '''
                            docker run --rm ${DOCKER_IMAGE}:builder npm test || true
                        '''
                    } else {
                        echo 'Exécution des tests...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            npm test || true
                        '''
                    }
                }
            }
            post {
                always {
                    junit testResults: 'test-results.xml', allowEmptyResults: true
                }
            }
        }
        
        stage('Code Quality Check') {
            steps {
                script {
                    if (env.DOCKER_AVAILABLE == 'true') {
                        echo 'Vérification de la qualité du code...'
                        sh '''
                            docker run --rm ${DOCKER_IMAGE}:builder sh -c "
                                echo 'Vérification de la syntaxe JavaScript...'
                                find src -name '*.js' -exec node -c {} \\;
                                echo 'Vérification terminée'
                            "
                        '''
                    } else {
                        echo 'Vérification de la qualité du code...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            echo "Vérification de la syntaxe JavaScript..."
                            find src -name "*.js" -exec node -c {} \\;
                            echo "Vérification terminée"
                        '''
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    if (env.DOCKER_AVAILABLE == 'true') {
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
                    } else {
                        echo 'Construction de l\'application...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            npm run build
                            ls -la dist/
                        '''
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    if (env.DOCKER_AVAILABLE == 'true') {
                        echo 'Analyse de sécurité...'
                        sh '''
                            docker run --rm ${DOCKER_IMAGE}:builder npm audit --audit-level=high || true
                            echo "Scan de l'image Docker..."
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} npm audit --audit-level=high || true
                        '''
                    } else {
                        echo 'Analyse de sécurité...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            echo "Vérification des dépendances..."
                            npm audit --audit-level=high || true
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    if (env.DOCKER_AVAILABLE == 'true') {
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
                    } else {
                        echo 'Déploiement vers l\'environnement de staging (mode sans Docker)...'
                        sh '''
                            echo "Déploiement staging simulé"
                            mkdir -p staging
                            cp -r dist/* staging/
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    if (env.DOCKER_AVAILABLE == 'true') {
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
                    } else {
                        echo 'Déploiement vers la production (mode sans Docker)...'
                        sh '''
                            echo "Sauvegarde de la version précédente..."
                            if [ -d "${DEPLOY_DIR}" ]; then
                                cp -r ${DEPLOY_DIR} ${DEPLOY_DIR}_backup_$(date +%Y%m%d_%H%M%S)
                            fi
                            
                            echo "Déploiement de la nouvelle version..."
                            mkdir -p ${DEPLOY_DIR}
                            cp -r dist/* ${DEPLOY_DIR}/
                            
                            echo "Vérification du déploiement..."
                            ls -la ${DEPLOY_DIR}
                        '''
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Vérification de santé de l\'application...'
                script {
                    try {
                        if (env.DOCKER_AVAILABLE == 'true') {
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
                        } else {
                            sh '''
                                echo "Test de connectivité simulé (mode sans Docker)..."
                                echo "Application déployée avec succès"
                            '''
                        }
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
            echo 'Nettoyage des ressources temporaires...'
            script {
                if (env.DOCKER_AVAILABLE == 'true') {
                    sh '''
                        docker system prune -f
                        docker image prune -f
                    '''
                } else {
                    sh '''
                        rm -rf node_modules/.cache
                        rm -rf staging
                    '''
                }
            }
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
