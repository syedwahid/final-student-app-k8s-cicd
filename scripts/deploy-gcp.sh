#!/bin/bash

# Simple GCP deployment script
set -e

echo "🚀 Starting GCP deployment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Default values
GCP_PROJECT=${GCP_PROJECT_ID:-$1}
VM_NAME="student-app-vm"

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check for required files
    if [ ! -f "terraform/gcp/main.tf" ]; then
        echo -e "${RED}Error: Terraform files not found${NC}"
        exit 1
    fi
    
    # Check for environment variables
    if [ -z "$GCP_PROJECT" ]; then
        echo -e "${RED}Error: GCP_PROJECT_ID not set${NC}"
        echo "Usage: $0 <gcp-project-id>"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Prerequisites check passed${NC}"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    echo "Deploying infrastructure with Terraform..."
    
    cd terraform/gcp
    
    # Initialize Terraform
    terraform init
    
    # Plan and apply
    terraform plan -var="gcp_project=$GCP_PROJECT"
    
    read -p "Apply these changes? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve -var="gcp_project=$GCP_PROJECT"
    fi
    
    # Get VM IP
    VM_IP=$(terraform output -raw vm_public_ip)
    echo "VM Public IP: $VM_IP"
    
    cd ../..
    
    echo -e "${GREEN}✓ Infrastructure deployed${NC}"
}

# Function to build Docker images
build_images() {
    echo "Building Docker images..."
    
    # Build backend
    docker build -t student-backend:latest ./app/backend
    
    # Build frontend
    docker build -t student-frontend:latest ./app/frontend
    
    echo -e "${GREEN}✓ Docker images built${NC}"
}

# Function to deploy application
deploy_application() {
    echo "Deploying application to VM..."
    
    # This function would typically SSH to the VM and deploy
    # For now, we'll just show what would happen
    echo "Application would be deployed to the VM at: $VM_IP"
    echo "Frontend: http://$VM_IP:31349"
    echo "Backend: http://$VM_IP:30001/api/health"
    
    echo -e "${GREEN}✓ Application deployment instructions generated${NC}"
}

# Main function
main() {
    check_prerequisites
    deploy_infrastructure
    build_images
    deploy_application
    
    echo ""
    echo "🎉 Deployment process completed!"
    echo ""
    echo "Next steps:"
    echo "1. SSH to the VM: ssh ubuntu@$VM_IP"
    echo "2. Copy your application files to /opt/student-app"
    echo "3. Run the deployment scripts"
    echo ""
    echo "Or push your code to GitHub to trigger the CI/CD pipeline!"
}

# Run main function
main "$@"
