pipeline {
    agent any
    
    environment {
        APP_NAME = "student-app"
        KUBE_NAMESPACE = "student-app"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Source code checked out'
            }
        }
        
        stage('Setup KIND Cluster') {
            steps {
                script {
                    echo '☸️ Setting up KIND cluster using existing config...'
                    sh '''
                        echo "1. Checking if KIND cluster exists..."
                        if ! kind get clusters | grep -q student-app; then
                            echo "Creating KIND cluster using kind/kind-config.yaml..."
                            kind create cluster --name student-app --config kind/kind-config.yaml
                        else
                            echo "✅ KIND cluster already exists"
                        fi
                        
                        echo "2. Setting up kubeconfig..."
                        mkdir -p ~/.kube
                        kind get kubeconfig --name student-app > ~/.kube/config
                        
                        echo "✅ Cluster ready"
                        kubectl get nodes
                        # ADD THESE 3 LINES - Export kubeconfig for local use
                        echo "3. Exporting kubeconfig for local kubectl access..."
                        echo "To use kubectl locally after pipeline, run:"
                        echo "kind export kubeconfig --name student-app"
                        echo "Or: kind get kubeconfig --name student-app > ~/.kube/config"
                    '''
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo '🐳 Building Docker images...'
                    sh '''
                        echo "1. Building backend image..."
                        cd app/backend
                        docker build -t student-backend:latest .
                        
                        echo "2. Building frontend image..."
                        cd ../frontend
                        docker build -t student-frontend:latest .
                        
                        echo "✅ Images built:"
                        docker images | grep student-
                    '''
                }
            }
        }
        
        stage('Load Images to KIND') {
            steps {
                script {
                    echo '📦 Loading images to KIND cluster...'
                    sh '''
                        echo "Loading backend image..."
                        kind load docker-image student-backend:latest --name student-app
                        
                        echo "Loading frontend image..."
                        kind load docker-image student-frontend:latest --name student-app
                        
                        echo "✅ Images loaded to KIND"
                    '''
                }
            }
        }
        
        stage('Prepare Kubernetes Manifests') {
            steps {
                script {
                    echo '🔄 Preparing manifests for KIND...'
                    sh '''
                        echo "1. Setting imagePullPolicy to Never (required for KIND)..."
                        cp k8s/backend/deployment.yaml k8s/backend/deployment.yaml.backup
                        cp k8s/frontend/deployment.yaml k8s/frontend/deployment.yaml.backup
                        
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/backend/deployment.yaml
                        sed -i 's/imagePullPolicy:.*/imagePullPolicy: Never/g' k8s/frontend/deployment.yaml
                        
                        echo "✅ Manifests prepared"
                    '''
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    echo '🚀 Deploying Student Management App...'
                    sh '''
                        echo "1. Creating namespace..."
                        kubectl create namespace student-app --dry-run=client -o yaml | kubectl apply -f -
                        
                        echo "2. Applying configurations..."
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        
                        echo "3. Deploying Backend..."
                        kubectl apply -f k8s/backend/
                        
                        echo "4. Deploying Frontend..."
                        kubectl apply -f k8s/frontend/
                        
                        echo "⏳ Waiting for pods (40 seconds)..."
                        sleep 40
                        
                        echo "📊 Deployment status:"
                        kubectl get all -n student-app
                    '''
                }
            }
        }
        
        stage('Test Application') {
            steps {
                script {
                    echo '🧪 Testing application...'
                    sh '''
                        echo "Testing backend API..."
                        if curl -s http://localhost:30001/api/health > /dev/null; then
                            echo "✅ Backend is working"
                            curl -s http://localhost:30001/api/health | grep status || echo "No status in response"
                        else
                            echo "❌ Backend not responding"
                        fi
                        
                        echo ""
                        echo "Testing frontend..."
                        if curl -s http://localhost:31349 > /dev/null; then
                            echo "✅ Frontend is working"
                            curl -s http://localhost:31349 | head -3
                        else
                            echo "❌ Frontend not responding"
                        fi
                        
                        echo ""
                        echo "🌐 Application URLs:"
                        echo "Frontend: http://localhost:31349"
                        echo "Backend: http://localhost:30001/api/health"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 CI/CD Pipeline completed successfully!'
            script {
                currentBuild.description = "✅ Success - App deployed"

                            // Add this message
                echo '📋 To use kubectl locally after pipeline runs:'
                echo '   1. Run: kind export kubeconfig --name student-app'
                echo '   2. Then: kubectl get nodes'
                echo '   3. Or: kubectl get pods -n student-app'
            }
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                currentBuild.description = "❌ Failed - Check logs"
            }
        }
        always {
            echo "Build #${BUILD_NUMBER} completed"
        }
    }
}