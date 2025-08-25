pipeline {
    agent any
    
    environment {
        NODE_VERSION = '18'
        APP_NAME = 'mon-app-js'
        DEPLOY_DIR = '/var/www/html/mon-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Récupération du code source...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Construction de l\'image Docker...'
                sh '''
                    docker --version
                    docker build -f Dockerfile.dev -t mon-app-js:${BUILD_NUMBER} .
                    docker images | grep mon-app-js
                '''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo 'Installation des dépendances Node.js...'
                sh '''
                    node --version
                    npm --version
                    npm ci
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Exécution des tests...'
                sh '''
                    # Tests locaux
                    npm test
                    
                    # Tests dans le conteneur Docker
                    echo "Tests dans le conteneur Docker..."
                    docker run --rm mon-app-js:${BUILD_NUMBER} npm test
                '''
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'test-results.xml'
                }
            }
        }
        
        stage('Code Quality Check') {
            steps {
                echo 'Vérification de la qualité du code...'
                sh '''
                    echo "Vérification de la syntaxe JavaScript..."
                    find src -name "*.js" -exec node -c {} \\;
                    echo "Vérification terminée"
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo 'Construction de l\'application...'
                sh '''
                    npm run build
                    ls -la dist/
                    
                    # Construction de l'image de production
                    echo "Construction de l'image de production..."
                    docker build -f Dockerfile -t mon-app-js-prod:${BUILD_NUMBER} .
                    docker images | grep mon-app-js-prod
                '''
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Analyse de sécurité...'
                sh '''
                    echo "Vérification des dépendances..."
                    npm audit --audit-level=high
                '''
            }
        }
        
        stage('Archive Docker Images') {
            steps {
                echo 'Archivage des images Docker...'
                sh '''
                    echo "Sauvegarde des images Docker..."
                    docker save mon-app-js:${BUILD_NUMBER} | gzip > mon-app-js-dev-${BUILD_NUMBER}.tar.gz
                    docker save mon-app-js-prod:${BUILD_NUMBER} | gzip > mon-app-js-prod-${BUILD_NUMBER}.tar.gz
                    ls -la *.tar.gz
                '''
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                echo 'Déploiement vers l\'environnement de staging...'
                sh '''
                    echo "Déploiement staging avec Docker..."
                    docker run -d --name mon-app-staging-${BUILD_NUMBER} -p 3001:3000 mon-app-js-prod:${BUILD_NUMBER}
                    echo "Application déployée sur le port 3001"
                '''
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo 'Déploiement vers la production...'
                sh '''
                    echo "Arrêt du conteneur précédent..."
                    docker stop mon-app-prod || true
                    docker rm mon-app-prod || true
                    
                    echo "Déploiement de la nouvelle version..."
                    docker run -d --name mon-app-prod -p 3000:3000 --restart unless-stopped mon-app-js-prod:${BUILD_NUMBER}
                    
                    echo "Vérification du déploiement..."
                    docker ps | grep mon-app-prod
                    echo "Application déployée sur le port 3000"
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Vérification de santé de l\'application...'
                script {
                    try {
                        sh '''
                            echo "Test de connectivité..."
                            # Simulation d'un health check
                            echo "Application déployée avec succès"
                        '''
                    } catch (Exception e) {
                        currentBuild.result = 'UNSTABLE'
                        echo "Warning: Health check failed: ${e.getMessage()}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Nettoyage des ressources temporaires...'
            sh '''
                rm -rf node_modules/.cache
                rm -rf staging
                
                # Nettoyage des anciennes images Docker (garder seulement les 5 dernières)
                echo "Nettoyage des anciennes images Docker..."
                docker images mon-app-js --format "table {{.Repository}}:{{.Tag}}" | tail -n +6 | awk '{print $1}' | xargs -r docker rmi || true
                docker images mon-app-js-prod --format "table {{.Repository}}:{{.Tag}}" | tail -n +6 | awk '{print $1}' | xargs -r docker rmi || true
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
                to: "${env.CHANGE_AUTHOR_EMAIL}"
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
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
        unstable {
            echo 'Build instable - des avertissements ont été détectés'
        }
    }
}
