# OpenTofu Module: vCD VM Deployment

Модуль создает одну или несколько виртуальных машин в VMware Cloud Director из шаблона каталога и выполняет гостевую кастомизацию.

## Возможности

- Развертывание одной ВМ или группы ВМ (`instance_count`)
- Авто-нейминг для пачки инстансов (`name-01`, `name-02`, ...)
- Настройка CPU, RAM, диска и типа шины диска
- Подключение к Org Network (`POOL`, `DHCP`, `MANUAL`)
- Linux/Windows guest customization через `initscript`
- Встроенные precondition-проверки для частых ошибок входных данных

## Требования

- OpenTofu `>= 1.9.0, < 2.0.0`
- `vmware/vcd` `>= 3.14.1, < 4.0.0`
- Доступ к vCloud Director API

## Быстрый старт

```hcl
module "vm_deployment" {
  source = "git::https://github.com/K1haa/Terraform-modules.git//VMware-VCD/vm?ref=main"

  vm_name        = "app-server"
  instance_count = 2
  computer_name  = "app"
  os_type        = "linux"

  catalog_org_name = "my-org"
  catalog_name     = "templates"
  template_name    = "ubuntu-2204"
  storage_policies = "SSD-Storage"

  memory       = 4096
  cpus         = 2
  disk_size_mb = 51200
  bus_type     = "paravirtual"

  network            = "internal-network"
  ip_allocation_mode = "MANUAL"
  static_ips         = ["192.168.10.15", "192.168.10.16"]

  admin_password        = "ChangeMe123!"
  force_customization   = false
  number_of_auto_logons = 1

  linux_init_script_path = "scripts/linux-init.sh"
}
```

## Важные входные параметры

- `vm_name` — базовое имя ВМ
- `instance_count` — количество создаваемых инстансов
- `computer_name` — имя хоста в ОС
- `os_type` — `linux` или `windows`
- `catalog_org_name`, `catalog_name`, `template_name` — источник шаблона
- `storage_policies` — профиль хранения диска
- `network` — Org Network для подключения ВМ
- `ip_allocation_mode` — `MANUAL`, `POOL`, `DHCP`
- `static_ips` — обязателен в `MANUAL`, длина списка должна совпадать с `instance_count`
- `linux_init_script_path` / `windows_init_script_path` — путь к init-скрипту под выбранную ОС
- `admin_password` — пароль локального администратора

## Outputs

- `vm_ids` — список ID созданных ВМ
- `vm_names` — список имен созданных ВМ
- `vm_name_to_id` — map имя ВМ -> ID

## Замечания

- При `instance_count > 1` к `vm_name` и `computer_name` автоматически добавляется суффикс с порядковым номером.
- `ip_allocation_mode`, `os_type` и `bus_type` нормализуются внутри модуля (`upper/lower`), поэтому ввод не чувствителен к регистру.
- Для Linux и Windows используются разные скрипты кастомизации; укажи только релевантный путь под выбранную ОС.