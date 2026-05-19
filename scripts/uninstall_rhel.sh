#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Cloudflare Mesh Connector Uninstall Script — RHEL/CentOS/Fedora
#
# Usage:
#   sudo ./uninstall_rhel.sh <ACCOUNT_ID> <API_TOKEN>
#
# Arguments:
#   ACCOUNT_ID  — Cloudflare account ID
#   API_TOKEN   — Cloudflare API token with MNM Admin permission
#
# This script:
#   1. Reads the WARP device ID before disconnecting
#   2. Removes this device from the MNM config via API
#   3. Disconnects and deregisters the WARP connector
#   4. Uninstalls the cloudflare-warp package
#   5. Removes firewall rules and sysctl settings added by the install script
# =============================================================================

ACCOUNT_ID="${1:-}"
API_TOKEN="${2:-}"

if [[ -z "$ACCOUNT_ID" || -z "$API_TOKEN" ]]; then
  echo "ERROR: Both arguments are required."
  echo "Usage: $0 <ACCOUNT_ID> <API_TOKEN>"
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Capture WARP device ID before we tear anything down
# ---------------------------------------------------------------------------
DEVICE_ID=$(warp-cli registration show 2>/dev/null | grep -i '^Device ID:' | awk '{print $NF}') || true

# ---------------------------------------------------------------------------
# 2. Remove this device from MNM config
# ---------------------------------------------------------------------------
if [[ -n "$DEVICE_ID" ]]; then
  echo ">>> Removing device $DEVICE_ID from MNM config..."
  CURRENT_CONFIG=$(curl -sf \
    "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/mnm/config" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json") || true

  if [[ -n "$CURRENT_CONFIG" ]]; then
    UPDATED_PAYLOAD=$(echo "$CURRENT_CONFIG" | python3 -c "
import json, sys
cfg = json.load(sys.stdin).get('result', {})
devices = cfg.get('warp_devices', [])
router_ips = cfg.get('router_ips', [])

# Remove all entries for this device
remaining = [d for d in devices if d['id'] != '$DEVICE_ID']

# Rebuild router_ips from remaining devices only
active_ips = {d['router_ip'] for d in remaining}
router_ips = [ip for ip in router_ips if ip in active_ips]

json.dump({'router_ips': router_ips, 'warp_devices': remaining}, sys.stdout)
") || true

    if [[ -n "$UPDATED_PAYLOAD" ]]; then
      curl -sf "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/mnm/config" \
        --request PATCH \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "$UPDATED_PAYLOAD" > /dev/null || true
      echo ">>> MNM config updated."
    fi
  fi
else
  echo ">>> No WARP device ID found — skipping MNM cleanup."
fi

# ---------------------------------------------------------------------------
# 3. Disconnect and deregister the connector
# ---------------------------------------------------------------------------
echo ">>> Disconnecting WARP..."
warp-cli --accept-tos disconnect 2>/dev/null || true

echo ">>> Deregistering connector..."
warp-cli --accept-tos registration delete 2>/dev/null || true

# ---------------------------------------------------------------------------
# 4. Uninstall the WARP client
# ---------------------------------------------------------------------------
echo ">>> Uninstalling cloudflare-warp..."
sudo yum remove -y cloudflare-warp || true

# ---------------------------------------------------------------------------
# 5. Clean up firewall rules
# ---------------------------------------------------------------------------
if command -v firewall-cmd &>/dev/null; then
  echo ">>> Removing firewalld rules..."
  sudo firewall-cmd --permanent --remove-port=2408/udp  2>/dev/null || true
  sudo firewall-cmd --permanent --remove-port=500/udp   2>/dev/null || true
  sudo firewall-cmd --permanent --remove-port=4500/udp  2>/dev/null || true
  sudo firewall-cmd --permanent --remove-port=443/tcp   2>/dev/null || true
  sudo firewall-cmd --permanent --remove-port=443/udp   2>/dev/null || true
  sudo firewall-cmd --reload
  echo ">>> firewalld rules removed."
fi

# ---------------------------------------------------------------------------
# 6. Remove sysctl override (optional — only if no other service needs it)
# ---------------------------------------------------------------------------
if [[ -f /etc/sysctl.d/99-cloudflare-mesh.conf ]]; then
  echo ">>> Removing IP forwarding sysctl override..."
  sudo rm -f /etc/sysctl.d/99-cloudflare-mesh.conf
  sudo sysctl --system
fi

echo ">>> Mesh Connector uninstall complete."
