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

    stagess {

        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                git credentialsId: SSH_KEY_CREDENTIALS, branch: 'master', url: 'git@github.com:fadil05me/fadil05me.github.io.git'
            }
        }

        stage('Rollback') {
            when {
                expression { params.ROLLBACK == 'true' }  // Only trigger if ROLLBACK is true
            }
            steps {
                script {
                    echo 'Rolling back to the previous version of the deployment...'

                    def previousBuild = currentBuild.previousBuild  // Start with the immediate previous build
                    while (previousBuild) {  // Loop through previous builds
                        def prevStatus = previousBuild.result ?: 'UNKNOWN'
                        def prevBuildNumber = previousBuild.number
                        
                        if (prevStatus == 'SUCCESS') {
                            echo "The latest successful build is #${prevBuildNumber}."
                            withKubeConfig([credentialsId: 'kubecfg']) {
                                sh "sed 's#__DOCKER_IMAGE__#${DOCKER_IMAGE_BASE}:${prevBuildNumber}#' deploy.yaml > deploy_processed.yaml"  // Replace placeholder
                                sh "kubectl apply -f deploy_processed.yaml"  // Apply the modified file
                                sh 'kubectl rollout restart deployment fadil05me-web'  // Restart deployment
                            }
                            break  // Exit the loop once a successful build is found
                        } else {
                            echo "Build #${prevBuildNumber} failed. Checking the build before it..."
                            previousBuild = previousBuild.previousBuild  // Move to the earlier build
                        }
                    }
                    
                    // If no successful build was found
                    if (!previousBuild) {
                        echo "No successful builds found in history."
                    }
                

                    // Prevent further stages from running
                    currentBuild.result = 'SUCCESS'
                    // Set a flag to skip remaining stages
                    env.SKIP_REMAINING_STAGES = 'true'
                }
            }
        }

        stage('Build') {
            when {
                expression { return env.SKIP_REMAINING_STAGES != 'true' }  // Check the flag
            }
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Push to Registry') {
            when {
                expression { return env.SKIP_REMAINING_STAGES != 'true' }  // Check the flag
            }
            steps {
                echo 'Pushing Docker image to private registry...'
                withCredentials([usernamePassword(credentialsId: DOCKER_REGISTRY_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                    sh "docker push ${DOCKER_IMAGE}"
                }
            }
        }

        stage('Deploy') {
            when {
                expression { return env.SKIP_REMAINING_STAGES != 'true' }  // Check the flag
            }
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