output "network_ids" {
  description = "ID созданных routed сетей по исходному имени из networks[*].name"
  value       = { for name, net in vcd_network_routed.network : name => net.id }
}

output "network_actual_names" {
  description = "Фактические имена созданных routed сетей (с учетом name_prefix)"
  value       = { for name, net in vcd_network_routed.network : name => net.name }
}

output "network_cidrs" {
  description = "Вычисленные CIDR для routed сетей"
  value       = local.network_cidrs
}

output "snat_rule_ids" {
  description = "ID SNAT правил по имени routed сети"
  value       = { for name, rule in vcd_nsxv_snat.auto_snat : name => rule.id }
}

output "snat_segment_rule_ids" {
  description = "ID SNAT segment-политик по имени policy"
  value       = { for name, rule in vcd_nsxv_snat.segment_snat : name => rule.id }
}

output "dnat_rule_ids" {
  description = "ID созданных DNAT правил по ключу ruleIndex-backendIndex"
  value       = { for key, rule in vcd_nsxv_dnat.port_forwarding : key => rule.id }
}

output "dnat_rule_ids_by_network_external_ip_protocol_port" {
  description = "ID DNAT по ключу: network_name -> external_ip -> protocol_port (list, если несколько backend)"
  value = {
    for network_name in distinct([
      for key, rule in local.expanded_dnat_rules : lower(rule.effective_network_name)
    ]) :
    network_name => {
      for external_ip in distinct([
        for key, rule in local.expanded_dnat_rules : rule.effective_external_ip
        if lower(rule.effective_network_name) == network_name
      ]) :
      external_ip => {
        for proto_port in distinct([
          for key, rule in local.expanded_dnat_rules :
          format("%s_%d", rule.protocol_normalized, rule.external_port)
          if lower(rule.effective_network_name) == network_name && rule.effective_external_ip == external_ip
        ]) :
        proto_port => [
          for key, rule in local.expanded_dnat_rules :
          vcd_nsxv_dnat.port_forwarding[key].id
          if lower(rule.effective_network_name) == network_name &&
          rule.effective_external_ip == external_ip &&
          format("%s_%d", rule.protocol_normalized, rule.external_port) == proto_port
        ]
      }
    }
  }
}

output "outbound_firewall_rule_ids" {
  description = "ID outbound firewall правил по ключу priority|network|group"
  value       = { for name, rule in vcd_nsxv_firewall_rule.outbound_internet : name => rule.id }
}

output "outbound_firewall_rule_ids_by_network_group" {
  description = "ID outbound firewall правил по ключу network_name -> group_name"
  value = {
    for network_name in distinct([
      for key, item in local.outbound_rules : item.network_name
    ]) :
    network_name => {
      for key, item in local.outbound_rules :
      item.group_name => vcd_nsxv_firewall_rule.outbound_internet[key].id
      if item.network_name == network_name
    }
  }
}

output "dnat_firewall_rule_ids" {
  description = "ID auto-allow firewall правил по индексу DNAT правила"
  value       = { for key, rule in vcd_nsxv_firewall_rule.dnat_auto_allow : key => rule.id }
}

output "dhcp_relay_id" {
  description = "ID DHCP relay конфигурации"
  value       = try(vcd_nsxv_dhcp_relay.relay[0].id, null)
}

output "edge_settings_id" {
  description = "ID edge settings конфигурации"
  value       = try(vcd_edgegateway_settings.edge[0].id, null)
}

output "lb_app_rule_ids" {
  description = "ID LB app rules по имени"
  value       = { for name, item in vcd_lb_app_rule.this : name => item.id }
}

output "lb_app_profile_ids" {
  description = "ID LB app profiles по имени"
  value       = { for name, item in vcd_lb_app_profile.this : name => item.id }
}

output "lb_service_monitor_ids" {
  description = "ID LB service monitors по имени"
  value       = { for name, item in vcd_lb_service_monitor.this : name => item.id }
}

output "lb_server_pool_ids" {
  description = "ID LB server pools по имени"
  value       = { for name, item in vcd_lb_server_pool.this : name => item.id }
}

output "lb_virtual_server_ids" {
  description = "ID LB virtual servers по имени"
  value       = { for name, item in vcd_lb_virtual_server.this : name => item.id }
}

output "vpn_ipsec_ids" {
  description = "ID VPN IPsec туннелей по имени"
  value       = { for name, item in vcd_edgegateway_vpn.ipsec : name => item.id }
}

output "routing_manifest" {
  description = "Manifest routing блока (provider NSX-V routing resources limited)"
  value       = local.routing_manifest
}

output "effective_manifest" {
  description = "Сводный manifest эффективной конфигурации"
  value = {
    network = {
      ids   = { for name, net in vcd_network_routed.network : name => net.id }
      cidrs = local.network_cidrs
    }
    nat = {
      snat_per_network = { for name, rule in vcd_nsxv_snat.auto_snat : name => rule.id }
      snat_segment     = { for name, rule in vcd_nsxv_snat.segment_snat : name => rule.id }
      dnat             = { for key, rule in vcd_nsxv_dnat.port_forwarding : key => rule.id }
    }
    firewall = {
      outbound        = { for name, rule in vcd_nsxv_firewall_rule.outbound_internet : name => rule.id }
      dnat_auto_allow = { for key, rule in vcd_nsxv_firewall_rule.dnat_auto_allow : key => rule.id }
    }
    dhcp = {
      relay_id = try(vcd_nsxv_dhcp_relay.relay[0].id, null)
    }
    lb = {
      app_rules        = { for name, item in vcd_lb_app_rule.this : name => item.id }
      app_profiles     = { for name, item in vcd_lb_app_profile.this : name => item.id }
      service_monitors = { for name, item in vcd_lb_service_monitor.this : name => item.id }
      server_pools     = { for name, item in vcd_lb_server_pool.this : name => item.id }
      virtual_servers  = { for name, item in vcd_lb_virtual_server.this : name => item.id }
    }
    vpn = {
      ipsec = { for name, item in vcd_edgegateway_vpn.ipsec : name => item.id }
    }
    routing = local.routing_manifest
  }
}
