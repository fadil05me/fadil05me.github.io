111
pipeline {
    agent any
    
    environment {
        SERVER = 'azureuser@20.205.24.80'
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
        
        


       


    }

}
