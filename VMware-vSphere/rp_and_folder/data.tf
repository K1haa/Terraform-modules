data "vsphere_datacenter" "datacenter" {
  name = var.datacenter_data
}
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_data
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
