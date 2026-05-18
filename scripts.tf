# Install scripts are standalone bash scripts in scripts/.
# They accept four arguments: connector token, router IP, account ID, API token.
# After enrolling the host, the script auto-registers the WARP device with
# Magic Network Monitoring (MNM) so encrypted flow data is routed correctly.
#
# Usage:
#   TOKEN=$(terraform output -json connector_tokens | jq -r '."<region>"')
#   scp scripts/install_debian.sh user@host:~/
#   ssh user@host "chmod +x ~/install_debian.sh && sudo ~/install_debian.sh \
#     $TOKEN <ROUTER_IPS> <ACCOUNT_ID> <API_TOKEN>"
#
# ROUTER_IPS can be a single IP or comma-separated for multiple routers:
#   "10.1.0.1" or "10.1.0.1,10.1.0.2"
