output "service_token_client_id" {
  description = "Client ID of the service token for headless device enrollment"
  value       = cloudflare_zero_trust_access_service_token.mesh_service_token.client_id
}

output "service_token_client_secret" {
  description = "Client Secret of the service token (sensitive)"
  value       = cloudflare_zero_trust_access_service_token.mesh_service_token.client_secret
  sensitive   = true
}

output "connector_id" {
  description = "ID of the mesh connector"
  value       = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.id
}

output "connector_name" {
  description = "Name of the mesh connector"
  value       = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.name
}

output "connector_token" {
  description = "Token for the mesh connector — use on all replica hosts (sensitive)"
  value       = local.connector_token
  sensitive   = true
}

