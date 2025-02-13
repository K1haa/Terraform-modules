# Terraform vSphere Virtual Machine Module

A Terraform module to create and manage vSphere Virtual Machines with customizable settings.

## Features

- Dynamic creation of multiple VMs
- Customizable CPU, memory, and disk configurations
- Windows and Linux OS customization
- Conditional provisioning based on the operating system

## Usage

### Example

```hcl
# Create Resource Pool and Folder

module "folder_and_rp" {
  source                     = "git::https://github.com/K1haa/Terraform-modules.git//VMware-vSphere/rp_and_folder?ref=main"
  vsphere_resource_pool_name = "Example-rp"
  vsphere_folder_name        = "Example-folder"
  # Data resource
  datacenter_data = "Datacenter name"
  cluster_data = "Cluster name"
}

module "vsphere_vm" {
  source = "git::https://github.com/K1haa/Terraform-modules.git//VMware-vSphere/VM?ref=main"
  # Data resource
  datacenter_data = "Datacenter name"
  cluster_data = "Cluster name"
  datastore_data = "Datastore name"
  # VM Names and IPs
  vm_names = ["vm1", "vm2"]
  vm_ips   = ["192.168.1.101", "192.168.1.102"]

  # Add to Resource Pool and Folder module: https://github.com/K1haa/Terraform-modules.git//VMware-vSphere/rp_and_folder
  resource_pool_id = module.folder_and_rp.resource_pool_id
  folder_path      = module.folder_and_rp.folder_path

  # VM Configuration
  num_cpus = 2
  memory   = 4096
  disk_size = 40

  # Network Configuration
  ipv4_gateway = "192.168.1.1"
  ipv4_netmask = 24
  dns_servers  = ["8.8.8.8", "8.8.4.4"]

  # OS Customization for Linux
  is_windows_image = false
  domain_linux     = "example.com"
  hw_clock_utc     = false
  time_zone        = 145 #("Europe/Moscow")
  script_text      = "echo 'Hello, world!'"
  
  # OS Customization for Windows
  is_windows_image      = true
  domain_admin_user     = "Administrator@example.com"
  domain_admin_password = "Admin10!"
  join_domain           = "example.com"
  domain_ou             = "DC=example, DC=com"
  run_once_command_list = {
    "ctx-sf01"       = ["powershell.exe -Command \"Start-Sleep -Seconds 30"]
  }
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
