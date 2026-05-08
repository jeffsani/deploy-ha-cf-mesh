resource "cloudflare_zero_trust_access_application" "mesh_device_enrollment" {
  account_id           = var.cloudflare_account_id
  type                 = "warp"
  name                 = "sFlow Mesh Device Enrollment"
  app_launcher_visible = false
  session_duration     = "24h"

  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.mesh_service_auth.id
      precedence = 1
    }
  ]
}
