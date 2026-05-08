resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

resource "cloudflare_zero_trust_tunnel_warp_connector" "sflow_proxy" {
  account_id    = var.cloudflare_account_id
  name          = "sFlow Proxy"
  ha            = true
  tunnel_secret = base64encode(random_password.tunnel_secret.result)
}

locals {
  connector_token = base64encode(jsonencode({
    a = var.cloudflare_account_id
    t = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.id
    s = base64encode(random_password.tunnel_secret.result)
  }))
}
