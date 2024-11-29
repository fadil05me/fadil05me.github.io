pipeline {
    agent any

    environment {
        DOCKER_IMAGE_BASE = 'fadil05me/fadil05me.github.io'
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'
        SERVER_CREDENTIALS = 'server'
        SSH_KEY_CREDENTIALS = 'github'
        IMAGE_TAG = "${env.BUILD_NUMBER}"  // Generate dynamic tag
        DOCKER_IMAGE = "${DOCKER_IMAGE_BASE}:${IMAGE_TAG}"  // Final image with tag
        DEPLOYMENT_NAME = 'fadil05me-web'
    }

    stages {

        stage('Rollback') {
            when {
                expression { params.ROLLBACK == 'true' }  // Only trigger if ROLLBACK is true
            }
            steps {
                echo 'Rolling back to the previous version of the deployment...'
                withKubeConfig([credentialsId: 'kubecfg']) {
                    // Rollback to the previous deployment revision
                    sh "kubectl rollout undo deployment/${DEPLOYMENT_NAME}"
                }
                script {
                    // Prevent further stages from running
                    currentBuild.result = 'SUCCESS'
                    // Abort pipeline to stop further execution
                    error('Rollback completed, stopping pipeline execution.')
                }
            }
        }



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
                withKubeConfig([credentialsId: 'kubecfg']) {
                    sh "sed 's#__DOCKER_IMAGE__#${DOCKER_IMAGE}#' deploy.yaml > deploy_processed.yaml"  // Replace placeholder
                    sh "kubectl apply -f deploy_processed.yaml"  // Apply the modified file
                    sh 'kubectl rollout restart deployment fadil05me-web'  // Restart deployment
                }
            }
        }

    }
}
