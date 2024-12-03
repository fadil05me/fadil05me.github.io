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

                    // Authenticate with Docker Hub and fetch tags
                    withCredentials([string(credentialsId: 'tokenHub', variable: 'DOCKER_TOKEN')]) {
                        def apiResponse = sh(script: """
                            export DOCKER_TOKEN=${DOCKER_TOKEN}
                            curl -s -H "Authorization: Bearer \$DOCKER_TOKEN" \\
                            https://hub.docker.com/v2/repositories/${DOCKER_IMAGE_BASE}/tags/
                        """, returnStdout: true).trim()

                        // Parse the tags from the response
                        def tags = readJSON(text: apiResponse).results*.name

                        // Get the previous tag
                        def rollbackTag = null
                        for (int i = 1; i < tags.size(); i++) {
                            def tag = tags[i]
                            if (tag.isInteger()) {  // Check if the tag is a valid number
                                rollbackTag = tag.toInteger()
                                break
                            }
                        }

                        if (rollbackTag == null) {
                            error "No valid tags found in the Docker Hub repository."
                        }

                        echo "The rollback tag is: ${rollbackTag}"

                        // Deploy using the rollback tag
                        withKubeConfig([credentialsId: 'kubecfg']) {
                            sh "sed 's#__DOCKER_IMAGE__#${DOCKER_IMAGE_BASE}:${rollbackTag}#' deploy.yaml > deploy_processed.yaml"  // Replace placeholder
                            sh "kubectl apply -f deploy_processed.yaml"  // Apply the modified file
                            sh 'kubectl rollout restart deployment fadil05me-web'  // Restart deployment
                        }

                        echo "Rollback to tag ${rollbackTag} successful."
                    }
                    
                    // Skip remaining stages
                    currentBuild.result = 'SUCCESS'
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
                    sh "docker push ${DOCKER_IMAGE}" // Push the tag version
                    sh "docker push ${DOCKER_IMAGE_BASE}:latest" // Push the latest version
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
