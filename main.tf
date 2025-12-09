terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create VM instance
resource "google_compute_instance" "student_app_vm" {
  name         = var.vm_name
  machine_type = var.vm_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  # Startup script - NO SSH KEY REFERENCE
  metadata_startup_script = <<-EOT
    #!/bin/bash
    
    # Update and install Docker
    apt-get update
    apt-get install -y docker.io
    
    # Start Docker
    systemctl enable docker
    systemctl start docker
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Install KIND
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    
    # Create app directory
    mkdir -p /opt/student-app
    
    # Run test services
    docker run -d -p 3000:3000 --name test-backend node:18-alpine node -e "require('http').createServer((req, res) => { res.end('Backend API Running') }).listen(3000)"
    docker run -d -p 80:80 --name test-frontend nginx
    
    echo "VM setup completed!" >> /var/log/startup.log
  EOT

  tags = ["http-server", "https-server", "student-app"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_web" {
  name    = "allow-student-app-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3000", "3001", "31349"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["student-app"]
}

# Static IP
resource "google_compute_address" "static_ip" {
  name   = "${var.vm_name}-ip"
  region = var.gcp_region
}

# Outputs
output "vm_public_ip" {
  value       = google_compute_address.static_ip.address
  description = "Public IP address of the VM"
}

output "frontend_url" {
  value       = "http://${google_compute_address.static_ip.address}:31349"
  description = "Frontend URL"
}

output "backend_url" {
  value       = "http://${google_compute_address.static_ip.address}:30001/api/health"
  description = "Backend API URL"
}

output "ssh_note" {
  value       = "Add SSH key via GCP Console: Compute Engine > Metadata > SSH Keys"
  description = "SSH access note"
}
