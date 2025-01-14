output "vm_names" {
  description = "Имена созданных виртуальных машин"
  value       = [for vm in vsphere_virtual_machine.VM : vm.name]
}

output "vm_ips" {
  description = "IP-адреса созданных виртуальных машин"
  value       = [for vm in vsphere_virtual_machine.VM : vm.guest_ip_addresses]
}

output "vm_ids" {
  description = "Уникальные идентификаторы созданных виртуальных машин"
  value       = [for vm in vsphere_virtual_machine.VM : vm.id]
}
