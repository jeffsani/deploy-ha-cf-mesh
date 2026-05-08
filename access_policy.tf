resource "cloudflare_zero_trust_access_policy" "mesh_service_auth" {
  account_id = var.cloudflare_account_id
  name       = "sFlow Mesh Service Token Auth"
  decision   = "non_identity"

  include = [
    {
      service_token = {
        token_id = cloudflare_zero_trust_access_service_token.mesh_service_token.id
      }
    }
  ]
}
