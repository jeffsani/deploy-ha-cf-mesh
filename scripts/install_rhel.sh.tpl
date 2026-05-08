#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sFlow Mesh Connector Install Script — RHEL/CentOS/Fedora
# Connector: ${connector_name}
# =============================================================================

echo ">>> Installing Cloudflare WARP client (RHEL/CentOS/Fedora)..."

# Add cloudflare-warp.repo to /etc/yum.repos.d/
curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo

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
warp-cli connector new ${connector_token}
warp-cli connect

echo ">>> sFlow Mesh Connector '${connector_name}' setup complete."
