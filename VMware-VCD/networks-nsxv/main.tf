locals {
  netmask_to_cidr = {
    "255.255.255.0"   = "24"
    "255.255.255.128" = "25"
    "255.255.255.192" = "26"
    "255.255.255.224" = "27"
    "255.255.255.240" = "28"
    "255.255.255.248" = "29"
    "255.255.255.252" = "30"
    "255.255.255.254" = "31"
    "255.255.255.255" = "32"
    "255.255.0.0"     = "16"
    "255.0.0.0"       = "8"
  }

  effective_enable_snat              = coalesce(try(var.module_options.enable_snat, null), true)
  effective_enable_outbound_firewall = coalesce(try(var.module_options.enable_outbound_firewall, null), true)
  effective_enable_dnat_firewall     = coalesce(try(var.module_options.enable_dnat_firewall_rules, null), true)
  effective_name_prefix              = trimspace(coalesce(try(var.module_options.name_prefix, null), ""))
  name_prefix                        = local.effective_name_prefix == "" ? "" : "${local.effective_name_prefix}-"

  effective_allowed_external_network_names = distinct([
    for name in coalesce(try(var.module_options.allowed_external_network_names, null), []) :
    lower(trimspace(name))
    if trimspace(name) != ""
  ])

  allowed_external_network_names = (
    length(local.effective_allowed_external_network_names) > 0 ?
    local.effective_allowed_external_network_names :
    [lower(trimspace(var.external_network_name))]
  )

  networks_by_name = { for net in var.networks : net.name => net }

  network_cidrs = {
    for net in var.networks : net.name =>
    format("%s/%s",
      cidrhost(
        format("%s/%s", net.gateway, local.netmask_to_cidr[net.netmask]),
        0
      ),
      local.netmask_to_cidr[net.netmask]
    )
  }

  enabled_snat_networks = {
    for name, net in local.networks_by_name : name => net
    if local.effective_enable_snat && try(net.snat_enabled, true)
  }

  enabled_snat_policies = {
    for p in var.snat_policies : lower(trimspace(p.name)) => p
    if local.effective_enable_snat && try(p.enabled, true)
  }

  expanded_dnat_rules = {
    for item in flatten([
      for idx, rule in var.dnat_rules : [
        for backend_idx, backend in(
          length(try(rule.backends, [])) > 0 ?
          [
            for b in rule.backends : {
              internal_ip   = b.internal_ip
              internal_port = coalesce(try(b.internal_port, null), try(rule.internal_port, null), rule.external_port)
              enabled       = try(b.enabled, true)
            }
          ] :
          [{
            internal_ip   = rule.internal_ip
            internal_port = coalesce(try(rule.internal_port, null), rule.external_port)
            enabled       = true
          }]
          ) : {
          key                    = "${idx}-${backend_idx}"
          rule_index             = tostring(idx)
          backend_index          = backend_idx
          rule_enabled           = try(rule.enabled, true)
          backend_enabled        = try(backend.enabled, true)
          effective_network_name = try(trimspace(rule.network_name), trimspace(var.external_network_name))
          effective_external_ip  = coalesce(try(rule.external_ip, null), var.external_ips[0])
          external_port          = rule.external_port
          protocol_normalized    = lower(trimspace(rule.protocol))
          description            = coalesce(try(rule.description, null), "DNAT rule for ${backend.internal_ip}:${backend.internal_port}")
          translated_address     = backend.internal_ip
          translated_port        = backend.internal_port
        }
      ]
    ]) : item.key => item
    if item.rule_enabled
  }

  enabled_dnat_rules = {
    for key, item in local.expanded_dnat_rules : key => item if item.backend_enabled
  }

  enabled_dnat_firewall_rules = {
    for idx, rule in var.dnat_rules : tostring(idx) => {
      effective_network_name = try(trimspace(rule.network_name), trimspace(var.external_network_name))
      effective_external_ip  = coalesce(try(rule.external_ip, null), var.external_ips[0])
      external_port          = rule.external_port
      protocol_normalized    = lower(trimspace(rule.protocol))
      source_cidrs           = coalesce(try(rule.source_cidrs, null), ["any"])
      above_rule_id          = try(rule.above_rule_id, null)
    } if try(rule.enabled, true)
  }

  outbound_service_presets = {
    web = [
      { protocol = "tcp", port = 80, source_port = "any" },
      { protocol = "tcp", port = 443, source_port = "any" }
    ]
    dns = [
      { protocol = "udp", port = 53, source_port = "any" },
      { protocol = "tcp", port = 53, source_port = "any" }
    ]
    ssh = [
      { protocol = "tcp", port = 22, source_port = "any" }
    ]
    ntp = [
      { protocol = "udp", port = 123, source_port = "any" }
    ]
    smtp = [
      { protocol = "tcp", port = 25, source_port = "any" },
      { protocol = "tcp", port = 465, source_port = "any" },
      { protocol = "tcp", port = 587, source_port = "any" }
    ]
    rdp = [
      { protocol = "tcp", port = 3389, source_port = "any" },
      { protocol = "udp", port = 3389, source_port = "any" }
    ]
    k8s-control-plane = [
      { protocol = "tcp", port = 6443, source_port = "any" },
      { protocol = "tcp", port = 2379, source_port = "any" },
      { protocol = "tcp", port = 2380, source_port = "any" },
      { protocol = "tcp", port = 10250, source_port = "any" },
      { protocol = "tcp", port = 10257, source_port = "any" },
      { protocol = "tcp", port = 10259, source_port = "any" }
    ]
    k8s-node = [
      { protocol = "tcp", port = 30000, source_port = "any" },
      { protocol = "tcp", port = 30001, source_port = "any" },
      { protocol = "tcp", port = 30002, source_port = "any" },
      { protocol = "tcp", port = 30003, source_port = "any" },
      { protocol = "tcp", port = 30004, source_port = "any" },
      { protocol = "tcp", port = 30005, source_port = "any" },
      { protocol = "tcp", port = 30006, source_port = "any" },
      { protocol = "tcp", port = 30007, source_port = "any" },
      { protocol = "tcp", port = 30008, source_port = "any" },
      { protocol = "tcp", port = 30009, source_port = "any" }
    ]
    monitoring = [
      { protocol = "tcp", port = 3000, source_port = "any" },
      { protocol = "tcp", port = 9090, source_port = "any" },
      { protocol = "tcp", port = 9093, source_port = "any" },
      { protocol = "tcp", port = 9100, source_port = "any" },
      { protocol = "tcp", port = 9121, source_port = "any" },
      { protocol = "tcp", port = 9187, source_port = "any" },
      { protocol = "udp", port = 161, source_port = "any" },
      { protocol = "udp", port = 162, source_port = "any" }
    ]
    ldap = [
      { protocol = "tcp", port = 389, source_port = "any" },
      { protocol = "udp", port = 389, source_port = "any" }
    ]
    ldaps = [
      { protocol = "tcp", port = 636, source_port = "any" }
    ]
    kerberos = [
      { protocol = "tcp", port = 88, source_port = "any" },
      { protocol = "udp", port = 88, source_port = "any" },
      { protocol = "tcp", port = 464, source_port = "any" },
      { protocol = "udp", port = 464, source_port = "any" }
    ]
    snmp = [
      { protocol = "udp", port = 161, source_port = "any" },
      { protocol = "udp", port = 162, source_port = "any" }
    ]
    syslog = [
      { protocol = "udp", port = 514, source_port = "any" },
      { protocol = "tcp", port = 514, source_port = "any" },
      { protocol = "tcp", port = 6514, source_port = "any" }
    ]
    dhcp = [
      { protocol = "udp", port = 67, source_port = "any" },
      { protocol = "udp", port = 68, source_port = "any" }
    ]
    imap = [
      { protocol = "tcp", port = 143, source_port = "any" },
      { protocol = "tcp", port = 993, source_port = "any" }
    ]
    pop3 = [
      { protocol = "tcp", port = 110, source_port = "any" },
      { protocol = "tcp", port = 995, source_port = "any" }
    ]
    nfs = [
      { protocol = "tcp", port = 111, source_port = "any" },
      { protocol = "udp", port = 111, source_port = "any" },
      { protocol = "tcp", port = 2049, source_port = "any" },
      { protocol = "udp", port = 2049, source_port = "any" }
    ]
    mysql = [
      { protocol = "tcp", port = 3306, source_port = "any" }
    ]
    postgres = [
      { protocol = "tcp", port = 5432, source_port = "any" }
    ]
    mssql = [
      { protocol = "tcp", port = 1433, source_port = "any" }
    ]
    redis = [
      { protocol = "tcp", port = 6379, source_port = "any" }
    ]
    mongodb = [
      { protocol = "tcp", port = 27017, source_port = "any" }
    ]
    rabbitmq = [
      { protocol = "tcp", port = 5672, source_port = "any" },
      { protocol = "tcp", port = 15672, source_port = "any" }
    ]
    kafka = [
      { protocol = "tcp", port = 9092, source_port = "any" },
      { protocol = "tcp", port = 9093, source_port = "any" }
    ]
    elasticsearch = [
      { protocol = "tcp", port = 9200, source_port = "any" },
      { protocol = "tcp", port = 9300, source_port = "any" }
    ]
    prometheus = [
      { protocol = "tcp", port = 9090, source_port = "any" }
    ]
    grafana = [
      { protocol = "tcp", port = 3000, source_port = "any" }
    ]
    loki = [
      { protocol = "tcp", port = 3100, source_port = "any" }
    ]
    tempo = [
      { protocol = "tcp", port = 3200, source_port = "any" }
    ]
    jaeger = [
      { protocol = "udp", port = 6831, source_port = "any" },
      { protocol = "udp", port = 6832, source_port = "any" },
      { protocol = "tcp", port = 16686, source_port = "any" }
    ]
    consul = [
      { protocol = "tcp", port = 8300, source_port = "any" },
      { protocol = "tcp", port = 8301, source_port = "any" },
      { protocol = "udp", port = 8301, source_port = "any" },
      { protocol = "tcp", port = 8500, source_port = "any" },
      { protocol = "tcp", port = 8600, source_port = "any" },
      { protocol = "udp", port = 8600, source_port = "any" }
    ]
    vault = [
      { protocol = "tcp", port = 8200, source_port = "any" },
      { protocol = "tcp", port = 8201, source_port = "any" }
    ]
    etcd = [
      { protocol = "tcp", port = 2379, source_port = "any" },
      { protocol = "tcp", port = 2380, source_port = "any" }
    ]
  }

  outbound_address_groups   = try(var.outbound_policy.address_groups, {})
  outbound_services_catalog = try(var.outbound_policy.services_catalog, {})

  outbound_destination_groups = length(try(var.outbound_policy.destination_groups, [])) > 0 ? [
    for grp in try(var.outbound_policy.destination_groups, []) : {
      name                    = trimspace(grp.name)
      priority                = try(grp.priority, 1000)
      above_rule_id           = try(grp.above_rule_id, null)
      destination_cidrs       = try(grp.destination_cidrs, ["any"])
      destination_group_names = try(grp.destination_group_names, [])
      source_cidrs            = try(grp.source_cidrs, null)
      source_group_names      = try(grp.source_group_names, [])
      service_presets         = [for p in try(grp.service_presets, []) : lower(trimspace(p))]
      service_group_names     = try(grp.service_group_names, [])
      allowed_services = [
        for svc in try(grp.allowed_services, []) : {
          protocol    = lower(trimspace(svc.protocol))
          port        = contains(["tcp", "udp"], lower(trimspace(svc.protocol))) ? svc.port : null
          source_port = try(svc.source_port, "any")
        }
      ]
    }
    ] : [{
      name                    = "default"
      priority                = 1000
      above_rule_id           = null
      destination_cidrs       = ["any"]
      destination_group_names = []
      source_cidrs            = null
      source_group_names      = []
      service_presets         = []
      service_group_names     = []
      allowed_services        = []
  }]

  outbound_destination_groups_effective = [
    for grp in local.outbound_destination_groups : merge(grp, {
      destination_cidrs_effective = distinct(concat(
        grp.destination_cidrs,
        flatten([
          for group_name in grp.destination_group_names : lookup(local.outbound_address_groups, group_name, [])
        ])
      ))
      source_group_cidrs = flatten([
        for group_name in grp.source_group_names : lookup(local.outbound_address_groups, group_name, [])
      ])
      services_catalog_resolved = flatten([
        for group_name in grp.service_group_names : lookup(local.outbound_services_catalog, group_name, [])
      ])
      services = length(concat(
        flatten([for preset in grp.service_presets : lookup(local.outbound_service_presets, preset, [])]),
        flatten([
          for group_name in grp.service_group_names : lookup(local.outbound_services_catalog, group_name, [])
        ]),
        grp.allowed_services
        )) > 0 ? concat(
        flatten([for preset in grp.service_presets : lookup(local.outbound_service_presets, preset, [])]),
        flatten([
          for group_name in grp.service_group_names : lookup(local.outbound_services_catalog, group_name, [])
        ]),
        grp.allowed_services
        ) : [{
          protocol    = "any"
          port        = null
          source_port = "any"
      }]
    })
  ]

  outbound_rules = {
    for tuple in flatten([
      for net_name, net in local.networks_by_name : [
        for grp in local.outbound_destination_groups_effective : {
          key               = "${format("%06d", grp.priority)}|${net_name}|${grp.name}"
          network_name      = net_name
          group_name        = grp.name
          priority          = grp.priority
          above_rule_id     = grp.above_rule_id
          source_cidrs      = distinct(concat(coalesce(grp.source_cidrs, [local.network_cidrs[net_name]]), grp.source_group_cidrs))
          destination_cidrs = grp.destination_cidrs_effective
          services          = grp.services
        }
      ]
    ]) : tuple.key => tuple
  }
}

