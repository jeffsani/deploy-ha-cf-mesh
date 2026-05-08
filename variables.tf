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
  description = "Cloudflare Zero Trust team/organization name (e.g. marigold68)"
  type        = string
}

variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string
  default     = "JPS_Consulting"
}

variable "tfc_workspace" {
  description = "Terraform Cloud workspace name"
  type        = string
  default     = "deploy-ha-cf-mesh"
}

variable "service_token_duration" {
  description = "Duration of the service token (e.g. 8760h = 1 year)"
  type        = string
  default     = "8760h"
}
