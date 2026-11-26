pipeline {
    agent any
 
    options {
        skipDefaultCheckout(true)
        timestamps()
    }
 
    tools {
        nodejs 'node23'
    }
 
    environment {
        SCANNER_HOME   = tool 'sonar-scanner'
        DC_HOME        = tool 'dependency-check'
        SONAR_PROJECT  = 'rapido-devsecops'
        DOCKER_IMAGE   = '<DOCKERHUB_USERNAME>/rapido'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        CONTAINER_NAME = 'rapido-container'
        HOST_PORT      = '<HOST_PORT>'        // e.g. 80
        APP_PORT       = '<CONTAINER_PORT>'   // 80 for Nginx, 3000 for npm start
    }
 
    stages {
 
        stage('Tool Versions') {
            steps {
                sh '''
                    java -version
                    docker --version
                    node --version
                    npm --version
                    trivy --version
                '''
            }
        }
 
        stage('Clean Workspace') {
            steps { cleanWs() }
        }
 
        stage('Checkout Code') {
            steps { checkout scm }
        }
 
        stage('Install Dependencies') {
            steps { sh 'npm install' }
        }
 
        stage('Test') {
            steps {
                // CI=true makes react-scripts/jest run once instead of watch mode
                sh 'CI=true npm test -- --passWithNoTests'
            }
        }
 
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        "$SCANNER_HOME/bin/sonar-scanner" \
                          -Dsonar.projectName=$SONAR_PROJECT \
                          -Dsonar.projectKey=$SONAR_PROJECT \
                          -Dsonar.sources=. \
                          -Dsonar.exclusions=node_modules/**,build/**,dist/**,reports/**
                    '''
                }
            }
        }
 
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
 
        stage('OWASP Dependency Check') {
            steps {
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_KEY')]) {
                    sh '''
                        "$DC_HOME/bin/dependency-check.sh" \
                          --project Rapido \
                          --scan . \
                          --exclude "**/node_modules/**" \
                          --format HTML \
                          --out reports \
                          --nvdApiKey "$NVD_KEY" || true
                    '''
                }
            }
        }
 
        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs --format table -o trivyfs-report.txt . || true'
            }
        }
 
        stage('Docker Build') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} -t ${DOCKER_IMAGE}:latest .'
            }
        }
 
        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --format table -o trivy-image-report.txt ${DOCKER_IMAGE}:latest || true'
            }
        }
 
        stage('Docker Push') {
            steps {
                withDockerRegistry(credentialsId: 'docker-creds', url: 'https://index.docker.io/v1/') {
                    sh '''
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }
 
        stage('Deploy Application') {
            steps {
                sh '''
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      --restart unless-stopped \
                      -p ${HOST_PORT}:${APP_PORT} \
                      ${DOCKER_IMAGE}:latest
                '''
            }
        }
 
        stage('Health Check') {
            steps {
                sh '''
                    for i in $(seq 1 12); do
                        if curl -fs http://localhost:${HOST_PORT}/ > /dev/null; then
                            echo "Rapido app is running on port ${HOST_PORT}"
                            exit 0
                        fi
                        sleep 5
                    done
                    echo "App did not respond"
                    docker logs ${CONTAINER_NAME} || true
                    exit 1
                '''
            }
        }
    }
 
    post {
        always {
            archiveArtifacts artifacts: 'reports/**,trivyfs-report.txt,trivy-image-report.txt',
                             allowEmptyArchive: true
            echo 'Pipeline execution completed'
        }
        success { echo 'Pipeline completed successfully' }
        failure { echo 'Pipeline failed. Check console output.' }
    }
}
