output "vm_ids" {
  description = "Список ID созданных ВМ"
  value       = [for vm in vcd_vm.vm : vm.id]
}

output "vm_names" {
  description = "Список имен созданных ВМ"
  value       = [for vm in vcd_vm.vm : vm.name]
}

output "vm_name_to_id" {
  description = "Map имя ВМ -> ID"
  value       = { for vm in vcd_vm.vm : vm.name => vm.id }
}
