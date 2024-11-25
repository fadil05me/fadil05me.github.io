111
pipeline {
    agent any
    
    environment {
        SERVER = 'azureuser@20.205.24.80'
        BRANCH = 'master'
        REPO_URL = 'git@github.com:fadil05me/fadil05me.github.io.git'
        REGISTRY_URL = 'registry.fadil.studentdumbways.my.id'
        IMAGE_NAME = 'be-dumbmerch-staging'
    }
    
    stages {
        stage('Connect SSH...') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        // Clean up directory and Docker images
                        sh """
                        ssh -o StrictHostKeyChecking=no ${SERVER} << 'EOF'

                        echo "Connect SSH Successfully!"

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
                            ssh -o StrictHostKeyChecking=no ${SERVER} << 'EOF'
                            if wget --spider -q --server-response  https://jen.fadil05me.my.id/ 2>&1 then
                                echo "Website is up!"
                            else
                                echo "Website is down!"
                                exit 1
                            fi
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
