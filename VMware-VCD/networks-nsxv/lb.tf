resource "vcd_lb_app_rule" "this" {
  for_each = local.lb_app_rules

  edge_gateway = var.edge_gateway_name
  name         = each.value.name
  script       = each.value.script
}

resource "vcd_lb_app_profile" "this" {
  for_each = local.lb_app_profiles

  edge_gateway                   = var.edge_gateway_name
  name                           = each.value.name
  type                           = lower(each.value.type)
  persistence_mechanism          = try(each.value.persistence_mechanism, null)
  cookie_name                    = try(each.value.cookie_name, null)
  cookie_mode                    = try(each.value.cookie_mode, null)
  expiration                     = try(each.value.expiration, null)
  insert_x_forwarded_http_header = try(each.value.insert_x_forwarded_http_header, null)
  enable_ssl_passthrough         = try(each.value.enable_ssl_passthrough, null)
  enable_pool_side_ssl           = try(each.value.enable_pool_side_ssl, null)
  http_redirect_url              = try(each.value.http_redirect_url, null)
}

resource "vcd_lb_service_monitor" "this" {
  for_each = local.lb_service_monitors

  edge_gateway = var.edge_gateway_name
  name         = each.value.name
  type         = lower(each.value.type)
  interval     = tostring(coalesce(try(each.value.interval, null), 5))
  timeout      = tostring(coalesce(try(each.value.timeout, null), 20))
  max_retries  = tostring(coalesce(try(each.value.max_retries, null), 3))
  method       = try(each.value.method, null)
  url          = try(each.value.url, null)
  send         = try(each.value.send, null)
  receive      = try(each.value.receive, null)
  expected     = try(each.value.expected, null)
  extension    = try(each.value.extension, null)
}

resource "vcd_lb_server_pool" "this" {
  for_each = local.lb_server_pools

  edge_gateway         = var.edge_gateway_name
  name                 = each.value.name
  description          = try(each.value.description, null)
  algorithm            = try(each.value.algorithm, null)
  algorithm_parameters = try(each.value.algorithm_parameters, null)
  enable_transparency  = try(each.value.enable_transparency, null)
  monitor_id           = try(vcd_lb_service_monitor.this[each.value.monitor_name].id, null)

  dynamic "member" {
    for_each = each.value.members
    content {
      name            = member.value.name
      ip_address      = member.value.ip_address
      port            = member.value.port
      condition       = try(member.value.condition, null)
      monitor_port    = try(member.value.monitor_port, null)
      weight          = try(member.value.weight, null)
      min_connections = try(member.value.min_connections, null)
      max_connections = try(member.value.max_connections, null)
    }
  }
}

resource "vcd_lb_virtual_server" "this" {
  for_each = local.lb_virtual_servers

  edge_gateway   = var.edge_gateway_name
  name           = each.value.name
  ip_address     = each.value.ip_address
  protocol       = lower(each.value.protocol)
  port           = each.value.port
  app_profile_id = try(vcd_lb_app_profile.this[each.value.app_profile_name].id, null)
  server_pool_id = try(vcd_lb_server_pool.this[each.value.server_pool_name].id, null)
  app_rule_ids = [
    for app_rule_name in try(each.value.app_rule_names, []) :
    vcd_lb_app_rule.this[app_rule_name].id
    if try(vcd_lb_app_rule.this[app_rule_name].id, null) != null
  ]
  description           = try(each.value.description, null)
  enabled               = coalesce(try(each.value.enabled, null), true)
  connection_limit      = try(each.value.connection_limit, null)
  connection_rate_limit = try(each.value.connection_rate_limit, null)
  enable_acceleration   = try(each.value.enable_acceleration, null)
}
