resource "cloudflare_zero_trust_tunnel_warp_connector" "sflow_proxy" {
  account_id = var.cloudflare_account_id
  name       = "sFlow Proxy"
}
