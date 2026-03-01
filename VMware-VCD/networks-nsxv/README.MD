# OpenTofu Module: NSX-V Network Stack

Единый модуль NSX-V для vCloud Director с покрытием ключевых сетевых подсистем:
- Firewall
- DHCP Relay
- NAT (SNAT/DNAT)
- Routing contract/manifest
- Load Balancer (`vcd_lb_*`)
- VPN IPsec (`vcd_edgegateway_vpn`)
- Edge Gateway global settings

## Поддерживаемые версии

- OpenTofu `>= 1.9.0, < 2.0.0`
- `vmware/vcd` `>= 3.14.1, < 4.0.0`

## Что умеет модуль

### NAT
- Multi-IP NAT через `external_ips`
- DNAT с:
  - single backend
  - active/standby backend list (`backends`)
  - source restrictions для auto-firewall (`source_cidrs`)
- SNAT:
  - для каждой сети
  - per-network override (`snat_external_ip`)
  - segment policies (`snat_policies`)

### Firewall
- Outbound policy groups с:
  - `priority`
  - `above_rule_id`
  - `address_groups`
  - `services_catalog`
  - `service_presets`
- Auto-allow firewall правила для DNAT
- Единый стиль протоколов (`tcp/udp/icmp/any` в lower-case)

### DHCP
- DHCP relay (`vcd_nsxv_dhcp_relay`)
- relay agents по сетям

### Load Balancer
- `vcd_lb_app_rule`
- `vcd_lb_app_profile`
- `vcd_lb_service_monitor`
- `vcd_lb_server_pool`
- `vcd_lb_virtual_server`

### VPN
- IPsec site-to-site (`vcd_edgegateway_vpn`)
- Поддержка нескольких туннелей

### Routing
- Входной контракт `routing` и `routing_manifest` output
- Важно: для NSX-V в текущем provider нет отдельного полнофункционального ресурса static routes как в NSX-T, поэтому здесь provider-only manifest-подход

## Матрица покрытия (NSX-V UI -> модуль -> provider)

| UI tab | Поддержка в модуле | Ограничение `vmware/vcd` provider |
| --- | --- | --- |
| Firewall | Да, реализовано (`vcd_nsxv_firewall_rule`), включая outbound groups и DNAT auto-allow | Ограничений для базовых NSX-V firewall rule сценариев в рамках ресурса модуля нет |
| DHCP | Частично: DHCP pool на сети (`vcd_network_routed`) + DHCP Relay (`vcd_nsxv_dhcp_relay`) | DHCP static bindings (MAC->IP) для NSX-V отсутствуют; bindings есть для NSX-T (`vcd_nsxt_network_dhcp_binding`) |
| NAT | Да, реализовано (`vcd_nsxv_snat`, `vcd_nsxv_dnat`) | Ограничено возможностями NSX-V ресурсов provider (вне их полей модуль не расширяет API) |
| Routing -> Routing Configuration | Частично: только контракт входных данных + `routing_manifest` | Нет отдельного NSX-V ресурса для полноценного управления advanced routing config |
| Routing -> Static Routes | Нет (как управляемый ресурс) | NSX-V static routes как отдельный полнофункциональный ресурс в provider отсутствуют (есть NSX-T ресурсы) |
| Routing -> OSPF | Нет | NSX-V OSPF ресурса в provider нет |
| Routing -> BGP | Нет | NSX-V BGP ресурса в provider нет |
| Routing -> Route Redistribution | Нет | NSX-V route redistribution ресурса в provider нет |
| Load Balancer | Да, реализовано (`vcd_lb_*`) | Покрытие ограничено доступными атрибутами соответствующих `vcd_lb_*` ресурсов |
| VPN -> IPsec VPN Sites | Да, реализовано (`vcd_edgegateway_vpn`) | Управление доступно на уровне site/tunnel, в пределах атрибутов ресурса |
| VPN -> Activation Status | Частично (косвенно через наличие/состояние IPsec site ресурсов) | Отдельного NSX-V ресурса для централизованного service activation toggle нет |
| VPN -> Global Configuration | Нет как отдельный блок | Отдельного NSX-V ресурса для global configuration в provider нет |
| VPN -> Logging Settings | Нет как отдельный блок | Отдельного NSX-V ресурса для VPN logging settings в provider нет |
| VPN -> L2 VPN | Нет | L2 VPN для NSX-V в provider не поддерживается |
| Edge Settings | Да, реализовано (`vcd_edgegateway_settings`) | Покрывает только поля, доступные в ресурсе (FW/LB global settings) |

## Быстрый пример

```hcl
module "nsxv_stack" {
  source = "git::https://github.com/K1haa/Terraform-modules.git//VMware-VCD/networks-nsxv?ref=main"

  edge_gateway_name     = "my-edge-gw"
  external_network_name = "ClientsExternalNetwork"
  external_ips          = ["203.0.113.10", "203.0.113.11"]
  interface_type        = "internal"

  module_options = {
    enable_snat                    = true
    enable_outbound_firewall       = true
    enable_dnat_firewall_rules     = true
    name_prefix                    = "prod"
    allowed_external_network_names = ["ClientsExternalNetwork"]
  }

  networks = [
    {
      name         = "app-net"
      gateway      = "192.168.10.1"
      netmask      = "255.255.255.0"
      static_start = "192.168.10.10"
      static_end   = "192.168.10.50"
      dns1         = "8.8.8.8"
      dns2         = "1.1.1.1"
      snat_enabled = true
    }
  ]

  dnat_rules = [
    {
      external_ip       = "203.0.113.10"
      external_port     = 8443
      protocol          = "tcp"
      distribution_mode = "active_standby"
      backends = [
        { internal_ip = "192.168.10.21", internal_port = 443, enabled = true },
        { internal_ip = "192.168.10.22", internal_port = 443, enabled = false }
      ]
    }
  ]
}
```

## Service Presets

`service_presets` включает расширенный каталог:

`web`, `dns`, `ssh`, `ntp`, `smtp`, `rdp`, `k8s-control-plane`, `k8s-node`, `monitoring`, `ldap`, `ldaps`, `kerberos`, `snmp`, `syslog`, `dhcp`, `imap`, `pop3`, `nfs`, `mysql`, `postgres`, `mssql`, `redis`, `mongodb`, `rabbitmq`, `kafka`, `elasticsearch`, `prometheus`, `grafana`, `loki`, `tempo`, `jaeger`, `consul`, `vault`, `etcd`.

## Ключевые outputs

- `network_ids`, `network_actual_names`, `network_cidrs`
- `snat_rule_ids`, `snat_segment_rule_ids`
- `dnat_rule_ids`, `dnat_rule_ids_by_network_external_ip_protocol_port`
- `outbound_firewall_rule_ids`, `outbound_firewall_rule_ids_by_network_group`
- `dhcp_relay_id`
- `edge_settings_id`
- `lb_app_rule_ids`, `lb_app_profile_ids`, `lb_service_monitor_ids`, `lb_server_pool_ids`, `lb_virtual_server_ids`
- `vpn_ipsec_ids`
- `routing_manifest`
- `effective_manifest`
