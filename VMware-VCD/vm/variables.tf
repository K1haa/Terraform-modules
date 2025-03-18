# Основные параметры
variable "vm_name" {
  description = "Базовое имя виртуальной машины"
  type        = string
}

variable "instance_count" {
  description = "Количество инстансов"
  type        = number
  default     = 1
}

variable "computer_name" {
  description = "Имя компьютера в ОС"
  type        = string
}

# Параметры ОС
variable "os_type" {
  description = "Тип ОС (linux/windows)"
  type        = string
  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "Допустимы: linux, windows"
  }
}

variable "linux_init_script_path" {
  description = "Путь к скрипту инициализации Linux"
  type        = string
  default     = ""
}

variable "windows_init_script_path" {
  description = "Путь к скрипту инициализации Windows"
  type        = string
  default     = ""
}

# Шаблоны и хранилище
variable "catalog_org_name" {
  description = "Имя организации"
  type        = string
}

variable "catalog_name" {
  description = "Имя каталога с шаблоном"
  type        = string
}

variable "template_name" {
  description = "Имя шаблона в каталоге"
  type        = string
}

variable "storage_policies" {
  description = "Профиль хранилища"
  type        = string
}

# Сетевые настройки
variable "network" {
  description = "Имя управляющей сети"
  type        = string
}

variable "ip_allocation_mode" {
  description = "Режим IP (MANUAL/POOL/DHCP)"
  type        = string
  default     = "POOL"
  validation {
    condition     = contains(["MANUAL", "POOL", "DHCP"], var.ip_allocation_mode)
    error_message = "Допустимы: MANUAL, POOL, DHCP"
  }
}

variable "static_ips" {
  description = "Список статических IP адресов (для MANUAL режима)"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for ip in var.static_ips : can(cidrhost("${ip}/32", 0))
    ])
    error_message = "Неверный формат одного из IP-адресов"
  }
}

# Домен Windows
variable "join_domain" {
  description = "Присоединение к домену"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Имя домена Windows"
  type        = string
  default     = ""
}

variable "domain_user" {
  description = "Пользователь домена"
  type        = string
  default     = ""
}

variable "domain_password" {
  description = "Пароль домена"
  type        = string
  sensitive   = true
  default     = ""
}

variable "join_domain_account_ou" {
  description = "OU для присоединения"
  type        = string
  default     = ""
}

# Ресурсы ВМ
variable "memory" {
  description = "Объем памяти (MB)"
  type        = number
  default     = 2048
}

variable "cpus" {
  description = "Количество CPU"
  type        = number
  default     = 1
}

variable "disk_size_mb" {
  description = "Размер диска (MB)"
  type        = number
  default     = 30720
}

# Безопасность
variable "admin_password" {
  description = "Пароль администратора"
  type        = string
  sensitive   = true
}

variable "number_of_auto_logons" {
  description = "Количество автовходов"
  type        = number
  default     = 1
}
