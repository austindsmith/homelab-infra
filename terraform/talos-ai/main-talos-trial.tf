terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

# MAC addresses for VMs
resource "random_id" "talos_mac" {
  count       = var.talos_vm_count
  byte_length = 5
}

# Talos Trial VMs - minimal resources, different IPs/VMIDs
resource "proxmox_vm_qemu" "talos_trial_vm" {
  count = var.talos_vm_count
  name  = "talos-trial-0${count.index + 1}"
  vmid  = 9100 + count.index  # Different VMID range

  target_node = var.node_name
  clone       = "talos-template"  # Your template ID 9001
  full_clone  = true
  
  cpu {
    cores   = var.talos_vm_cores
    sockets = 1
    type    = "host"
  }

  agent    = 0  # Talos doesn't use QEMU agent
  os_type  = "l26"  # Linux 2.6+ kernel
  memory   = var.talos_vm_memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.vm_disk_storage
          size    = var.talos_vm_disk_size
        }
      }
    }
  }

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    id      = 0
    tag     = 2
    macaddr = format(
      "02:%s:%s:%s:%s:%s",
      substr(random_id.talos_mac[count.index].hex, 0, 2),
      substr(random_id.talos_mac[count.index].hex, 2, 2),
      substr(random_id.talos_mac[count.index].hex, 4, 2),
      substr(random_id.talos_mac[count.index].hex, 6, 2),
      substr(random_id.talos_mac[count.index].hex, 8, 2)
    )
  }

  lifecycle {
    ignore_changes = [
      network,
      disks
    ]
  }

  # Different IP range - 192.168.50.25-27 instead of 15-17
  ipconfig0 = "ip=192.168.50.${25 + count.index}/24,gw=192.168.50.1"
  vm_state  = "running"
  onboot    = false  # Don't auto-start on boot for trial

  vga {
    type = "std"
  }
}

# Output the VM information
output "talos_trial_vms" {
  value = {
    for idx, vm in proxmox_vm_qemu.talos_trial_vm : vm.name => {
      vmid       = vm.vmid
      ip_address = "192.168.50.${25 + idx}"
      name       = vm.name
    }
  }
}

