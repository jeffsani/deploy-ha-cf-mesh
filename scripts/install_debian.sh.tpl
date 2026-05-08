#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sFlow Mesh Connector Install Script — Debian/Ubuntu
# Connector: ${connector_name}
# =============================================================================

echo ">>> Installing Cloudflare WARP client (Debian/Ubuntu)..."

# Setup pubkey, apt repo, and update/install the Cloudflare One Client
curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
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
warp-cli connector new ${connector_token}
warp-cli connect

echo ">>> sFlow Mesh Connector '${connector_name}' setup complete."
