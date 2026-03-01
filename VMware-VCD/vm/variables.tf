variable "vm_name" {
  description = "Базовое имя виртуальной машины"
  type        = string
  validation {
    condition     = trimspace(var.vm_name) != ""
    error_message = "vm_name не может быть пустым"
  }
}

variable "instance_count" {
  description = "Количество инстансов"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count >= 1 && floor(var.instance_count) == var.instance_count
    error_message = "instance_count должен быть целым числом >= 1"
  }
}

variable "computer_name" {
  description = "Имя компьютера в ОС"
  type        = string
  validation {
    condition     = trimspace(var.computer_name) != ""
    error_message = "computer_name не может быть пустым"
  }
}


variable "os_type" {
  description = "Тип ОС (linux/windows)"
  type        = string
  validation {
    condition     = contains(["linux", "windows"], lower(trimspace(var.os_type)))
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

variable "catalog_org_name" {
  description = "Имя организации"
  type        = string
  validation {
    condition     = trimspace(var.catalog_org_name) != ""
    error_message = "catalog_org_name не может быть пустым"
  }
}

variable "catalog_name" {
  description = "Имя каталога с шаблоном"
  type        = string
  validation {
    condition     = trimspace(var.catalog_name) != ""
    error_message = "catalog_name не может быть пустым"
  }
}

variable "template_name" {
  description = "Имя шаблона в каталоге"
  type        = string
  validation {
    condition     = trimspace(var.template_name) != ""
    error_message = "template_name не может быть пустым"
  }
}

variable "storage_policies" {
  description = "Профиль хранилища"
  type        = string
  validation {
    condition     = trimspace(var.storage_policies) != ""
    error_message = "storage_policies не может быть пустым"
  }
}


variable "network" {
  description = "Имя управляющей сети"
  type        = string
  validation {
    condition     = trimspace(var.network) != ""
    error_message = "network не может быть пустым"
  }
}

variable "ip_allocation_mode" {
  description = "Режим IP (MANUAL/POOL/DHCP)"
  type        = string
  default     = "POOL"
  validation {
    condition     = contains(["MANUAL", "POOL", "DHCP"], upper(trimspace(var.ip_allocation_mode)))
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
  validation {
    condition     = length(var.static_ips) == length(distinct(var.static_ips))
    error_message = "static_ips не должен содержать дубли"
  }
}


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


variable "memory" {
  description = "Объем памяти (MB)"
  type        = number
  default     = 2048
  validation {
    condition     = var.memory >= 256
    error_message = "memory должен быть >= 256 MB"
  }
}

variable "cpus" {
  description = "Количество CPU"
  type        = number
  default     = 1
  validation {
    condition     = var.cpus >= 1 && floor(var.cpus) == var.cpus
    error_message = "cpus должен быть целым числом >= 1"
  }
}

variable "disk_size_mb" {
  description = "Размер диска (MB)"
  type        = number
  default     = 30720
  validation {
    condition     = var.disk_size_mb >= 1024
    error_message = "disk_size_mb должен быть >= 1024 MB"
  }
}


variable "admin_password" {
  description = "Пароль администратора"
  type        = string
  sensitive   = true
  validation {
    condition     = trimspace(var.admin_password) != ""
    error_message = "admin_password не может быть пустым"
  }
}

variable "number_of_auto_logons" {
  description = "Количество автовходов"
  type        = number
  default     = 1
  validation {
    condition     = var.number_of_auto_logons >= 0 && floor(var.number_of_auto_logons) == var.number_of_auto_logons
    error_message = "number_of_auto_logons должен быть целым числом >= 0"
  }
}

variable "force_customization" {
  type        = bool
  description = "Принудительное выполнение кастомизации"
  default     = false
}

variable "bus_type" {
  description = "Тип шины диска"
  type        = string
  default     = "paravirtual"
  validation {
    condition     = contains(["parallel", "ide", "paravirtual", "sata", "nvme", "sas"], lower(trimspace(var.bus_type)))
    error_message = "Допустимы: parallel, ide, paravirtual, sata, nvme, sas"
  }
}
