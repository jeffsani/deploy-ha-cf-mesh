#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Cloudflare Mesh Connector Install Script — Debian/Ubuntu
#
# Usage:
#   sudo ./install_debian.sh <CONNECTOR_TOKEN>
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

echo ">>> Installing Cloudflare WARP client (Debian/Ubuntu)..."

# Setup pubkey, apt repo, and update/install the Cloudflare One Client
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt-get update && sudo apt-get install -y cloudflare-warp

# Enable IP forwarding on the host (persistent)
echo ">>> Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-cloudflare-mesh.conf
sudo sysctl --system

# Configure firewall exceptions for Cloudflare WARP/Mesh
echo ">>> Configuring UFW firewall rules..."
if command -v ufw &>/dev/null; then
  sudo ufw allow 2408/udp comment "Cloudflare WARP"
  sudo ufw allow 500/udp  comment "Cloudflare WARP IKE"
  sudo ufw allow 4500/udp comment "Cloudflare WARP NAT-T"
  sudo ufw allow 443/tcp  comment "Cloudflare WARP HTTPS"
  sudo ufw allow 443/udp  comment "Cloudflare WARP MASQUE"
  sudo ufw reload
  echo ">>> UFW rules applied."
else
  echo ">>> UFW not found — skipping firewall config. Add rules manually if using another firewall."
fi

# Register and connect the Mesh Connector
echo ">>> Registering mesh connector..."
warp-cli --accept-tos connector new "$CONNECTOR_TOKEN"
warp-cli --accept-tos connect

echo ">>> Mesh Connector setup complete."
