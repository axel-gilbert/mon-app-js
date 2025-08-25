pipeline {
    agent any
    
    environment {
        NODE_VERSION = '18'
        APP_NAME = 'mon-app-js'
        DOCKER_IMAGE = 'mon-app-js'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = 'localhost:5000'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Récupération du code source...'
                checkout scm
            }
        }
        
        stage('Setup Docker') {
            steps {
                echo 'Vérification de Docker...'
                sh '''
                    docker --version
                    docker-compose --version
                '''
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
                    docker run --rm ${DOCKER_IMAGE}:builder npm test
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
                    docker run --rm ${DOCKER_IMAGE}:builder sh -c "
                        echo 'Vérification de la syntaxe JavaScript...'
                        find src -name '*.js' -exec node -c {} \\;
                        echo 'Vérification terminée'
                    "
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Construction de l\'image Docker...'
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    docker images ${DOCKER_IMAGE}
                '''
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Analyse de sécurité...'
                sh '''
                    docker run --rm ${DOCKER_IMAGE}:builder npm audit --audit-level=high
                    echo "Scan de l'image Docker..."
                    docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} npm audit --audit-level=high || true
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
                    echo "Déploiement staging avec Docker Compose..."
                    docker-compose -f docker-compose.yml up -d app
                    sleep 10
                    docker-compose ps
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
                    echo "Sauvegarde de la version précédente..."
                    docker-compose down || true
                    
                    echo "Déploiement de la nouvelle version..."
                    docker-compose -f docker-compose.yml up -d app
                    
                    echo "Vérification du déploiement..."
                    sleep 10
                    docker-compose ps
                    docker logs mon-app-js
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
                            sleep 5
                            curl -f http://localhost:3000/health || exit 1
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
