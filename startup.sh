#!/bin/bash
set -e

echo "🚀 Starting trueclaw bootstrap..."

# Update system
apt-get update

# set up GPU connections
apt upgrade -y
apt install -y build-essential dkms linux-headers-$(uname -r)
apt install firmware-misc-nonfree nvidia-driver -y
apt update
sed -i '/^Components:/ s/$/ contrib non-free-firmware non-free/' /etc/apt/sources.list.d/debian.sources

# install build dependencies
apt install build-essential g++ clang libssl-dev -y

echo "alias ll='ls -lFa'" >> ~/.bashrc

echo "✅ Bootstrap complete!"
echo "   Node: $(node --version)"
echo "   NPM: $(npm --version)"

echo "  Install OpenClaw CLI:"
echo "  $ curl -fsSL https://openclaw.ai/install-cli.sh | bash"
echo "  You may need to update CMake (https://cmake.org/download/)"

