# Only one WARP-type Access Application can exist per account.
# The import block below adopts the pre-existing app into Terraform state.
import {
  to = cloudflare_zero_trust_access_application.mesh_device_enrollment
  id = "${var.cloudflare_account_id}/${var.warp_app_id}"
}

resource "cloudflare_zero_trust_access_application" "mesh_device_enrollment" {
  account_id       = var.cloudflare_account_id
  type             = "warp"
  name             = "sFlow Mesh Device Enrollment"
  session_duration = "24h"

  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.mesh_service_auth.id
      precedence = 1
    }
  ]
}
