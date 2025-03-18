variable "edge_gateway_name" {
  description = "Имя Edge Gateway"
  type        = string
}

variable "external_ip" {
  description = "Общий белый IP для всех NAT правил"
  type        = string
  validation {
    condition     = can(cidrhost("${var.external_ip}/32", 0))
    error_message = "Неверный формат IP-адреса"
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
  description = "Список сетей с параметрами"
  type = list(object({
    name         = string
    gateway      = string # Пример: "192.168.10.1"
    netmask      = string # Пример: "255.255.255.0"
    static_start = string # Пример: "192.168.10.2"
    static_end   = string # Пример: "192.168.10.254"
    dns1         = string
    dns2         = string
    dns_suffix   = optional(string)
    dhcp_start   = optional(string)
    dhcp_end     = optional(string)
  }))
}

variable "dnat_rules" {
  description = "Правила проброса портов через внешнюю сеть ClientsExternalNetwork"
  type = list(object({
    network_name  = string
    internal_ip   = string # Серый IP внутри сети
    internal_port = number # Порт на целевой ВМ
    external_port = number # Порт на внешнем IP
    protocol      = string # Протокол (tcp/udp)
  }))
  default = []
  validation {
    condition = alltrue([
      for r in var.dnat_rules :
      contains(["tcp", "udp"], lower(r.protocol)) &&
      r.internal_port > 0 &&
      r.external_port > 0
    ])
    error_message = "Допустимы только TCP/UDP с портами > 0"
  }
}

variable "enable_outbound_firewall" {
  description = "Разрешить исходящий интернет-трафик для сетей"
  type        = bool
  default     = true
}



