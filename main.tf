terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# -------------------
# Provider Configuration
# -------------------
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

# -------------------
# Get default VPC network
# -------------------
data "google_compute_network" "default" {
  name = "default"
}

# -------------------
# Firewall Rule - SSH Access
# -------------------
resource "google_compute_firewall" "allow_ssh" {
  name        = "${var.project_name}-allow-ssh"
  network     = data.google_compute_network.default.name
  description = "Allow SSH from specific IP"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_ip]

  target_tags = ["trueclaw"]
}

# -------------------
# Firewall Rule - Allow HTTP/HTTPS (if trueclaw serves web)
# -------------------
resource "google_compute_firewall" "allow_http_https" {
  name        = "${var.project_name}-allow-http-https"
  network     = data.google_compute_network.default.name
  description = "Allow HTTP and HTTPS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3000", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["trueclaw"]
}

# -------------------
# Firewall Rule - Allow all internal traffic within the tag
# -------------------
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.project_name}-allow-internal"
  network     = data.google_compute_network.default.name
  description = "Allow internal traffic"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_tags = ["trueclaw"]
  target_tags = ["trueclaw"]
}

# -------------------
# Service Account for the Instance
# -------------------
resource "google_service_account" "trueclaw_sa" {
  account_id   = "${var.project_name}-sa"
  display_name = "trueclaw Service Account"
  description  = "Service account for trueclaw compute instance"
}

# Add IAM roles (adjust as needed)
resource "google_project_iam_member" "sa_cloud_logging" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.trueclaw_sa.email}"
}

resource "google_project_iam_member" "sa_monitoring" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.trueclaw_sa.email}"
}

# -------------------
# Static IP for the Instance
# -------------------
resource "google_compute_address" "trueclaw_static_ip" {
  name   = "${var.project_name}-static-ip"
  region = var.region
}

# -------------------
# Compute Engine Instance
# -------------------
resource "google_compute_instance" "trueclaw" {
  name         = "${var.project_name}-instance"
  machine_type = var.instance_type
  zone         = var.zone
  allow_stopping_for_update = true

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  tags = ["trueclaw"]

  boot_disk {
    initialize_params {
      # Option A: The "Base" image (Drivers + CUDA only)
      image = "projects/deeplearning-platform-release/global/images/family/common-cu128-ubuntu-2204-nvidia-570"
      
      # Option B: PyTorch Pre-installed
      # image = "projects/deeplearning-platform-release/global/images/family/pytorch-2-1-cu121-debian-12"
      
      # Option C: TensorFlow Pre-installed
      # image = "projects/deeplearning-platform-release/global/images/family/tf-2-15-cu122-debian-12"
      
      size = 100 # Recommend at least 100GB for DL images
    }
  }

  # network_interface {
  #   network = data.google_compute_network.default.name
  #   access_config {
  #     // This adds a public IP (ephemeral)
  #   }
  # }
  network_interface {
    network = data.google_compute_network.default.name
    access_config {
      nat_ip = google_compute_address.trueclaw_static_ip.address
    }
  }

  service_account {
    email  = google_service_account.trueclaw_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  metadata = {
    startup-script = file("${path.module}/startup.sh")
    ssh-keys       = <<-EOT
      debian:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlBLFpZUEcjbWjjXK+pntMYabxNCE1fYDSzD8cTnaoz trueclaw@gcp
    EOT
    }

  labels = {
    environment = "production"
    app         = "trueclaw"
  }

  # Allow SSH via metadata (project-wide)
  # metadata_keys = {
  #   # You can add SSH keys here if needed
  # }

  # Schedule deletion protection (optional)
  # can_ip_forward = false
  # enable_display = false
}



# -------------------
# Outputs
# -------------------
output "instance_ip" {
  value = google_compute_instance.trueclaw.network_interface[0].access_config[0].nat_ip
}

output "instance_name" {
  value = google_compute_instance.trueclaw.name
}

output "instance_zone" {
  value = google_compute_instance.trueclaw.zone
}

output "ssh_command" {
  value = "ssh -i <your-private-key> ${var.project_name}@${google_compute_instance.trueclaw.network_interface[0].access_config[0].nat_ip}"
}
