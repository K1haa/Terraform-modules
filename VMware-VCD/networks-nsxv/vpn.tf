resource "vcd_edgegateway_vpn" "ipsec" {
  for_each = local.vpn_ipsec_tunnels

  edge_gateway        = var.edge_gateway_name
  name                = each.value.name
  description         = try(each.value.description, null)
  encryption_protocol = each.value.encryption_protocol
  mtu                 = try(each.value.mtu, null)
  peer_id             = each.value.peer_id
  peer_ip_address     = each.value.peer_ip_address
  local_id            = each.value.local_id
  local_ip_address    = each.value.local_ip_address
  shared_secret       = each.value.shared_secret

  dynamic "peer_subnets" {
    for_each = try(each.value.peer_subnets, [])
    content {
      peer_subnet_name    = peer_subnets.value.name
      peer_subnet_gateway = peer_subnets.value.gateway
      peer_subnet_mask    = peer_subnets.value.mask
    }
  }

  dynamic "local_subnets" {
    for_each = try(each.value.local_subnets, [])
    content {
      local_subnet_name    = local_subnets.value.name
      local_subnet_gateway = local_subnets.value.gateway
      local_subnet_mask    = local_subnets.value.mask
    }
  }
}
