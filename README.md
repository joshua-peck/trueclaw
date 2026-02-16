# CLAW GCP Infrastructure

A complete Terraform configuration for deploying OpenClaw on Google Cloud Platform. Optimized for Node.js workloads with the e3 machine family.

## Prerequisites

### Tools You Need on macOS

```bash
# Install Homebrew (if you haven't already)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install \
  terraform \
  google-cloud-sdk \
  gh \
  git
```

### Verify Installations

```bash
terraform --version
gcloud --version
git --version
gh --version
```

---

## Step 1: Google Cloud Platform Setup

### 1.1 Create a GCP Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click the project dropdown (top left) → **New Project**
3. Name it `openclaw` (or your preference)
4. Note your **Project ID** (it'll be something like `openclaw-12345`)

### 1.2 Enable Compute Engine API

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable Compute Engine
gcloud services enable compute.googleapis.com
```

### 1.3 Authenticate with GCP

```bash
# Open browser for authentication
gcloud auth login

# Or use a service account (recommended for CI/CD)
gcloud auth activate-service-account --key-file=/path/to/key.json
```

### 1.4 Set Default Region/Zone

```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

---

## Step 2: SSH Key Setup

### 2.1 Generate an SSH Key

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key (choose a strong passphrase)
ssh-keygen -t ed25519 -C "openclaw@gcp" -f ~/.ssh/gcp_openclaw

# Secure the key
chmod 600 ~/.ssh/gcp_openclaw
```

### 2.2 Add SSH Key to GCP Project

```bash
# Add your public key to GCP metadata
gcloud compute config-ssh --ssh-key-file=~/.ssh/gcp_openclaw
```

This adds your public key to project metadata, allowing SSH to any instance in the project.

### 2.3 (Optional) Add SSH Key to GitHub

If your OpenClaw repo is private:

```bash
# Copy your public key
cat ~/.ssh/gcp_openclaw.pub

# Go to GitHub → Settings → SSH Keys → Add New
```

---

## Step 3: Configure the Project

### 3.1 Clone/Create the Infrastructure Repository

```bash
# If using your own repo
gh repo create openclaw-infra --private
cd openclaw-infra

# Create the directory structure
mkdir -p openclaw-gcp
cd openclaw-gcp
```

### 3.2 Copy the Terraform Files

Create the following files in `openclaw-gcp/`:

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `startup.sh`

(Use the code from the previous messages, or copy from the examples below.)

### 3.3 Update Variables

Edit `variables.tf` with your settings:

```hcl
variable "project" {
  default = "your-actual-project-id"  # CHANGE THIS
}

variable "ssh_source_ip" {
  default = "your-ip-address/32"  # Find yours at https://whatismyip.com
}
```

To find your IP:

```bash
curl -s https://api.ipify.org
```

---

## Step 4: Deploy the Infrastructure

### 4.1 Initialize Terraform

```bash
cd openclaw-gcp
terraform init
```

### 4.2 Review the Plan

```bash
terraform plan
```

This shows what resources will be created. Review carefully!

### 4.3 Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. This typically takes 2-3 minutes.

### 4.4 Save the Output

Note the instance IP address from the output:

```
instance_ip = "34.123.45.678"
```

---

## Step 5: Connect to Your Instance

### 5.1 SSH Into the Instance

```bash
# Using the IP from terraform output
ssh -i ~/.ssh/gcp_openclaw debian@34.123.45.678
```

> **Note:** The default user is `debian` (not `ec2-user` like AWS)

### 5.2 Verify the Setup

```bash
# Check Node.js
node --version
# Should output: v20.x.x

# Check npm
npm --version

# Check Docker
docker --version

# Check PM2 (process manager)
pm2 --version

# Check startup script logs
sudo journalctl -u google-startup-scripts --no-pager | tail -50
```

---

## Step 6: Deploy OpenClaw

### 6.1 Clone Your Repository

```bash
# Navigate to app directory
cd /opt/openclaw

# Clone your OpenClaw repo
git clone https://github.com/YOUR_ORG/openclaw.git .

# Or if using SSH
git clone git@github.com:YOUR_ORG/openclaw.git .
```

### 6.2 Install Dependencies

```bash
npm install
```

### 6.3 Configure Environment Variables

```bash
# Create environment file
cp .env.example .env

# Edit with your settings
nano .env
```

Common variables for OpenClaw:

```bash
# API Keys (example)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Database (if needed)
DATABASE_URL=postgresql://...

# Other configs
NODE_ENV=production
PORT=3000
```

### 6.4 Start OpenClaw

```bash
# Using PM2 for production
pm2 start index.js --name openclaw

# Save PM2 process list (so it restarts on reboot)
pm2 save

# Set up PM2 startup script
pm2 startup
# Follow the instructions output by this command
```

### 6.5 Verify It's Running

```bash
pm2 status
pm2 logs openclaw
```

---

## Step 7: Firewall Configuration (Already Done)

The Terraform configuration automatically creates:

| Rule | Purpose |
|------|---------|
| `allow-ssh` | SSH from your IP only |
| `allow-http-https` | HTTP, HTTPS, ports 3000/8080 |
| `allow-internal` | Communication between instances |

If you need additional ports, edit `main.tf` and re-run `terraform apply`.

---

## Daily Operations

### View Instance Status

```bash
gcloud compute instances list
```

### SSH Into Instance

```bash
ssh -i ~/.ssh/gcp_openclaw debian@YOUR_INSTANCE_IP
```

### View Logs

```bash
# Instance logs
gcloud compute instances get-serial-port-output openclaw-instance --zone us-central1-a

# Application logs (PM2)
pm2 logs openclaw

# System logs
sudo journalctl -u google-startup-scripts --no-pager
```

### Restart OpenClaw

```bash
ssh -i ~/.ssh/gcp_openclaw debian@YOUR_INSTANCE_IP
pm2 restart openclaw
```

### SSH Shortcut (Optional)

Add to `~/.ssh/config`:

```bash
Host openclaw
    HostName YOUR_INSTANCE_IP
    User debian
    IdentityFile ~/.ssh/gcp_openclaw
    ForwardAgent yes
```

Then simply run:

```bash
ssh openclaw
```

---

## Troubleshooting

### SSH Connection Issues

```bash
# Check if instance is running
gcloud compute instances list

# Check firewall rules
gcloud compute firewall-rules list

# Test connectivity
ping YOUR_INSTANCE_IP
```

### Terraform Errors

```bash
# Refresh state
terraform refresh

# View detailed errors
terraform apply -var="project=your-project" -verbose
```

### Instance Won't Start

```bash
# Check serial port output for errors
gcloud compute instances get-serial-port-output openclaw-instance --zone us-central1-a
```

### Out of Disk Space

The default disk is 30GB. To resize:

```bash
# Edit variables.tf, change disk_size_gb
# Then apply
terraform apply -var="disk_size_gb=100"
```

---

## Cleaning Up

### Destroy All Resources

```bash
cd openclaw-gcp
terraform destroy
```

This terminates the instance and deletes all firewall rules. Your static IP (if reserved) will need to be deleted separately:

```bash
gcloud compute addresses delete openclaw-ip --region us-central1
```

---

## Next Steps (Optional Enhancements)

### Reserve a Static IP

Add to `main.tf`:

```hcl
resource "google_compute_address" "static_ip" {
  name   = "${var.project_name}-static-ip"
  region = var.region
}
```

### Add a Domain with Cloud DNS

```hcl
resource "google_dns_record_set" "openclaw" {
  name = "openclaw.yourdomain.com."
  type = "A"
  ttl  = 300
  zone = google_dns_managed_zone.main.name
  rrdatas = [google_compute_instance.openclaw.network_interface[0].access_config[0].nat_ip]
}
```

### Set Up SSL with Let's Encrypt

```bash
# On the instance
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d openclaw.yourdomain.com
```

### Add Monitoring with Cloud Monitoring

The Terraform already includes basic monitoring. To view:

```bash
# In GCP Console
# Monitoring → Dashboard → VM Instance
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Deploy infrastructure | `terraform apply` |
| Destroy infrastructure | `terraform destroy` |
| SSH to instance | `ssh -i ~/.ssh/gcp_openclaw debian@IP` |
| Restart OpenClaw | `pm2 restart openclaw` |
| View logs | `pm2 logs openclaw` |
| Check instance | `gcloud compute instances list` |

---

## Support

- **GCP Docs**: [cloud.google.com/compute/docs](https://cloud.google.com/compute/docs)
- **Terraform GCP Provider**: [registry.terraform.io/providers/hashicorp/google](https://registry.terraform.io/providers/hashicorp/google)
- **OpenClaw Repo**: [github.com/openclaw](https://github.com/openclaw)
