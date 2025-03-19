resource "vcd_vm" "vm" {
  count                  = var.instance_count
  name                   = var.instance_count > 1 ? "${var.vm_name}-${format("%02d", count.index + 1)}" : var.vm_name
  computer_name          = var.instance_count > 1 ? "${var.computer_name}-${format("%02d", count.index + 1)}" : var.computer_name
  vapp_template_id       = data.vcd_catalog_vapp_template.template01.id
  memory                 = var.memory
  memory_hot_add_enabled = true
  cpus                   = var.cpus
  cpu_hot_add_enabled    = true

  override_template_disk {
    bus_number      = 0
    unit_number     = 0
    bus_type        = "paravirtual"
    storage_profile = var.storage_policies
    size_in_mb      = var.disk_size_mb
  }

  network {
    type               = "org"
    name               = var.network
    ip_allocation_mode = var.ip_allocation_mode
    adapter_type       = "VMXNET3"
    ip                 = var.ip_allocation_mode == "MANUAL" ? var.static_ips[count.index] : null
  }

  customization {
    enabled                    = true
    auto_generate_password     = false
    allow_local_admin_password = true
    admin_password             = var.admin_password
    change_sid                 = var.os_type == "windows"
    force                      = var.force_customization
    initscript                 = var.os_type == "linux" ? file(var.linux_init_script_path) : file(var.windows_init_script_path)
  }

  power_on = true

  lifecycle {

    precondition {
      condition     = var.ip_allocation_mode != "MANUAL" || length(var.static_ips) == var.instance_count
      error_message = "Количество статических IP должно совпадать с количеством инстансов"
    }

    precondition {
      condition     = var.ip_allocation_mode != "MANUAL" || var.static_ips != null
      error_message = "Для MANUAL режима необходимо указать static_ips"
    }

    precondition {
      condition     = var.os_type != "linux" || var.linux_init_script_path != ""
      error_message = "Для Linux необходимо указать linux_init_script_path"
    }

    precondition {
      condition     = var.os_type != "windows" || var.windows_init_script_path != ""
      error_message = "Для Windows необходимо указать windows_init_script_path"
    }
  }
}