resource "vcd_network_routed" "network" {
  for_each = local.networks_by_name

  name           = "${local.name_prefix}${each.value.name}"
  edge_gateway   = var.edge_gateway_name
  gateway        = each.value.gateway
  netmask        = each.value.netmask
  interface_type = var.interface_type
  dns1           = each.value.dns1
  dns2           = each.value.dns2
  dns_suffix     = try(each.value.dns_suffix, null)

  static_ip_pool {
    start_address = each.value.static_start
    end_address   = each.value.static_end
  }

  dynamic "dhcp_pool" {
    for_each = (try(each.value.dhcp_start, null) != null && try(each.value.dhcp_end, null) != null) ? [1] : []
    content {
      start_address = each.value.dhcp_start
      end_address   = each.value.dhcp_end
    }
  }

  lifecycle {
    precondition {
      condition = cidrcontains(
        format(
          "%s/%s",
          cidrhost(format("%s/%s", each.value.gateway, local.netmask_to_cidr[each.value.netmask]), 0),
          local.netmask_to_cidr[each.value.netmask]
        ),
        each.value.gateway
      )
      error_message = "Gateway должен принадлежать подсети сети"
    }

    precondition {
      condition = cidrcontains(
        format(
          "%s/%s",
          cidrhost(format("%s/%s", each.value.gateway, local.netmask_to_cidr[each.value.netmask]), 0),
          local.netmask_to_cidr[each.value.netmask]
        ),
        each.value.static_start
        ) && cidrcontains(
        format(
          "%s/%s",
          cidrhost(format("%s/%s", each.value.gateway, local.netmask_to_cidr[each.value.netmask]), 0),
          local.netmask_to_cidr[each.value.netmask]
        ),
        each.value.static_end
      )
      error_message = "static_start/static_end должны принадлежать подсети сети"
    }

    precondition {
      condition = try(each.value.dhcp_start, null) == null || (
        cidrcontains(
          format(
            "%s/%s",
            cidrhost(format("%s/%s", each.value.gateway, local.netmask_to_cidr[each.value.netmask]), 0),
            local.netmask_to_cidr[each.value.netmask]
          ),
          each.value.dhcp_start
          ) && cidrcontains(
          format(
            "%s/%s",
            cidrhost(format("%s/%s", each.value.gateway, local.netmask_to_cidr[each.value.netmask]), 0),
            local.netmask_to_cidr[each.value.netmask]
          ),
          each.value.dhcp_end
        )
      )
      error_message = "dhcp_start/dhcp_end должны принадлежать подсети сети"
    }
  }
}

