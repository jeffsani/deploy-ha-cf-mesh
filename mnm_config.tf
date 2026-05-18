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
}

import {
  for_each = length(var.routers) > 0 ? toset(["import"]) : toset([])
  to       = cloudflare_magic_network_monitoring_configuration.flow_config[0]
  id       = var.cloudflare_account_id
}

resource "cloudflare_magic_network_monitoring_configuration" "flow_config" {
  count = length(var.routers) > 0 ? 1 : 0

  account_id       = var.cloudflare_account_id
  name             = var.team_name
  default_sampling = 1
  router_ips       = local.all_router_ips
  warp_devices     = local.warp_devices
}
