resource "vsphere_resource_pool" "resource_pool_vm" {
  name                    = var.vsphere_resource_pool_name
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
}

resource "vsphere_folder" "vm_folder" {
  path          = var.vsphere_folder_name
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
