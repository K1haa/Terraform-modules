resource "vsphere_virtual_machine" "VM" {
  for_each               = { for idx, vm_name in var.vm_names : vm_name => var.vm_ips[idx] }
  name                   = each.key
  resource_pool_id       = var.resource_pool_id
  folder                 = var.folder_path
  datastore_id           = data.vsphere_datastore.datastore.id
  num_cpus               = var.num_cpus
  cpu_hot_add_enabled    = true
  memory                 = var.memory
  memory_hot_add_enabled = true
  guest_id               = data.vsphere_virtual_machine.template.guest_id
  scsi_type              = data.vsphere_virtual_machine.template.scsi_type
  firmware               = "efi"
  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path         = var.path_iso
  }
  disk {
    label            = "Hard Disk 1"
    size             = var.disk_size
    thin_provisioned = true
  }
  network_interface {
    network_id     = data.vsphere_network.network.id
    adapter_type   = "vmxnet3"
    use_static_mac = var.use_static_mac
    mac_address    = var.mac_address
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.uuid
    customize {
      ipv4_gateway = var.ipv4_gateway

      network_interface {
        ipv4_address    = each.value
        ipv4_netmask    = var.ipv4_netmask
        dns_server_list = var.dns_servers

      }
      dynamic "linux_options" {
        for_each = var.is_windows_image ? [] : [1]
        content {
          host_name    = each.key
          domain       = var.domain_linux
          hw_clock_utc = var.hw_clock_utc
          time_zone    = var.time_zone
          script_text  = lookup(var.script_text, each.key, "")
        }
      }
      dynamic "windows_options" {
        for_each = var.is_windows_image ? [1] : []
        content {
          computer_name         = each.key
          admin_password        = var.vm_password
          workgroup             = var.workgroup
          join_domain           = var.join_domain
          domain_admin_user     = var.domain_admin_user
          domain_admin_password = var.domain_admin_password
          organization_name     = "Terraform"
          run_once_command_list = lookup(var.run_once_command_list, each.key, [])
          auto_logon            = var.auto_logon
          auto_logon_count      = var.auto_logon_count
          time_zone             = var.time_zone
          product_key           = var.product_key
          full_name             = each.key
        }
      }
    }
  }
}




