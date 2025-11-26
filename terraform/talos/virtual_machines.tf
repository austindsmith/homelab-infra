resource "proxmox_virtual_environment_vm" "talos_cp_01" {
  name        = "talos-cp-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "proxmox"
  on_boot     = true

  cpu {
    cores = 2
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    vlan_id = 2
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        #address = "dhcp"
        address = "${var.talos_cp_01_ip_addr}/24"
        gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker_01" {
  depends_on = [ proxmox_virtual_environment_vm.talos_cp_01 ]
  name        = "talos-worker-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "proxmox"
  on_boot     = true

  cpu {
    cores = 4
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    vlan_id = 2
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        #address = "dhcp"
        address = "${var.talos_worker_01_ip_addr}/24"
        gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}