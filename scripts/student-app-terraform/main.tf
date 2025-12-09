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
    apt-get install -y docker.io curl
    systemctl enable docker
    systemctl start docker
    
    # Install KIND
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Run simple web server for testing
    docker run -d -p 80:80 --name nginx nginx
    docker run -d -p 3000:3000 --name node node:18-alpine node -e "require('http').createServer((req, res) => { res.end('Backend API') }).listen(3000)"
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

output "ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}
