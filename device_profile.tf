resource "cloudflare_zero_trust_device_custom_profile" "sflow" {
  account_id  = var.cloudflare_account_id
  name        = "sFlow"
  description = "Device Profile for Cloudflare Mesh Connector used to secure sFlow"
  enabled     = true
  precedence  = 100

  match = "identity.email == \"warp_connector@${var.team_name}.cloudflareaccess.com\""

  tunnel_protocol = "masque"

  service_mode_v2 = {
    mode = "warp_tunnel_only"
  }

  captive_portal = 0
  allow_updates  = true

  include = [
    {
      address     = "162.159.65.1/32"
      description = "Cloudflare sFlow Collector Anycast IP"
    }
  ]
}
