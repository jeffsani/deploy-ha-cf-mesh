resource "cloudflare_zero_trust_tunnel_warp_connector" "sflow_proxy" {
  account_id = var.cloudflare_account_id
  name       = "sFlow Proxy"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "sflow_proxy_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.id
}
