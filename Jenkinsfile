pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'fadil05me/fadil05me.github.io:latest'  // YDocker image name
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'  // Jenkins credential ID for Docker Hub
        SERVER_CREDENTIALS = 'server'
        SSH_KEY_CREDENTIALS = 'github'  // The SSH key credential ID
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                git credentialsId: SSH_KEY_CREDENTIALS, branch: 'master', url: 'git@github.com:fadil05me/fadil05me.github.io.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Push to Registry') {
            steps {
                echo 'Pushing Docker image to private registry...'
                withCredentials([usernamePassword(credentialsId: DOCKER_REGISTRY_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                    sh "docker push ${DOCKER_IMAGE}"
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh 'kubectl apply -f ../../deploy/deploy.yaml'
                sh 'kubectl rollout status deployment/fadil05me-web'
            }
        }

    }
}
