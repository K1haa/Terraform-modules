terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = ">= 3.14.1, < 4.0.0"
    }
  }
}
