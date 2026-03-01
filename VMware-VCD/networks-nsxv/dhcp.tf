resource "vcd_nsxv_dhcp_relay" "relay" {
  count = local.dhcp_relay_enabled ? 1 : 0

  edge_gateway = var.edge_gateway_name
  ip_addresses = try(var.dhcp.ip_addresses, [])
  ip_sets      = try(var.dhcp.ip_sets, [])
  domain_names = try(var.dhcp.domain_names, [])

  dynamic "relay_agent" {
    for_each = try(var.dhcp.relay_agents, [])
    content {
      network_name       = relay_agent.value.network_name
      gateway_ip_address = relay_agent.value.gateway_ip_address
    }
  }
}
