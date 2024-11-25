111
pipeline {
    agent any
    
    environment {
        BUILD_SERVER = 'finaltask-fadil@52.187.151.49'
        DEPLOY_SERVER = 'finaltask-fadil@103.127.134.73'
        DIRECTORY = '/home/finaltask-fadil/build/staging/backend'
        BRANCH = 'staging'
        REPO_URL = 'git@github.com:fadil05me/be-dumbmerch.git'
        SSH_PORT = '1234'
        REGISTRY_URL = 'registry.fadil.studentdumbways.my.id'
        IMAGE_NAME = 'be-dumbmerch-staging'
    }
    
    stages {
        stage('Clean up stage') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        // Clean up directory and Docker images
                        sh """
                        ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no ${BUILD_SERVER} << 'EOF'
                        rm -rf ${DIRECTORY}
                        mkdir -p ${DIRECTORY}
                        echo "Directory cleaned and recreated!"

                        docker rmi -f \$(docker images ${REGISTRY_URL}/${IMAGE_NAME} -q)
                        echo "All images deleted!"

                        exit
                        EOF
                        """
                    }
                }
            }
        }
        
        

        stage('Checking website using wget spider') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        sh """
                            ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no ${BUILD_SERVER} << 'EOF'
                            if wget --spider -q --server-response http://127.0.0.1:5000/ 2>&1 | grep '404 Not Found'; then
                                echo "Website is up!"
                            else
                                echo "Website is down!"
                                docker rm -f testcode-be
                                exit 1
                            fi
                            docker rm -f testcode-be
                            echo "Selesai Testing!"
                            exit
                            EOF
                            """
                    }
                }
            }
        }

       


    }

}
