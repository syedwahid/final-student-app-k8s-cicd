#!/bin/bash
echo "🚀 Setting up KIND (Kubernetes in Docker)"
echo "========================================="

# Install KIND if not installed
if ! command -v kind &> /dev/null; then
    echo "📦 Installing KIND..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "✅ KIND installed"
else
    echo "✅ KIND already installed"
fi

# Install kubectl if not installed
if ! command -v kubectl &> /dev/null; then
    echo "📦 Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    echo "✅ kubectl installed"
else
    echo "✅ kubectl already installed"
fi

# Create KIND cluster configuration
echo "📝 Creating KIND cluster configuration..."
cat > kind/kind-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
  - containerPort: 31349
    hostPort: 31349
    protocol: TCP
  - containerPort: 32000
    hostPort: 32000
    protocol: TCP
- role: worker
- role: worker
EOF

# Create or start KIND cluster
if kind get clusters | grep -q "student-app"; then
    echo "🔄 KIND cluster 'student-app' already exists"
    echo "   To delete and recreate: kind delete cluster --name student-app"
else
    echo "🚀 Creating KIND cluster 'student-app'..."
    kind create cluster --name student-app --config kind/kind-config.yaml
fi

# Set kubectl context
kubectl config use-context kind-student-app

# Check cluster status
echo "📊 Cluster status:"
kubectl cluster-info
kubectl get nodes

echo ""
echo "✅ KIND setup completed!"
echo "🌐 Cluster: student-app"
echo "👤 Context: kind-student-app"