resource "vcd_nsxv_snat" "auto_snat" {
  for_each = local.enabled_snat_networks

  edge_gateway       = var.edge_gateway_name
  network_name       = var.external_network_name
  network_type       = var.external_network_type
  original_address   = local.network_cidrs[each.value.name]
  translated_address = coalesce(try(each.value.snat_external_ip, null), var.external_ips[0])
  depends_on         = [vcd_network_routed.network]
}

resource "vcd_nsxv_snat" "segment_snat" {
  for_each = local.enabled_snat_policies

  edge_gateway       = var.edge_gateway_name
  network_name       = var.external_network_name
  network_type       = var.external_network_type
  original_address   = each.value.source_cidr
  translated_address = each.value.external_ip
  depends_on         = [vcd_network_routed.network]
}

resource "vcd_nsxv_dnat" "port_forwarding" {
  for_each = local.expanded_dnat_rules

  edge_gateway = var.edge_gateway_name
  network_name = each.value.effective_network_name
  network_type = var.external_network_type
  enabled      = each.value.backend_enabled
  description  = each.value.description

  original_address   = each.value.effective_external_ip
  original_port      = each.value.external_port
  translated_address = each.value.translated_address
  translated_port    = each.value.translated_port
  protocol           = each.value.protocol_normalized
  depends_on         = [vcd_network_routed.network]

  lifecycle {
    precondition {
      condition = anytrue([
        for cidr in values(local.network_cidrs) : cidrcontains(cidr, each.value.translated_address)
      ])
      error_message = "DNAT translated_address должен принадлежать одной из подсетей, заданных в networks"
    }

    precondition {
      condition = contains(
        local.allowed_external_network_names,
        lower(each.value.effective_network_name)
      )
      error_message = "DNAT network_name не входит в module_options.allowed_external_network_names"
    }
  }
}

