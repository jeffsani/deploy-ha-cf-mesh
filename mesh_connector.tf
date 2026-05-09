resource "random_password" "tunnel_secret" {
  for_each = toset(var.regions)
  length   = 64
  special  = false
}

resource "cloudflare_zero_trust_tunnel_warp_connector" "sflow_proxy" {
  for_each      = toset(var.regions)
  account_id    = var.cloudflare_account_id
  name          = "sFlow Proxy - ${each.key}"
  ha            = true
  tunnel_secret = base64encode(random_password.tunnel_secret[each.key].result)
}

locals {
  connector_tokens = {
    for region in var.regions : region => base64encode(jsonencode({
      a = var.cloudflare_account_id
      t = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy[region].id
      s = base64encode(random_password.tunnel_secret[region].result)
    }))
  }
}
