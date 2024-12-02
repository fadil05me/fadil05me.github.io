pipeline {
    agent any

    environment {
        DOCKER_IMAGE_BASE = 'fadil05me/fadil05me.github.io'
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'
        SSH_KEY_CREDENTIALS = 'github'
        IMAGE_TAG = "${env.BUILD_NUMBER}"  // Generate dynamic tag
        DOCKER_IMAGE = "${DOCKER_IMAGE_BASE}:${IMAGE_TAG}"  // Final image with tag
        DEPLOYMENT_NAME = 'fadil05me-web'
    }

    stages {

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

                    echo 'Fetching the latest tag from Docker Hub...'

                    // Authenticate with Docker Hub
                    withCredentials([usernamePassword(credentialsId: DOCKER_REGISTRY_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        // Get the latest tag from Docker Hub
                        def latestTag = sh(script: """
                            curl -u ${DOCKER_USER}:${DOCKER_PASS} -s https://registry.hub.docker.com/v2/repositories/${DOCKER_IMAGE_BASE}/tags/ | \
                            jq -r '.results[0].name'
                        """, returnStdout: true).trim()

                        echo "The latest tag in Docker Hub is: ${latestTag}"

                        // Attempt to find the previous tag by decrementing the version number
                        def tagFound = false
                        def tagToCheck = latestTag.toInteger()

                        // Loop to check if the tag exists
                        while (!tagFound && tagToCheck > 0) {
                            tagToCheck--
                            echo "Checking for tag: ${tagToCheck}"

                            def tagExists = sh(script: """
                                curl -u ${DOCKER_USER}:${DOCKER_PASS} -s https://registry.hub.docker.com/v2/repositories/${DOCKER_IMAGE_BASE}/tags/${tagToCheck} | \
                                jq -e '.name' > /dev/null 2>&1
                            """, returnStatus: true)

                            if (tagExists == 0) {
                                echo "Found tag ${tagToCheck}, using this for rollback."
                                tagFound = true
                                env.TAG_TO_USE = tagToCheck.toString()
                            } else {
                                echo "Tag ${tagToCheck} not found, trying the previous one."
                            }
                        }

                        // If no valid tag found, print an error message
                        if (!tagFound) {
                            error "No valid tags found for rollback."
                        }
                    }

                    echo "Rolling back to image with tag ${env.TAG_TO_USE}..."

                    withKubeConfig([credentialsId: 'kubecfg']) {
                        // Set the image tag to the one found during the search
                        sh """
                            kubectl set image deployment/${DEPLOYMENT_NAME} ${DEPLOYMENT_NAME}=${DOCKER_IMAGE_BASE}:${env.TAG_TO_USE}
                            kubectl rollout restart deployment ${DEPLOYMENT_NAME}
                        """
                    }

                    echo "Rollback to tag ${env.TAG_TO_USE} successful."
                

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