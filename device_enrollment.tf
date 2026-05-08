# Only one WARP-type Access Application can exist per account.
#
# Fresh deploy (warp_app_id = ""):
#   Terraform creates the app normally.
#
# Existing account (warp_app_id = "<uuid>"):
#   The import block below adopts the pre-existing app into state.
#   After the first successful apply, you can clear warp_app_id back to "".

import {
  for_each = var.warp_app_id != "" ? toset([var.warp_app_id]) : toset([])
  to       = cloudflare_zero_trust_access_application.mesh_device_enrollment
  id       = "accounts/${var.cloudflare_account_id}/${each.value}"
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
