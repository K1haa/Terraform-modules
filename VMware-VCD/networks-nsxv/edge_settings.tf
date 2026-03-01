resource "vcd_edgegateway_settings" "edge" {
  count = coalesce(try(var.edge_settings.enabled, null), false) ? 1 : 0

  edge_gateway_name = var.edge_gateway_name

  fw_enabled                      = try(var.edge_settings.fw_enabled, null)
  fw_default_rule_action          = try(var.edge_settings.fw_default_rule_action, null)
  fw_default_rule_logging_enabled = try(var.edge_settings.fw_default_rule_logging_enabled, null)

  lb_enabled              = try(var.edge_settings.lb_enabled, null)
  lb_acceleration_enabled = try(var.edge_settings.lb_acceleration_enabled, null)
  lb_logging_enabled      = try(var.edge_settings.lb_logging_enabled, null)
  lb_loglevel             = try(var.edge_settings.lb_loglevel, null)
}
