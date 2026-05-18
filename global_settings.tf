# Global device management settings required for Cloudflare Mesh.
#
# NOTE: "Allow all Cloudflare One traffic to reach enrolled devices" (Mesh connectivity)
# must be enabled manually in the dashboard — there is no Terraform attribute for it yet.
# See: https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/configure/settings/#allow-all-cloudflare-one-traffic-to-reach-enrolled-devices

resource "cloudflare_zero_trust_device_settings" "global" {
  account_id = var.cloudflare_account_id

  # Assign a unique CGNAT IP to each device (required for Mesh)
  use_zt_virtual_ip = true

  # Enable Gateway proxy for TCP and UDP (required for Mesh traffic)
  gateway_proxy_enabled     = true
  gateway_udp_proxy_enabled = true

  # Required defaults — omitting these can cause "invalid account settings request"
  root_certificate_installation_enabled = true
  disable_for_time                      = 0
}
