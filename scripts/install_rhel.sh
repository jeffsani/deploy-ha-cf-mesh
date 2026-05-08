#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Cloudflare Mesh Connector Install Script — RHEL/CentOS/Fedora
#
# Usage:
#   sudo ./install_rhel.sh <CONNECTOR_TOKEN>
#
# The connector token can be obtained from Terraform:
#   terraform output -raw connector_token
# =============================================================================

CONNECTOR_TOKEN="${1:-}"

if [[ -z "$CONNECTOR_TOKEN" ]]; then
  echo "ERROR: Connector token is required."
  echo "Usage: $0 <CONNECTOR_TOKEN>"
  echo ""
  echo "Get the token with: terraform output -raw connector_token"
  exit 1
fi

echo ">>> Installing Cloudflare WARP client (RHEL/CentOS/Fedora)..."

# Add cloudflare-warp.repo to /etc/yum.repos.d/
curl -fsSL https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo

# Update repo
sudo yum update -y

# Install
sudo yum install -y cloudflare-warp

# Enable IP forwarding on the host (persistent)
echo ">>> Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-cloudflare-mesh.conf
sudo sysctl --system

# Configure firewall exceptions for Cloudflare WARP/Mesh
echo ">>> Configuring firewalld rules..."
if command -v firewall-cmd &>/dev/null; then
  sudo firewall-cmd --permanent --add-port=2408/udp   # Cloudflare WARP
  sudo firewall-cmd --permanent --add-port=500/udp    # IKE
  sudo firewall-cmd --permanent --add-port=4500/udp   # NAT-T
  sudo firewall-cmd --permanent --add-port=443/tcp    # HTTPS
  sudo firewall-cmd --permanent --add-port=443/udp    # MASQUE
  sudo firewall-cmd --reload
  echo ">>> firewalld rules applied."
else
  echo ">>> firewalld not found — skipping firewall config. Add rules manually if using another firewall."
fi

# Register and connect the Mesh Connector
echo ">>> Registering mesh connector..."
warp-cli connector new "$CONNECTOR_TOKEN"
warp-cli connect

echo ">>> Mesh Connector setup complete."
