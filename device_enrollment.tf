# NOTE: Only one WARP-type Access Application can exist per account.
# If it already exists, import it first:
#   terraform import cloudflare_zero_trust_access_application.mesh_device_enrollment <account_id>/<app_id>
#
# To find the existing app ID, run:
#   curl -s "https://api.cloudflare.com/client/v4/accounts/<ACCOUNT_ID>/access/apps" \
#     -H "Authorization: Bearer <API_TOKEN>" | jq '.result[] | select(.type=="warp") | .id'

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
