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
      // Ephemeral public IP
    }
  }

  # Metadata for SSH
  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_pub_key_path)}"
  }

  # Startup script to install required tools
  metadata_startup_script = <<-EOF
    #!/bin/bash
    
    # Update and install basic tools
    apt-get update
    apt-get install -y \
      docker.io \
      docker-compose \
      git \
      curl \
      wget \
      unzip \
      gnupg \
      lsb-release
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Install KIND
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    
    # Add ubuntu user to docker group
    usermod -aG docker ubuntu
    
    # Configure Docker to start on boot
    systemctl enable docker
    systemctl start docker
    
    # Create application directory
    mkdir -p /opt/student-app
    chown -R ubuntu:ubuntu /opt/student-app
    
    echo "VM setup completed at $(date)" >> /var/log/startup.log
  EOF

  tags = ["http-server", "https-server", "student-app"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Firewall rules for application ports
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

# Static IP for the VM
resource "google_compute_address" "static_ip" {
  name   = "${var.vm_name}-ip"
  region = var.gcp_region
}

output "vm_public_ip" {
  value = google_compute_address.static_ip.address
  description = "Public IP address of the VM"
}

output "vm_name" {
  value = google_compute_instance.student_app_vm.name
  description = "Name of the VM instance"
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_private_key_path} ubuntu@${google_compute_address.static_ip.address}"
  description = "SSH command to connect to the VM"
}
