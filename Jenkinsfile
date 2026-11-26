
pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        SONAR_PROJECT = 'rapido-devsecops'
        IMAGE_NAME = 'rapido-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Declarative Tool Install') {
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
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=rapido-devsecops \
                        -Dsonar.sources=.
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
                sh '''
                    dependency-check.sh \
                    --project Rapido \
                    --scan . \
                    --format HTML \
                    --out reports
                '''
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs .'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image ${IMAGE_NAME}:${IMAGE_TAG}'
            }
        }

        stage('Docker Push') {
            steps {
                echo 'Add your Docker registry login and push commands'
            }
        }

        stage('Deploy Application') {
            steps {
                echo 'Add your application deployment commands'
            }
        }

        stage('Health Check') {
            steps {
                echo 'Add your application health-check URL'
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'
        }
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed. Check console output.'
        }
    }
}

