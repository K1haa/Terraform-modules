# Terraform Module: vSphere Virtual Machine Deployment

Этот модуль Terraform автоматизирует развертывание виртуальных машин в VMware vSphere.  
**Основные возможности:**
- Создание ВМ из шаблонов
- Гибкая настройка ресурсов (CPU, память, диск)
- Поддержка Linux и Windows
- Интеграция с доменом Active Directory
- Настройка сети (статический MAC/IP, DHCP)

## Использование

### Требования
- VMware vSphere 7.0+
- Terraform 1.0+
- Провайдер [`vsphere`](https://registry.terraform.io/providers/hashicorp/vsphere/latest) ≥ 2.4

### Пример подключения модуля
```hcl
module "vm_deployment" {
  source = "git::https://github.com/K1haa/Terraform-modules.git//VMware-vSphere/VM?ref=main"

  # Основные параметры
  vm_names        = ["web-01", "web-02"]
  vm_ips          = ["192.168.10.101", "192.168.10.102"]
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder_path      = "Production/VMs"

  # Параметры ОС
  is_windows_image = false
  domain_linux     = "example.com"
  script_text      = {
    "web-01" = file("scripts/web-init.sh")
  }

  # Сетевые настройки
  network_id       = data.vsphere_network.network.id
  ipv4_gateway     = "192.168.10.1"
  ipv4_netmask     = 24
  dns_servers      = ["8.8.8.8", "8.8.4.4"]
}