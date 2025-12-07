pipeline {
    agent any
    
    stages {
        stage('Hello') {
            steps {
                echo 'Hello from Jenkins CI/CD!'
                sh 'echo "Build Number: $BUILD_NUMBER"'
                sh 'date'
            }
        }
        
        stage('Check Files') {
            steps {
                sh '''
                    echo "Project structure:"
                    pwd
                    ls -la
                '''
            }
        }
    }
    
    post {
        always {
            echo "Pipeline completed!"
        }
    }
}
