
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 60, unit: 'MINUTES')
    }

    tools {
        nodejs 'NodeJS'
    }

    environment {
        DOCKERHUB_REPO = 'sujanraj2604-eng/rapido-devsecops'
        AWS_DEFAULT_REGION = 'ap-south-1'
        OWASP_CLI = '/opt/dependency-check/dependency-check/bin/dependency-check.sh'
    }

    stages {

        stage('1. GitHub Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('2. Install Dependencies') {
            steps {
                sh '''
                    node --version
                    npm --version
                    npm ci
                '''
            }
        }

        stage('3. Application Testing') {
            steps {
                sh 'npm test'
            }
        }

        stage('4. SonarQube Analysis') {
            steps {
                script {
                    env.SONAR_SCANNER_HOME = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            "$SONAR_SCANNER_HOME/bin/sonar-scanner" \
                              -Dsonar.projectKey=rapido-devsecops \
                              -Dsonar.projectName=Rapido-DevSecOps \
                              -Dsonar.sources=. \
                              -Dsonar.exclusions=**/node_modules/**,terraform/**,**/.git/** \
                              -Dsonar.token="$SONAR_AUTH_TOKEN"
                        '''
                    }
                }
            }
        }

        stage('5. OWASP Dependency Check') {
            steps {
                sh '''
                    mkdir -p dependency-check-report

                    "$OWASP_CLI" \
                      --scan package.json \
                      --scan package-lock.json \
                      --format HTML \
                      --out dependency-check-report \
                      --failOnCVSS 7
                '''
            }
        }

        stage('6. Docker Build') {
            steps {
                script {
                    env.DOCKER_IMAGE =
                        "${env.DOCKERHUB_REPO}:${env.BUILD_NUMBER}"

                    env.DOCKER_IMAGE_LATEST =
                        "${env.DOCKERHUB_REPO}:latest"

                    sh '''
                        docker build \
                          -t "$DOCKER_IMAGE" \
                          -t "$DOCKER_IMAGE_LATEST" .
                    '''
                }
            }
        }

        stage('7. Trivy Security Scan') {
            steps {
                sh '''
                    trivy image \
                      --no-progress \
                      --format json \
                      --output trivy-report.json \
                      "$DOCKER_IMAGE"

                    trivy image \
                      --no-progress \
                      --exit-code 1 \
                      --severity HIGH,CRITICAL \
                      "$DOCKER_IMAGE"
                '''
            }
        }

        stage('8. Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e
                        trap 'docker logout >/dev/null 2>&1 || true' EXIT

                        printf '%s' "$DOCKERHUB_PASSWORD" |
                          docker login \
                            --username "$DOCKERHUB_USER" \
                            --password-stdin

                        docker push "$DOCKER_IMAGE"
                        docker push "$DOCKER_IMAGE_LATEST"
                    '''
                }
            }
        }

        stage('9. Terraform Plan and Approval') {
            steps {
                script {
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws-credentials']
                    ]) {
                        dir('terraform/terraform') {

                            sh '''
                                terraform fmt -check
                                terraform init -input=false
                                terraform validate

                                terraform plan \
                                  -input=false \
                                  -out=tfplan \
                                  -var="docker_image=$DOCKER_IMAGE"
                            '''

                            timeout(time: 30, unit: 'MINUTES') {
                                input(
                                    message: 'Approve Rapido AWS deployment?',
                                    ok: 'Approve Deployment'
                                )
                            }

                            sh '''
                                terraform apply \
                                  -input=false \
                                  -auto-approve \
                                  tfplan
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts(
                artifacts: 'dependency-check-report/**,trivy-report.json',
                allowEmptyArchive: true
            )

            echo 'Rapido DevSecOps pipeline execution completed.'
        }

        success {
            echo 'Rapido application pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs and security reports.'
        }
    }
}

