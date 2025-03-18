# Terraform Module: vCD Virtual Machine Deployment

Этот модуль Terraform автоматизирует развертывание виртуальных машин в VMware Cloud Director (vCD).  
**Основные возможности:**
- Создание ВМ из шаблонов каталога
- Настройка ресурсов (CPU, память, диск)
- Гибкое управление сетевыми параметрами (DHCP/статический IP)
- Интеграция скриптов инициализации для Linux/Windows
- Поддержка присоединения к домену Active Directory

## Использование

### Требования
- VMware Cloud Director 10.x+
- Terraform 1.0+
- Провайдер [`vmware/vcd`](https://registry.terraform.io/providers/vmware/vcd/latest) >= 3.10

### Пример подключения модуля
```hcl
module "vm_deployment" {
  source = "git::https://github.com/K1haa/Terraform-modules.git//VMware-VCD/vm?ref=main"

  # Основные параметры
  vm_name          = "app-server"
  instance_count   = 2
  computer_name    = "app"
  os_type          = "linux"
  admin_password   = "SecurePassword123!"

  # Шаблоны и хранилище
  catalog_org_name  = "my-org"
  catalog_name      = "templates"
  template_name     = "ubuntu-2204"
  storage_policies  = "SSD-Storage"

  # Сетевые настройки
  network              = "internal-network"
  ip_allocation_mode   = "MANUAL"
  static_ips           = ["192.168.10.15", "192.168.10.16"]

  # Скрипты инициализации
  linux_init_script_path = "scripts/cloud-init.sh"
}