output "connection_info" {
  description = "Information for connecting to the instance"
  value = {
    ip        = google_compute_instance.trueclaw.network_interface[0].access_config[0].nat_ip
    ssh_user  = "debian"  # Default user for Debian
    ssh_key   = "~/.ssh/gcp_key"  # Path to your SSH key
    command   = "ssh -i ~/.ssh/gcp_key debian@${google_compute_instance.trueclaw.network_interface[0].access_config[0].nat_ip}"
  }
}
