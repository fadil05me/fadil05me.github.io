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


stage('Checking website using curl') {
    steps {
        script {
            sshagent(credentials: ['sshkey']) {
                sh """
                ssh -o StrictHostKeyChecking=no ${SERVER} << 'EOF'
                if curl -s -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" https://jen.fadil05me.my.id/ | grep -q "403"; then
                    echo "Website is up!"
                else
                    echo "Website is down or inaccessible!"
                    exit 1
                fi
                echo "Selesai Testing!"
                """
            }
        }
    }
}




    }

}