resource "vcd_nsxv_firewall_rule" "outbound_internet" {
  for_each = local.effective_enable_outbound_firewall ? local.outbound_rules : {}

  edge_gateway  = var.edge_gateway_name
  name          = "Outbound-${each.value.network_name}-${each.value.group_name}"
  action        = "accept"
  enabled       = true
  above_rule_id = each.value.above_rule_id

  source {
    ip_addresses = each.value.source_cidrs
  }

  destination {
    ip_addresses = each.value.destination_cidrs
  }

  dynamic "service" {
    for_each = each.value.services
    content {
      protocol    = service.value.protocol
      port        = service.value.port
      source_port = service.value.source_port
    }
  }

  depends_on = [vcd_network_routed.network]
}

resource "vcd_nsxv_firewall_rule" "dnat_auto_allow" {
  for_each = local.effective_enable_dnat_firewall ? local.enabled_dnat_firewall_rules : {}

  edge_gateway  = var.edge_gateway_name
  name          = "Allow-${each.value.effective_network_name}-${each.value.effective_external_ip}:${each.value.external_port}-${each.value.protocol_normalized}"
  action        = "accept"
  enabled       = true
  above_rule_id = each.value.above_rule_id

  source {
    ip_addresses = each.value.source_cidrs
  }

  destination {
    ip_addresses = [each.value.effective_external_ip]
  }

  service {
    protocol    = each.value.protocol_normalized
    port        = each.value.external_port
    source_port = "any"
  }

  depends_on = [vcd_nsxv_dnat.port_forwarding]
}
