# Magic Network Monitoring configuration — registers each mesh connector
# as a WARP device and maps it to the router IPs it tunnels traffic for.
# This tells the Cloudflare flow collector which encrypted tunnel carries
# each router's sFlow/NetFlow/IPFIX data.

locals {
  # Flatten var.routers into a list of { region, router_ip } objects
  router_entries = flatten([
    for region, ips in var.routers : [
      for ip in ips : {
        region    = region
        router_ip = ip
      }
    ]
  ])

  # Build the warp_devices list expected by the MNM config resource
  warp_devices = [
    for entry in local.router_entries : {
      id        = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy[entry.region].id
      name      = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy[entry.region].name
      router_ip = entry.router_ip
    }
  ]

  # Deduplicate router IPs across all regions for the top-level router_ips list
  all_router_ips = distinct([for entry in local.router_entries : entry.router_ip])

  # JSON payload for the PATCH call below
  mnm_payload = jsonencode({
    router_ips   = local.all_router_ips
    warp_devices = local.warp_devices
  })
}

# The cloudflare_magic_network_monitoring_configuration resource does not
# support import, and the MNM config is a per-account singleton that already
# exists (POST returns 403 "Account already exists").  We call the PATCH
# endpoint directly so Terraform can manage the warp_devices mapping without
# needing to import the pre-existing object.

resource "terraform_data" "mnm_config" {
  count = length(var.routers) > 0 ? 1 : 0

  triggers_replace = local.mnm_payload

  provisioner "local-exec" {
    command = <<-EOT
      curl -sf "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/mnm/config" \
        --request PATCH \
        --header "Authorization: Bearer ${var.cloudflare_api_token}" \
        --header "Content-Type: application/json" \
        --data '${local.mnm_payload}'
    EOT
  }
}
