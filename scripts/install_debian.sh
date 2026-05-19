#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Cloudflare Mesh Connector Install Script — Debian/Ubuntu
#
# Usage:
#   sudo ./install_debian.sh <CONNECTOR_TOKEN> <ROUTER_IPS> <ACCOUNT_ID> <API_TOKEN>
#
# Arguments:
#   CONNECTOR_TOKEN  — from: terraform output -json connector_tokens | jq -r '."<region>"'
#   ROUTER_IPS       — Comma-separated router IPs whose flow data this node tunnels
#                      e.g. "10.1.0.1" or "10.1.0.1,10.1.0.2,10.2.0.1"
#   ACCOUNT_ID       — Cloudflare account ID
#   API_TOKEN        — Cloudflare API token with MNM Admin permission
# =============================================================================

CONNECTOR_TOKEN="${1:-}"
ROUTER_IPS="${2:-}"
ACCOUNT_ID="${3:-}"
API_TOKEN="${4:-}"

if [[ -z "$CONNECTOR_TOKEN" || -z "$ROUTER_IPS" || -z "$ACCOUNT_ID" || -z "$API_TOKEN" ]]; then
  echo "ERROR: All four arguments are required."
  echo "Usage: $0 <CONNECTOR_TOKEN> <ROUTER_IPS> <ACCOUNT_ID> <API_TOKEN>"
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

# ---------------------------------------------------------------------------
# Auto-register this WARP device with Magic Network Monitoring
# ---------------------------------------------------------------------------
echo ">>> Registering device with Magic Network Monitoring..."

# Wait briefly for registration to propagate
sleep 5

# Get the WARP device ID from the local registration
DEVICE_ID=$(warp-cli registration show 2>/dev/null | grep -i '^Device ID:' | awk '{print $NF}')
if [[ -z "$DEVICE_ID" ]]; then
  echo "WARNING: Could not obtain WARP Device ID. MNM registration skipped."
  echo "         Run 'warp-cli registration show' manually and register via the API."
  exit 0
fi

DEVICE_NAME=$(hostname)-mesh

# Fetch the current MNM config
CURRENT_CONFIG=$(curl -sf \
  "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/mnm/config" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json")

# Step 1: Remove any stale entries for this host (the API won't update a
#         device ID in-place — you must remove first, then re-add).
REMOVE_PAYLOAD=$(echo "$CURRENT_CONFIG" | python3 -c "
import json, sys
cfg = json.load(sys.stdin).get('result', {})
devices = cfg.get('warp_devices', [])
router_ips = cfg.get('router_ips', [])

# Remove entries matching this host's name or device ID
devices = [d for d in devices if d.get('name') != '$DEVICE_NAME' and d['id'] != '$DEVICE_ID']

# Prune router_ips that no longer have any device
active_ips = {d['router_ip'] for d in devices}
router_ips = [ip for ip in router_ips if ip in active_ips]

json.dump({'router_ips': router_ips, 'warp_devices': devices}, sys.stdout)
")

curl -sf "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/mnm/config" \
  --request PATCH \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "$REMOVE_PAYLOAD" > /dev/null

# Step 2: Re-fetch config and add this device with the current ID
CURRENT_CONFIG=$(curl -sf \
  "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/mnm/config" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json")

ADD_PAYLOAD=$(echo "$CURRENT_CONFIG" | python3 -c "
import json, sys
cfg = json.load(sys.stdin).get('result', {})
devices = cfg.get('warp_devices', [])
router_ips = cfg.get('router_ips', [])

for ip in '$ROUTER_IPS'.split(','):
    ip = ip.strip()
    devices.append({'id': '$DEVICE_ID', 'name': '$DEVICE_NAME', 'router_ip': ip})
    if ip not in router_ips:
        router_ips.append(ip)

json.dump({'router_ips': router_ips, 'warp_devices': devices}, sys.stdout)
")

curl -sf "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/mnm/config" \
  --request PATCH \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "$ADD_PAYLOAD" > /dev/null

echo ">>> MNM registration complete (Device ID: $DEVICE_ID, Routers: $ROUTER_IPS)."
echo ">>> Mesh Connector setup complete."
