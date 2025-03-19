resource "vcd_network_routed" "network" {
  for_each = { for net in var.networks : net.name => net }

  name           = each.value.name
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
}

locals {
  # Преобразование netmask в CIDR-префикс
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



  # Вычисление CIDR сети в формате "X.X.X.X/YY"
  network_cidrs = {
    for net in var.networks : net.name =>
    format("%s/%s",
      cidrhost(
        format("%s/%s", net.gateway, lookup(local.netmask_to_cidr, net.netmask, "24")),
        0
      ),
      lookup(local.netmask_to_cidr, net.netmask, "24")
    )
  }
}

resource "vcd_nsxv_snat" "auto_snat" {
  for_each = { for net in var.networks : net.name => net }

  edge_gateway       = var.edge_gateway_name
  network_name       = "ClientsExternalNetwork"
  network_type       = "ext"
  original_address   = local.network_cidrs[each.value.name] # Используем вычисленный CIDR
  translated_address = var.external_ip
  depends_on         = [vcd_network_routed.network]
}

resource "vcd_nsxv_dnat" "port_forwarding" {
  for_each = { for idx, rule in var.dnat_rules : idx => rule }

  edge_gateway = var.edge_gateway_name
  network_name = "ClientsExternalNetwork"
  network_type = "ext"
  enabled      = true
  description  = "DNAT rule for ${each.value.internal_ip}:${each.value.internal_port}"

  original_address   = var.external_ip
  original_port      = each.value.external_port
  translated_address = each.value.internal_ip
  translated_port    = each.value.internal_port
  protocol           = lower(each.value.protocol) # Протокол в нижнем регистре
  depends_on         = [vcd_network_routed.network, vcd_nsxv_snat.auto_snat]
}

resource "vcd_nsxv_firewall_rule" "outbound_internet" {
  for_each = { for net in var.networks : net.name => net }

  edge_gateway = var.edge_gateway_name
  name         = "Outbound-${each.value.name}"
  action       = "accept"
  enabled      = var.enable_outbound_firewall

  # Источник: внутренняя сеть
  source {
    ip_addresses = [local.network_cidrs[each.value.name]]
  }

  # Назначение: любой адрес
  destination {
    ip_addresses = ["any"]
  }

  # Протоколы и порты (разрешаем всё)
  service {
    protocol = "any"
  }

  depends_on = [vcd_network_routed.network, vcd_nsxv_snat.auto_snat, vcd_nsxv_dnat.port_forwarding]
}

resource "vcd_nsxv_firewall_rule" "dnat_auto_allow" {
  for_each = { for idx, rule in var.dnat_rules : idx => rule }

  edge_gateway = var.edge_gateway_name
  name         = "Allow-${var.external_ip}:${each.value.external_port}-${each.value.protocol}"
  action       = "accept"
  enabled      = true

  # Источник: любой IP
  source {
    ip_addresses = ["any"]
  }

  # Назначение: внешний IP и порт из DNAT
  destination {
    ip_addresses = [var.external_ip]
  }

  # Протокол из DNAT
  service {
    protocol    = upper(each.value.protocol)
    port        = each.value.external_port
    source_port = "any"
  }

  depends_on = [vcd_nsxv_dnat.port_forwarding]
}
