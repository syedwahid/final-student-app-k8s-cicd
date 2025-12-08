#!/bin/bash
echo "🔧 Setting up kubeconfig for Jenkins"
echo "==================================="

# 1. Stop Jenkins
echo "1. Stopping Jenkins..."
sudo systemctl stop jenkins

# 2. Create kubeconfig directory
echo "2. Creating kubeconfig directory..."
sudo mkdir -p /var/lib/jenkins/.kube
sudo chown jenkins:jenkins /var/lib/jenkins/.kube

# 3. Get KIND kubeconfig
echo "3. Getting KIND kubeconfig..."
if kind get clusters | grep -q student-app; then
    # Get kubeconfig and fix for Jenkins
    kind get kubeconfig --name student-app | \
        sed 's/server: .*/server: https:\/\/student-app-control-plane:6443/' | \
        sudo tee /var/lib/jenkins/.kube/config
    
    sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
    sudo chmod 600 /var/lib/jenkins/.kube/config
    
    echo "✅ Kubeconfig created"
else
    echo "❌ KIND cluster 'student-app' not found"
    echo "Creating cluster..."
    kind create cluster --name student-app --config kind/kind-config-fixed.yaml
    kind get kubeconfig --name student-app | sudo tee /var/lib/jenkins/.kube/config
fi

# 4. Test
echo "4. Testing..."
sudo -u jenkins kubectl config get-contexts
sudo -u jenkins kubectl get nodes

# 5. Start Jenkins
echo "5. Starting Jenkins..."
sudo systemctl start jenkins

echo ""
echo "✅ Setup complete!"
echo "Run Jenkins pipeline now."