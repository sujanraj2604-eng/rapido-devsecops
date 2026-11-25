
pipeline {
    agent any

    environment {
        IMAGE_NAME = "rapido-demo:latest"
        SONAR_URL = "http://127.0.0.1:9000"
        SONAR_PROJECT = "rapido-devsecops"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sujanraj2604-eng/rapido-devsecops.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'sonar-token',
                        variable: 'SONAR_TOKEN'
                    )
                ]) {
                    sh '''
                    docker run --rm --network host \
                    -e SONAR_HOST_URL=$SONAR_URL \
                    -e SONAR_TOKEN=$SONAR_TOKEN \
                    -v "$WORKSPACE:/usr/src" \
                    sonarsource/sonar-scanner-cli \
                    -Dsonar.projectKey=$SONAR_PROJECT \
                    -Dsonar.sources=. \
                    -Dsonar.exclusions=terraform/** \
                    '''
                }
            }
        }

        stage('OWASP Dependency Scan') {
            steps {
                sh '''
                   mkdir -p reports

                   docker run --rm \
                     -v "$WORKSPACE:/src" \
                     -v "$WORKSPACE/reports:/report" \
                     owasp/dependency-check:latest \
                     --scan /src \
                     --format HTML \
                     --out /report \
                     --project Rapido-DevSecOps \
                     --noupdate
              '''
             }
       }

        stage('Docker Build') {
            steps {
                sh '''
                docker build -t $IMAGE_NAME .
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                trivy image --severity HIGH,CRITICAL \
                --exit-code 0 $IMAGE_NAME
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Deploy') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
      }

    post {
        success {
            echo 'Rapido application deployed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the Jenkins console.'
        }

        always {
            echo 'DevSecOps Pipeline Execution Completed.'
        }
    }
}


