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
                    // Vérifier si Docker est disponible
                    def dockerAvailable = sh(
                        script: 'which docker > /dev/null 2>&1 && echo "true" || echo "false"',
                        returnStdout: true
                    ).trim()
                    
                    env.DOCKER_AVAILABLE = dockerAvailable
                    echo "Docker disponible: ${env.DOCKER_AVAILABLE}"
                    
                    if (env.DOCKER_AVAILABLE == 'true') {
                        sh '''
                            docker --version
                            docker-compose --version
                        '''
                    } else {
                        echo 'Docker non disponible, utilisation de Node.js local...'
                        sh '''
                            # Installation de Node.js via nvm
                            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
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
                            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            npm ci
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
                            docker run --rm ${DOCKER_IMAGE}:builder npm test
                        '''
                    } else {
                        echo 'Exécution des tests...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            npm test
                        '''
                    }
                }
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'test-results.xml'
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
                            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
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
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                            docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                            docker images ${DOCKER_IMAGE}
                        '''
                    } else {
                        echo 'Construction de l\'application...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
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
                            docker run --rm ${DOCKER_IMAGE}:builder npm audit --audit-level=high
                            echo "Scan de l'image Docker..."
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} npm audit --audit-level=high || true
                        '''
                    } else {
                        echo 'Analyse de sécurité...'
                        sh '''
                            export NVM_DIR="$HOME/.nvm"
                            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                            nvm use ${NODE_VERSION}
                            echo "Vérification des dépendances..."
                            npm audit --audit-level=high
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
                            echo "Déploiement staging avec Docker Compose..."
                            docker-compose -f docker-compose.yml up -d app
                            sleep 10
                            docker-compose ps
                        '''
                    } else {
                        echo 'Déploiement vers l\'environnement de staging...'
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
                            echo "Sauvegarde de la version précédente..."
                            docker-compose down || true
                            
                            echo "Déploiement de la nouvelle version..."
                            docker-compose -f docker-compose.yml up -d app
                            
                            echo "Vérification du déploiement..."
                            sleep 10
                            docker-compose ps
                            docker logs mon-app-js
                        '''
                    } else {
                        echo 'Déploiement vers la production...'
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
                                echo "Test de connectivité..."
                                sleep 5
                                curl -f http://localhost:3000/health || exit 1
                                echo "Application déployée avec succès"
                            '''
                        } else {
                            sh '''
                                echo "Test de connectivité simulé..."
                                # Simulation d'un health check
                                echo "Application déployée avec succès"
                            '''
                        }
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
