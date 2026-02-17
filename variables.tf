variable "project" {
  description = "GCP project ID"
  type        = string
  default     = "your-project-id"  # CHANGE THIS
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone within the region"
  type        = string
  default     = "us-central1-a"
}

variable "instance_type" {
  description = "GCP machine type (g2 family)"
  type        = string
  default     = "g2-standard-4"  # 4 vCPU / 1x GPU /16 GB setup
  # default     = "e2-standard-4"  # 4 vCPU / 16 GB setup
}

variable "project_name" {
  description = "Name for tagging resources"
  type        = string
  default     = "trueclaw"
}

variable "disk_size_gb" {
  description = "Root disk size in GB"
  type        = number
  default     = 30
}

variable "ssh_source_ip" {
  description = "Your IP for SSH access (CIDR)"
  type        = string
  default     = "0.0.0.0/0"  # CHANGE THIS to your IP like "203.0.113.5/32"
}

variable "enable_monitoring" {
  description = "Enable Cloud Monitoring agent"
  type        = bool
  default     = true
}

