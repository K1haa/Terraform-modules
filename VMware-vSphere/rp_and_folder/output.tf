output "resource_pool_id" {
  value = vsphere_resource_pool.resource_pool_vm.id
}

output "folder_path" {
  value = vsphere_folder.vm_folder.path
}
