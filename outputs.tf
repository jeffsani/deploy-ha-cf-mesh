output "service_token_client_id" {
  description = "Client ID of the service token for headless device enrollment"
  value       = cloudflare_zero_trust_access_service_token.mesh_service_token.client_id
}

output "service_token_client_secret" {
  description = "Client Secret of the service token (sensitive)"
  value       = cloudflare_zero_trust_access_service_token.mesh_service_token.client_secret
  sensitive   = true
}

output "connector_ids" {
  description = "Map of region → mesh connector ID"
  value       = { for region, conn in cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy : region => conn.id }
}

output "connector_names" {
  description = "Map of region → mesh connector name"
  value       = { for region, conn in cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy : region => conn.name }
}

output "connector_tokens" {
  description = "Map of region → connector token — use on all replica hosts in that region (sensitive)"
  value       = local.connector_tokens
  sensitive   = true
}

