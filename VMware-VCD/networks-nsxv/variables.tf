variable "edge_gateway_name" {
  description = "Имя Edge Gateway"
  type        = string
}

variable "external_network_name" {
  description = "Имя внешней сети Edge Gateway для NAT"
  type        = string
  default     = "ClientsExternalNetwork"
  validation {
    condition     = trimspace(var.external_network_name) != ""
    error_message = "external_network_name не может быть пустым"
  }
}

variable "external_network_type" {
  description = "Тип внешней сети для NAT (обычно ext)"
  type        = string
  default     = "ext"
  validation {
    condition     = contains(["ext"], var.external_network_type)
    error_message = "Поддерживается только тип внешней сети: ext"
  }
}

variable "external_ips" {
  description = "Список внешних IP для NAT. Первый IP используется по умолчанию для SNAT/DNAT"
  type        = list(string)
  validation {
    condition = length(var.external_ips) > 0 && alltrue([
      for ip in var.external_ips : can(cidrhost("${ip}/32", 0))
    ])
    error_message = "external_ips должен содержать хотя бы один валидный IP-адрес"
  }
}

variable "interface_type" {
  description = "Режим подключения к Edge (internal/subinterface/distributed)"
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["internal", "subinterface", "distributed"], var.interface_type)
    error_message = "Допустимы: internal/subinterface/distributed"
  }
}

variable "networks" {
  description = "Список routed сетей с параметрами"
  type = list(object({
    name             = string
    gateway          = string
    netmask          = string
    static_start     = string
    static_end       = string
    dns1             = string
    dns2             = string
    dns_suffix       = optional(string)
    dhcp_start       = optional(string)
    dhcp_end         = optional(string)
    snat_enabled     = optional(bool, true)
    snat_external_ip = optional(string)
  }))
  validation {
    condition = length(var.networks) == length(distinct([
      for net in var.networks : net.name
    ]))
    error_message = "Имена сетей должны быть уникальными"
  }
  validation {
    condition = alltrue([
      for net in var.networks :
      contains([
        "255.255.255.0",
        "255.255.255.128",
        "255.255.255.192",
        "255.255.255.224",
        "255.255.255.240",
        "255.255.255.248",
        "255.255.255.252",
        "255.255.255.254",
        "255.255.255.255",
        "255.255.0.0",
        "255.0.0.0"
      ], net.netmask)
    ])
    error_message = "Поддерживаемые netmask: /8, /16, /24-/32 (в формате 255.x.x.x)"
  }
  validation {
    condition = alltrue([
      for net in var.networks :
      can(cidrhost("${net.gateway}/32", 0)) &&
      can(cidrhost("${net.static_start}/32", 0)) &&
      can(cidrhost("${net.static_end}/32", 0)) &&
      (
        (try(net.dhcp_start, null) == null && try(net.dhcp_end, null) == null) ||
        (
          try(net.dhcp_start, null) != null &&
          try(net.dhcp_end, null) != null &&
          can(cidrhost("${net.dhcp_start}/32", 0)) &&
          can(cidrhost("${net.dhcp_end}/32", 0))
        )
      ) &&
      (try(net.snat_external_ip, null) == null || can(cidrhost("${net.snat_external_ip}/32", 0)))
    ])
    error_message = "Для networks: IP должны быть валидны, dhcp_start/dhcp_end указываются парой, snat_external_ip должен быть валидным IP"
  }
  validation {
    condition = alltrue([
      for net in var.networks :
      sum([for idx, octet in split(".", net.static_start) : tonumber(octet) * pow(256, 3 - idx)]) <=
      sum([for idx, octet in split(".", net.static_end) : tonumber(octet) * pow(256, 3 - idx)])
    ])
    error_message = "Для networks: static_start должен быть меньше или равен static_end"
  }
  validation {
    condition = alltrue([
      for net in var.networks :
      (
        try(net.dhcp_start, null) == null ||
        sum([for idx, octet in split(".", net.dhcp_start) : tonumber(octet) * pow(256, 3 - idx)]) <=
        sum([for idx, octet in split(".", net.dhcp_end) : tonumber(octet) * pow(256, 3 - idx)])
      )
    ])
    error_message = "Для networks: dhcp_start должен быть меньше или равен dhcp_end"
  }
  validation {
    condition = alltrue([
      for net in var.networks :
      try(net.snat_external_ip == null || contains(var.external_ips, net.snat_external_ip), true)
    ])
    error_message = "Для networks: snat_external_ip (если задан) должен входить в external_ips"
  }
}

