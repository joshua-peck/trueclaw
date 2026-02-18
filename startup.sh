#!/bin/bash
set -e

echo "🚀 Starting trueclaw bootstrap..."

# Update system
apt-get update

apt install build-essential g++ clang libssl-dev -y

echo "alias ll='ls -lFa'" >> ~/.bashrc

echo "✅ Bootstrap complete!"
echo "   Node: $(node --version)"
echo "   NPM: $(npm --version)"

echo "  Install OpenClaw CLI:"
echo "  $ curl -fsSL https://openclaw.ai/install-cli.sh | bash"
echo "  You may need to update CMake (https://cmake.org/download/)"

