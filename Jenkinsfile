pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME    = tool 'sonar-scanner'
        TMDB_V3_KEY     = '2ddbd7777985bd3f59a07defffcb3e59'
        DOCKER_USER     = 'kaif03'  // Replace with your DockerHub username
        DOCKER_IMAGE    = "${DOCKER_USER}/netflix:latest"
        EMAIL_TO        = 'mksocials21@gmail.com'     // Replace with your email
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                // Automatically pulls the repo and branch configured in the Jenkins job
                checkout scm
            }
        }

        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Netflix \
                        -Dsonar.projectKey=Netflix
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('OWASP FS Scan') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker') {
                        sh "docker build --build-arg TMDB_V3_API_KEY=${TMDB_V3_KEY} -t netflix ."
                        sh "docker tag netflix ${DOCKER_IMAGE}"
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image ${DOCKER_IMAGE} > trivyimage.txt"
            }
        }

        stage('Deploy to Container') {
            steps {
                // Stops and removes existing container before launching the new version
                sh """
                    docker rm -f netflix || true
                    docker run -d --name netflix -p 8081:80 ${DOCKER_IMAGE}
                """
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    dir('Kubernetes') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                            sh 'kubectl apply -f deployment.yml'
                            sh 'kubectl apply -f service.yml'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            emailext attachLog: true,
                subject: "Build Status: '${currentBuild.result}' - Netflix CI/CD",
                body: """
                    <h3>Jenkins Build Summary</h3>
                    <p><b>Project:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Status:</b> ${currentBuild.result}</p>
                    <p><b>URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                """,
                to: "${EMAIL_TO}",
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}