locals {
  lb_app_rules = {
    for r in try(var.load_balancer.app_rules, []) : r.name => r
    if coalesce(try(var.load_balancer.enabled, null), false)
  }

  lb_app_profiles = {
    for p in try(var.load_balancer.app_profiles, []) : p.name => p
    if coalesce(try(var.load_balancer.enabled, null), false)
  }

  lb_service_monitors = {
    for m in try(var.load_balancer.service_monitors, []) : m.name => m
    if coalesce(try(var.load_balancer.enabled, null), false)
  }

  lb_server_pools = {
    for p in try(var.load_balancer.server_pools, []) : p.name => p
    if coalesce(try(var.load_balancer.enabled, null), false)
  }

  lb_virtual_servers = {
    for v in try(var.load_balancer.virtual_servers, []) : v.name => v
    if coalesce(try(var.load_balancer.enabled, null), false)
  }

  vpn_ipsec_tunnels = {
    for t in try(var.vpn.ipsec_tunnels, []) : t.name => t
    if coalesce(try(var.vpn.enabled, null), false)
  }

  dhcp_relay_enabled = coalesce(try(var.dhcp.relay_enabled, null), false)

  routing_manifest = {
    distributed_routing   = try(var.routing.distributed_routing, null)
    static_routes         = try(var.routing.static_routes, [])
    supported_by_provider = false
  }
}
