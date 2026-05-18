# Magic Network Monitoring (MNM) — WARP device registration
#
# MNM configuration is handled automatically by the install scripts
# (scripts/install_debian.sh, scripts/install_rhel.sh).  After enrolling a
# host as a mesh connector, the script:
#   1. Reads the WARP device ID via  warp-cli registration show
#   2. Fetches the current MNM config via GET /accounts/{id}/mnm/config
#   3. Appends this device + router IP (deduplicated)
#   4. PATCHes the MNM config back
#
# No Terraform resource is needed — the cloudflare_magic_network_monitoring_configuration
# provider resource does not support import and the config is a per-account singleton.
#
# To view the current MNM config:
#   curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/mnm/config" \
#     -H "Authorization: Bearer $API_TOKEN" | jq .result
