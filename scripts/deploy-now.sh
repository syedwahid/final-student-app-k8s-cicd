#!/bin/bash

echo "🚀 DEPLOY STUDENT APP - ONE COMMAND"
echo "==================================="

# Create fresh directory
rm -rf student-app-deploy
mkdir student-app-deploy
cd student-app-deploy

# Get Cloud Shell project
PROJECT=$(gcloud config get-value project)
echo "Using project: $PROJECT"

# Generate SSH key
echo "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -f ./id_rsa -N "" -q

# Create complete Terraform configuration
cat > main.tf << 'MAIN'
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "vm" {
  name         = "student-app-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    docker run -d -p 80:80 --name nginx nginx
    docker run -d -p 3000:3000 --name node node:18-alpine node -e "require('http').createServer((req, res) => { res.end('Backend API Running') }).listen(3000)"
  SCRIPT

  tags = ["http-server", "https-server"]
}

resource "google_compute_firewall" "web" {
  name    = "allow-web"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3000", "3001", "31349"]
  }

  source_ranges = ["0.0.0.0/0"]
}

variable "project" {
  type = string
}

output "vm_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "frontend_url" {
  value = "http://\${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}"
}

output "backend_url" {
  value = "http://\${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}:3000"
}
MAIN

# Create terraform.tfvars
echo "project = \"$PROJECT\"" > terraform.tfvars

# Initialize and apply
echo "Deploying VM..."
terraform init
terraform apply -auto-approve

# Get results
VM_IP=$(terraform output -raw vm_ip)
echo ""
echo "🎉 DEPLOYMENT SUCCESSFUL!"
echo "========================"
echo ""
echo "🌐 Access URLs:"
echo "   Frontend (nginx): http://$VM_IP"
echo "   Backend API: http://$VM_IP:3000"
echo ""
echo "🖥️  SSH Access:"
echo "   ssh ubuntu@$VM_IP"
echo ""
echo "📋 To deploy full student app:"
echo "   1. ssh ubuntu@$VM_IP"
echo "   2. git clone https://github.com/syedwahid/final-student-app-k8s-cicd"
echo "   3. Follow README instructions"
