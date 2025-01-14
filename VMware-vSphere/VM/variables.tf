variable "datacenter_data" {
  description = "Datacenter name"
  type        = string
}
variable "datastore_data" {
  description = "Datastore name"
  type        = string
}
variable "cluster_data" {
  description = "Cluster name"
  type        = string
}
variable "resource_pool_id" {
  type = string
}
variable "folder_path" {
  type = string
}
variable "vm_password" {
  description = "Admin Pass VM"
  type        = string
}
variable "vsphere_network_name" {
  description = "Network name connect to VM"
  type        = string
}
variable "num_cpus" {
  description = "Number or CPUs VM"
  type        = number
  default     = 2
}
variable "memory" {
  description = "Memory VM"
  type        = number
  default     = 4096
}
variable "disk_size" {
  description = "Size Disk 0:0"
  type        = number
  default     = 40
}
variable "run_once_command_list" {
  description = "Список команд для каждой VM. Пример: {\"win01\" = [\"cmd1\"], \"win02\" = [\"cmd2\"]}"
  type        = map(list(string))
  default     = null
}
#####################################
# Пример использования разных команд для виндовых серверов без доступа к ним напрямую 
#{ 
#     "win01"       = ["powershell.exe -Command \"Start-Sleep -Seconds 30; C:\\scripts\\init01.ps1\""],
#     "win02"       = ["powershell.exe -Command \"Start-Sleep -Seconds 30; C:\\scripts\\init02.ps1\""],
#     "win03"       = ["powershell.exe -Command \"Start-Sleep -Seconds 30; C:\\scripts\\init03.ps1\""]
#   }
#####################################

variable "template_name" {
  description = "Template name"
  type        = string
}
variable "ipv4_gateway" {
  description = "Subnet gateway"
  type        = string
}
variable "ipv4_netmask" {
  description = "Subnet gateway"
  type        = number
  default     = 24
}
variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
}
variable "domain_admin_user" {
  description = "Domain user"
  type        = string
  default     = null
}
variable "domain_admin_password" {
  description = "Domain user password"
  type        = string
  default     = null
}
variable "join_domain" {
  description = "Domain"
  type        = string
  default     = null
}
variable "domain_ou" {
  description = "OU Domain"
  type        = string
  default     = null
}
variable "workgroup" {
  description = "The workgroup name for this virtual machine. One of this or join_domain must be included."
  default     = null
}
variable "is_windows_image" {
  description = "Boolean flag to notify when the custom image is windows based."
  type        = bool
  default     = false
}
variable "product_key" {
  description = "Product key Windows License"
  type        = string
  default     = null
}
variable "domain_linux" {
  description = "default VM domain for linux guest customization and fqdn name (if fqdnvmname is true)."
  default     = "zherdev.local"
}
variable "script_text" {
  description = "Текст кастомизационного скрипта для каждой VM. Пример: {\"node01\" = \"echo 'hello world'\"}"
  type        = map(string)
  default     = {}
}
#####################################
# Пример использования разных команд для линукс серверов без доступа к ним напрямую
#script_text = {
#    "ubuntu-app01" = "echo 'App 01 initialized'; apt-get update",
#    "ubuntu-app02" = "echo 'App 02 initialized'; apt-get install -y nginx"
#  }
#####################################
variable "time_zone" {
  description = "Time zone"
  type        = number
  default     = 145
}
variable "hw_clock_utc" {
  description = "Hardware clock UTC"
  type        = bool
  default     = false

}
variable "auto_logon" {
  description = "Auto logon"
  type        = bool
  default     = false
}
variable "auto_logon_count" {
  description = "Auto logon count"
  type        = number
  default     = 1
}
variable "path_iso" {
  description = "ISO parth of Datastore"
  type        = string
  default     = "no ISO-Image"
}
variable "vm_names" {
  description = "List of VM names"
  type        = list(string)
}
variable "vm_ips" {
  description = "List of IP addresses for VMs"
  type        = list(string)
}
