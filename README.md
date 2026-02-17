# CLAW GCP Infrastructure

Terraform configuration to deploy claw-like instances on Google Cloud Platform.

## Prerequisites

### Tools You Need on macOS
* homebrew
* terraform
* google-cloud-sdk
* git


## Step 1: Google Cloud Platform Setup

### 1.1 Create a GCP Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click the project dropdown (top left) → **New Project**
3. Name it `trueclaw` (or your preference)
4. Note your **Project ID** (it'll be something like `trueclaw-12345`)

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
ssh-keygen -t ed25519 -C "trueclaw@gcp" -f ~/.ssh/gcp_trueclaw

# Secure the key
chmod 600 ~/.ssh/gcp_trueclaw
```

### 2.2 Add SSH Key to GCP Project

```bash
# Add your public key to GCP metadata
gcloud compute config-ssh --ssh-key-file=~/.ssh/gcp_trueclaw
```

This adds your public key to project metadata, allowing SSH to any instance in the project.

### 2.3 (Optional) Add SSH Key to GitHub

If your trueclaw repo is private:

```bash
# Copy your public key
cat ~/.ssh/gcp_trueclaw.pub

# Go to GitHub → Settings → SSH Keys → Add New
```

---

## Step 3: Configure the Project

### 3.1 Clone/Create the Infrastructure Repository

```bash
# If using your own repo
gh repo create trueclaw-infra --private
cd trueclaw-infra

# Create the directory structure
mkdir -p trueclaw-gcp
cd trueclaw-gcp
```

### 3.2 Copy the Terraform Files

Create the following files in `trueclaw-gcp/`:

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
cd trueclaw-gcp
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
ssh -i ~/.ssh/gcp_trueclaw debian@34.123.45.678
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

## Step 6: Deploy trueclaw

### 6.1 Clone Your Repository

```bash
# Navigate to app directory
cd /opt/trueclaw

# Clone your trueclaw repo
git clone https://github.com/YOUR_ORG/trueclaw.git .

# Or if using SSH
git clone git@github.com:YOUR_ORG/trueclaw.git .
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

Common variables for trueclaw:

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

### 6.4 Start trueclaw

```bash
# Using PM2 for production
pm2 start index.js --name trueclaw

# Save PM2 process list (so it restarts on reboot)
pm2 save

# Set up PM2 startup script
pm2 startup
# Follow the instructions output by this command
```

### 6.5 Verify It's Running

```bash
pm2 status
pm2 logs trueclaw
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
ssh -i ~/.ssh/gcp_trueclaw debian@YOUR_INSTANCE_IP
```

### View Logs

```bash
# Instance logs
gcloud compute instances get-serial-port-output trueclaw-instance --zone us-central1-a

# Application logs (PM2)
pm2 logs trueclaw

# System logs
sudo journalctl -u google-startup-scripts --no-pager
```

### Restart trueclaw

```bash
ssh -i ~/.ssh/gcp_trueclaw debian@YOUR_INSTANCE_IP
pm2 restart trueclaw
```

### SSH Shortcut (Optional)

Add to `~/.ssh/config`:

```bash
Host trueclaw
    HostName YOUR_INSTANCE_IP
    User debian
    IdentityFile ~/.ssh/gcp_trueclaw
    ForwardAgent yes
```

Then simply run:

```bash
ssh trueclaw
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
gcloud compute instances get-serial-port-output trueclaw-instance --zone us-central1-a
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
cd trueclaw-gcp
terraform destroy
```

This terminates the instance and deletes all firewall rules. Your static IP (if reserved) will need to be deleted separately:

```bash
gcloud compute addresses delete trueclaw-ip --region us-central1
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
resource "google_dns_record_set" "trueclaw" {
  name = "trueclaw.yourdomain.com."
  type = "A"
  ttl  = 300
  zone = google_dns_managed_zone.main.name
  rrdatas = [google_compute_instance.trueclaw.network_interface[0].access_config[0].nat_ip]
}
```

### Set Up SSL with Let's Encrypt

```bash
# On the instance
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d trueclaw.yourdomain.com
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
| SSH to instance | `ssh -i ~/.ssh/gcp_trueclaw debian@IP` |
| Restart trueclaw | `pm2 restart trueclaw` |
| View logs | `pm2 logs trueclaw` |
| Check instance | `gcloud compute instances list` |

---

## Support

- **GCP Docs**: [cloud.google.com/compute/docs](https://cloud.google.com/compute/docs)
- **Terraform GCP Provider**: [registry.terraform.io/providers/hashicorp/google](https://registry.terraform.io/providers/hashicorp/google)
- **trueclaw Repo**: [github.com/trueclaw](https://github.com/trueclaw)