variable "snat_policies" {
  description = "Дополнительные SNAT политики по source CIDR"
  type = list(object({
    name        = string
    source_cidr = string
    external_ip = string
    enabled     = optional(bool, true)
  }))
  default = []
  validation {
    condition = length(var.snat_policies) == length(distinct([
      for p in var.snat_policies : lower(trimspace(p.name))
    ]))
    error_message = "snat_policies: имена должны быть уникальными"
  }
  validation {
    condition = alltrue([
      for p in var.snat_policies :
      trimspace(p.name) != "" &&
      can(cidrhost(p.source_cidr, 0)) &&
      contains(var.external_ips, p.external_ip)
    ])
    error_message = "snat_policies: проверь name, source_cidr и external_ip (должен входить в external_ips)"
  }
}

variable "dnat_rules" {
  description = "DNAT правила: single target или пул backend-целей"
  type = list(object({
    network_name      = optional(string)
    external_ip       = optional(string)
    external_port     = number
    protocol          = string
    enabled           = optional(bool, true)
    description       = optional(string)
    source_cidrs      = optional(list(string))
    above_rule_id     = optional(string)
    internal_ip       = optional(string)
    internal_port     = optional(number)
    distribution_mode = optional(string, "active_standby")
    backends = optional(list(object({
      internal_ip   = string
      internal_port = optional(number)
      enabled       = optional(bool, true)
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.dnat_rules :
      contains(["tcp", "udp"], lower(trimspace(r.protocol))) &&
      r.external_port >= 1 &&
      r.external_port <= 65535 &&
      try(
        r.external_ip == null ||
        (can(cidrhost("${r.external_ip}/32", 0)) && contains(var.external_ips, r.external_ip)),
        true
      ) &&
      try(r.network_name == null || trimspace(r.network_name) != "", true) &&
      contains(["active_standby"], lower(trimspace(try(r.distribution_mode, "active_standby")))) &&
      (
        (
          try(r.internal_ip, null) != null &&
          can(cidrhost("${r.internal_ip}/32", 0)) &&
          coalesce(try(r.internal_port, null), r.external_port) >= 1 &&
          coalesce(try(r.internal_port, null), r.external_port) <= 65535
        ) ||
        length(try(r.backends, [])) > 0
      ) &&
      alltrue([
        for b in try(r.backends, []) :
        can(cidrhost("${b.internal_ip}/32", 0)) &&
        coalesce(try(b.internal_port, null), r.external_port) >= 1 &&
        coalesce(try(b.internal_port, null), r.external_port) <= 65535
      ]) &&
      alltrue([
        for cidr in coalesce(try(r.source_cidrs, null), ["any"]) :
        lower(trimspace(cidr)) == "any" || can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "DNAT: проверь protocol/ports, external_ip, target(backends или internal_*), source_cidrs и distribution_mode(active_standby)"
  }
}

variable "module_options" {
  description = "Опциональные настройки модуля"
  type = object({
    enable_snat                    = optional(bool)
    enable_outbound_firewall       = optional(bool)
    enable_dnat_firewall_rules     = optional(bool)
    name_prefix                    = optional(string)
    allowed_external_network_names = optional(list(string))
  })
  default = {}

  validation {
    condition = alltrue([
      for name in try(var.module_options.allowed_external_network_names, []) : trimspace(name) != ""
    ])
    error_message = "module_options.allowed_external_network_names не должен содержать пустые значения"
  }
}

variable "outbound_policy" {
  description = "Расширенная outbound policy с address groups, service catalog и destination groups"
  type = object({
    address_groups = optional(map(list(string)), {})
    services_catalog = optional(map(list(object({
      protocol    = string
      port        = optional(number)
      source_port = optional(string, "any")
    }))), {})
    destination_groups = optional(list(object({
      name                    = string
      priority                = optional(number)
      above_rule_id           = optional(string)
      destination_cidrs       = optional(list(string), ["any"])
      destination_group_names = optional(list(string), [])
      source_cidrs            = optional(list(string))
      source_group_names      = optional(list(string), [])
      service_presets         = optional(list(string), [])
      service_group_names     = optional(list(string), [])
      allowed_services = optional(list(object({
        protocol    = string
        port        = optional(number)
        source_port = optional(string, "any")
      })), [])
    })), [])
  })
  default = {}

  validation {
    condition = alltrue(flatten([
      for name, cidrs in try(var.outbound_policy.address_groups, {}) : [
        for cidr in cidrs : lower(trimspace(cidr)) == "any" || can(cidrhost(cidr, 0))
      ]
    ]))
    error_message = "outbound_policy.address_groups: допустимы только CIDR или any"
  }

  validation {
    condition = alltrue(flatten([
      for name, services in try(var.outbound_policy.services_catalog, {}) : [
        for svc in services :
        contains(["any", "tcp", "udp", "icmp"], lower(trimspace(svc.protocol))) &&
        (
          !contains(["tcp", "udp"], lower(trimspace(svc.protocol))) ||
          (try(svc.port, null) != null && svc.port >= 1 && svc.port <= 65535)
        )
      ]
    ]))
    error_message = "outbound_policy.services_catalog: protocol any/tcp/udp/icmp; для tcp/udp обязателен port 1..65535"
  }

  validation {
    condition = length(try(var.outbound_policy.destination_groups, [])) == length(distinct([
      for grp in try(var.outbound_policy.destination_groups, []) : lower(trimspace(grp.name))
    ]))
    error_message = "outbound_policy.destination_groups: имена групп должны быть уникальными"
  }

  validation {
    condition = alltrue([
      for grp in try(var.outbound_policy.destination_groups, []) :
      trimspace(grp.name) != "" &&
      alltrue([
        for cidr in try(grp.destination_cidrs, ["any"]) :
        lower(trimspace(cidr)) == "any" || can(cidrhost(cidr, 0))
      ]) &&
      alltrue([
        for cidr in coalesce(try(grp.source_cidrs, null), ["any"]) :
        lower(trimspace(cidr)) == "any" || can(cidrhost(cidr, 0))
      ]) &&
      alltrue([
        for preset in try(grp.service_presets, []) :
        contains([
          "web", "dns", "ssh", "ntp", "smtp", "rdp",
          "k8s-control-plane", "k8s-node", "monitoring",
          "ldap", "ldaps", "kerberos", "snmp", "syslog", "dhcp",
          "imap", "pop3", "nfs", "mysql", "postgres", "mssql",
          "redis", "mongodb", "rabbitmq", "kafka", "elasticsearch",
          "prometheus", "grafana", "loki", "tempo", "jaeger",
          "consul", "vault", "etcd"
        ], lower(trimspace(preset)))
      ]) &&
      alltrue([
        for svc in try(grp.allowed_services, []) :
        contains(["any", "tcp", "udp", "icmp"], lower(trimspace(svc.protocol))) &&
        (
          !contains(["tcp", "udp"], lower(trimspace(svc.protocol))) ||
          (try(svc.port, null) != null && svc.port >= 1 && svc.port <= 65535)
        )
      ]) &&
      alltrue([
        for g in try(grp.destination_group_names, []) :
        contains(keys(try(var.outbound_policy.address_groups, {})), g)
      ]) &&
      alltrue([
        for g in try(grp.source_group_names, []) :
        contains(keys(try(var.outbound_policy.address_groups, {})), g)
      ]) &&
      alltrue([
        for g in try(grp.service_group_names, []) :
        contains(keys(try(var.outbound_policy.services_catalog, {})), g)
      ])
    ])
    error_message = "outbound_policy.destination_groups: проверь CIDR, presets, services и ссылки на address/service группы"
  }
}

variable "dhcp" {
  description = "Настройки DHCP для NSX-V (relay)"
  type = object({
    relay_enabled = optional(bool, false)
    ip_addresses  = optional(list(string), [])
    ip_sets       = optional(list(string), [])
    domain_names  = optional(list(string), [])
    relay_agents = optional(list(object({
      network_name       = string
      gateway_ip_address = string
    })), [])
  })
  default = {}

  validation {
    condition = alltrue([
      for ip in try(var.dhcp.ip_addresses, []) : can(cidrhost("${ip}/32", 0))
      ]) && alltrue([
      for ra in try(var.dhcp.relay_agents, []) :
      trimspace(ra.network_name) != "" && can(cidrhost("${ra.gateway_ip_address}/32", 0))
    ])
    error_message = "dhcp: ip_addresses и relay_agents.gateway_ip_address должны быть валидными IP, network_name не пустой"
  }
}

variable "routing" {
  description = "Routing параметры NSX-V (provider ограничен, static routes не поддерживаются напрямую)"
  type = object({
    distributed_routing = optional(bool)
    static_routes = optional(list(object({
      name         = string
      network_cidr = string
      next_hop     = string
    })), [])
  })
  default = {}

  validation {
    condition = alltrue([
      for r in try(var.routing.static_routes, []) :
      can(cidrhost(r.network_cidr, 0)) && can(cidrhost("${r.next_hop}/32", 0))
    ])
    error_message = "routing.static_routes: network_cidr и next_hop должны быть валидными"
  }
}

variable "edge_settings" {
  description = "Глобальные настройки Edge Gateway (firewall/lb)"
  type = object({
    enabled                         = optional(bool, false)
    fw_enabled                      = optional(bool)
    fw_default_rule_action          = optional(string)
    fw_default_rule_logging_enabled = optional(bool)
    lb_enabled                      = optional(bool)
    lb_acceleration_enabled         = optional(bool)
    lb_logging_enabled              = optional(bool)
    lb_loglevel                     = optional(string)
  })
  default = {}
}

variable "load_balancer" {
  description = "Полная конфигурация NSX-V Load Balancer"
  type = object({
    enabled = optional(bool, false)
    app_rules = optional(list(object({
      name   = string
      script = string
    })), [])
    app_profiles = optional(list(object({
      name                           = string
      type                           = string
      persistence_mechanism          = optional(string)
      cookie_name                    = optional(string)
      cookie_mode                    = optional(string)
      expiration                     = optional(number)
      insert_x_forwarded_http_header = optional(bool)
      enable_ssl_passthrough         = optional(bool)
      enable_pool_side_ssl           = optional(bool)
      http_redirect_url              = optional(string)
    })), [])
    service_monitors = optional(list(object({
      name        = string
      type        = string
      interval    = optional(number)
      timeout     = optional(number)
      max_retries = optional(number)
      method      = optional(string)
      url         = optional(string)
      send        = optional(string)
      receive     = optional(string)
      expected    = optional(string)
      extension   = optional(map(string), {})
    })), [])
    server_pools = optional(list(object({
      name                 = string
      description          = optional(string)
      algorithm            = optional(string)
      algorithm_parameters = optional(string)
      enable_transparency  = optional(bool)
      monitor_name         = optional(string)
      members = list(object({
        name            = string
        ip_address      = string
        port            = number
        condition       = optional(string)
        monitor_port    = optional(number)
        weight          = optional(number)
        min_connections = optional(number)
        max_connections = optional(number)
      }))
    })), [])
    virtual_servers = optional(list(object({
      name                  = string
      ip_address            = string
      protocol              = string
      port                  = number
      app_profile_name      = optional(string)
      server_pool_name      = optional(string)
      app_rule_names        = optional(list(string), [])
      description           = optional(string)
      enabled               = optional(bool)
      connection_limit      = optional(number)
      connection_rate_limit = optional(number)
      enable_acceleration   = optional(bool)
    })), [])
  })
  default = {}

  validation {
    condition = alltrue([
      for p in try(var.load_balancer.app_profiles, []) :
      contains(["tcp", "udp", "http", "https"], lower(trimspace(p.type)))
      ]) && alltrue([
      for m in try(var.load_balancer.service_monitors, []) :
      contains(["tcp", "http", "https", "udp", "icmp"], lower(trimspace(m.type)))
      ]) && alltrue([
      for p in try(var.load_balancer.server_pools, []) :
      alltrue([
        for mem in p.members :
        can(cidrhost("${mem.ip_address}/32", 0)) && mem.port >= 1 && mem.port <= 65535
      ])
      ]) && alltrue([
      for vs in try(var.load_balancer.virtual_servers, []) :
      can(cidrhost("${vs.ip_address}/32", 0)) &&
      contains(["tcp", "udp", "http", "https"], lower(trimspace(vs.protocol))) &&
      vs.port >= 1 && vs.port <= 65535
    ])
    error_message = "load_balancer: проверь типы, IP адреса и диапазоны портов"
  }
}

variable "vpn" {
  description = "VPN конфигурация NSX-V (IPsec поддерживается, L2 VPN недоступен в provider)"
  type = object({
    enabled = optional(bool, false)
    ipsec_tunnels = optional(list(object({
      name                = string
      description         = optional(string)
      encryption_protocol = string
      mtu                 = optional(number)
      peer_id             = string
      peer_ip_address     = string
      local_id            = string
      local_ip_address    = string
      shared_secret       = string
      peer_subnets = optional(list(object({
        name    = string
        gateway = string
        mask    = string
      })), [])
      local_subnets = optional(list(object({
        name    = string
        gateway = string
        mask    = string
      })), [])
    })), [])
    l2_vpn = optional(list(object({
      name = string
    })), [])
  })
  default = {}

  validation {
    condition = alltrue([
      for t in try(var.vpn.ipsec_tunnels, []) :
      can(cidrhost("${t.peer_ip_address}/32", 0)) &&
      can(cidrhost("${t.local_ip_address}/32", 0)) &&
      trimspace(t.shared_secret) != "" &&
      alltrue([
        for s in try(t.peer_subnets, []) :
        can(cidrhost("${s.gateway}/32", 0))
      ]) &&
      alltrue([
        for s in try(t.local_subnets, []) :
        can(cidrhost("${s.gateway}/32", 0))
      ])
    ]) && length(try(var.vpn.l2_vpn, [])) == 0
    error_message = "vpn: проверь ipsec параметры; l2_vpn для NSX-V provider недоступен"
  }
}
