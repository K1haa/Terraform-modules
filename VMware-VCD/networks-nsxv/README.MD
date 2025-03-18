# Terraform Module: vCD Network & NAT Automation

Этот модуль Terraform автоматизирует создание сетей, NAT-правил и фаерволл-правил в VMware Cloud Director (vCD).  
**Основные возможности:**
- Создание Routed сетей с DHCP/статическими пулами
- Автоматическая настройка SNAT для выхода в интернет
- Проброс портов через DNAT с поддержкой TCP/UDP
- Автоматическое открытие портов в фаерволе

## Использование

### Требования
- VMware Cloud Director 10.x+
- Terraform 1.0+
- Провайдер [`vmware/vcd`](https://registry.terraform.io/providers/vmware/vcd/latest) >= 3.10

### Пример подключения модуля

```hcl
module "network" {
  source = "git::https://github.com/K1haa/Terraform-modules.git//VMware-VCD/networks-nsxv?ref=main"

  edge_gateway_name = "edge-gw-1"
  external_ip       = "203.0.113.5"
  interface_type    = "internal"

  networks = [
    {
      name         = "prod-net",
      gateway      = "192.168.10.1",
      netmask      = "255.255.255.0",
      static_start = "192.168.10.10",
      static_end   = "192.168.10.20",
      dns1         = "8.8.8.8",
      dns2         = "8.8.4.4"
    }
  ]

  dnat_rules = [
    {
      internal_ip   = "192.168.10.15",
      internal_port = 80,
      external_port = 8080,
      protocol      = "tcp"
    }
  ]
}
 