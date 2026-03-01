locals {
  normalized_os_type           = lower(trimspace(var.os_type))
  normalized_ip_allocation     = upper(trimspace(var.ip_allocation_mode))
  normalized_bus_type          = lower(trimspace(var.bus_type))
  normalized_linux_script_path = trimspace(var.linux_init_script_path)
  normalized_windows_script    = trimspace(var.windows_init_script_path)
}

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
    bus_type        = local.normalized_bus_type
    storage_profile = var.storage_policies
    size_in_mb      = var.disk_size_mb
  }

  network {
    type               = "org"
    name               = var.network
    ip_allocation_mode = local.normalized_ip_allocation
    adapter_type       = "VMXNET3"
    ip                 = local.normalized_ip_allocation == "MANUAL" ? var.static_ips[count.index] : null
  }

  customization {
    enabled                    = true
    auto_generate_password     = false
    allow_local_admin_password = true
    admin_password             = var.admin_password
    change_sid                 = local.normalized_os_type == "windows"
    force                      = var.force_customization
    initscript                 = local.normalized_os_type == "linux" ? file(local.normalized_linux_script_path) : file(local.normalized_windows_script)
    number_of_auto_logons      = var.number_of_auto_logons
  }

  power_on = true

  lifecycle {

    precondition {
      condition     = local.normalized_ip_allocation != "MANUAL" || length(var.static_ips) == var.instance_count
      error_message = "Количество статических IP должно совпадать с количеством инстансов"
    }

    precondition {
      condition     = local.normalized_ip_allocation != "MANUAL" || var.static_ips != null
      error_message = "Для MANUAL режима необходимо указать static_ips"
    }

    precondition {
      condition     = local.normalized_os_type != "linux" || local.normalized_linux_script_path != ""
      error_message = "Для Linux необходимо указать linux_init_script_path"
    }

    precondition {
      condition     = local.normalized_os_type != "windows" || local.normalized_windows_script != ""
      error_message = "Для Windows необходимо указать windows_init_script_path"
    }
    precondition {
      condition     = contains(["ide", "paravirtual", "parallel", "sata", "nvme", "sas"], local.normalized_bus_type)
      error_message = "Недопустимый тип шины: используйте ide, paravirtual, parallel, sata, nvme, sas"
    }
  }
}




