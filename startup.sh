#!/bin/bash
set -e

echo "🚀 Starting trueclaw bootstrap..."

# Update system
apt-get update

# # Install common tools
# dnf install -y \
#   git \
#   curl \
#   wget \
#   jq \
#   nano \
#   htop \
#   ca-certificates \
#   gnupg

# # Install Node.js 20.x (LTS)
# dnf module enable nodejs:20 -y
# dnf install -y nodejs

# # Verify Node.js installation
# node --version
# npm --version

# # Install PM2 for production process management (recommended for Node.js)
# npm install -g pm2

# # Install Docker (if needed for containers)
# dnf install -y docker
# systemctl start docker
# systemctl enable docker
# usermod -aG docker $USER

# # Install Docker Compose
# COMPOSE_VERSION=$(curl -sL https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
# curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose

# # Optional: Install Python (some Node.js tools need it)
# dnf install -y python3 python3-pip

# # Create application directory
# mkdir -p /opt/trueclaw
# cd /opt/trueclaw

# # If you have your repo, uncomment:
# # git clone https://github.com/your-org/trueclaw.git .

# echo "✅ Bootstrap complete!"
# echo "   Node: $(node --version)"
# echo "   NPM: $(npm --version)"
# echo "   PM2: $(pm2 --version)"
# echo "   Docker: $(docker --version)"
# echo ""
# echo "   To start trueclaw:"
# echo "   cd /opt/trueclaw"
# echo "   npm install"
# echo "   pm2 start index.js"

