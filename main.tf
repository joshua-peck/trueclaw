terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
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

  target_tags = ["openclaw"]
}

# -------------------
# Firewall Rule - Allow HTTP/HTTPS (if OpenClaw serves web)
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

  target_tags = ["openclaw"]
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

  source_tags = ["openclaw"]
  target_tags = ["openclaw"]
}

# -------------------
# Service Account for the Instance
# -------------------
resource "google_service_account" "openclaw_sa" {
  account_id   = "${var.project_name}-sa"
  display_name = "OpenClaw Service Account"
  description  = "Service account for OpenClaw compute instance"
}

# Add IAM roles (adjust as needed)
resource "google_project_iam_member" "sa_cloud_logging" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.openclaw_sa.email}"
}

resource "google_project_iam_member" "sa_monitoring" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.openclaw_sa.email}"
}

# -------------------
# Compute Engine Instance
# -------------------
resource "google_compute_instance" "openclaw" {
  name         = "${var.project_name}-instance"
  machine_type = var.instance_type
  zone         = var.zone

  tags = ["openclaw"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"  # Or "centos-stream-9", "ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-ssd"  # SSD for better I/O
    }
  }

  network_interface {
    network = data.google_compute_network.default.name
    access_config {
      // This adds a public IP (ephemeral)
    }
  }

  service_account {
    email  = google_service_account.openclaw_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  metadata = {
    startup-script = file("${path.module}/startup.sh")
  }

  labels = {
    environment = "production"
    app         = "openclaw"
  }

  # Allow SSH via metadata (project-wide)
  metadata_keys = {
    # You can add SSH keys here if needed
  }

  # Schedule deletion protection (optional)
  # can_ip_forward = false
  # enable_display = false
}



# -------------------
# Outputs
# -------------------
output "instance_ip" {
  value = google_compute_instance.openclaw.network_interface[0].access_config[0].nat_ip
}

output "instance_name" {
  value = google_compute_instance.openclaw.name
}

output "instance_zone" {
  value = google_compute_instance.openclaw.zone
}

output "ssh_command" {
  value = "ssh -i <your-private-key> ${var.project_name}@${google_compute_instance.openclaw.network_interface[0].access_config[0].nat_ip}"
}
