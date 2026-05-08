resource "local_file" "install_debian" {
  filename = "${path.module}/scripts/generated/install_debian.sh"

  content = templatefile("${path.module}/scripts/install_debian.sh.tpl", {
    connector_name  = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.name
    connector_token = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.token_value
  })

  file_permission = "0755"
}

resource "local_file" "install_rhel" {
  filename = "${path.module}/scripts/generated/install_rhel.sh"

  content = templatefile("${path.module}/scripts/install_rhel.sh.tpl", {
    connector_name  = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.name
    connector_token = cloudflare_zero_trust_tunnel_warp_connector.sflow_proxy.token_value
  })

  file_permission = "0755"
}
