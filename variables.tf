variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zero Trust permissions"
  type        = string
  sensitive   = true
}

variable "team_name" {
  description = "Cloudflare Zero Trust team/organization name (the subdomain in <team>.cloudflareaccess.com)"
  type        = string
}

variable "warp_app_id" {
  description = "ID of an existing WARP-type Access Application to import. Leave empty for a fresh deploy. Find with: curl -s 'https://api.cloudflare.com/client/v4/accounts/<ACCOUNT_ID>/access/apps' -H 'Authorization: Bearer <TOKEN>' | jq '.result[] | select(.type==\"warp\") | .id'"
  type        = string
  default     = ""
}

variable "regions" {
  description = "List of region identifiers. One HA mesh connector is created per region."
  type        = list(string)
  default     = ["default"]
}

variable "routers" {
  description = "Map of region → list of router IPs that export flow data through that region's mesh connector. Each IP is registered with Cloudflare Magic Network Monitoring so the collector knows which WARP device tunnels each router's flows."
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue([
      for region, ips in var.routers : alltrue([
        for ip in ips : can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", ip))
      ])
    ])
    error_message = "Each router entry must be a valid IPv4 address (e.g. 10.0.1.1)."
  }
}

variable "service_token_duration" {
  description = "Duration of the service token (e.g. 8760h = 1 year)"
  type        = string
  default     = "8760h"
}
