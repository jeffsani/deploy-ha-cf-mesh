resource "cloudflare_zero_trust_access_service_token" "mesh_service_token" {
  account_id = var.cloudflare_account_id
  name       = "sFlow Mesh Service Token"
  duration   = var.service_token_duration

  lifecycle {
    create_before_destroy = true
  }
}
