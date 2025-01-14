variable "datacenter_data" {
  description = "Datacenter name"
  type        = string
}

variable "cluster_data" {
  description = "Cluster name"
  type        = string
}

variable "vsphere_resource_pool_name" {
  description = "Resource pool name connect to VM"
  type        = string
}

variable "vsphere_folder_name" {
  description = "VM folder name connect to VM"
  type        = string
}
