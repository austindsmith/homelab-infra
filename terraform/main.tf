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

# one MAC per VM
resource "random_id" "mac" {
  count       = var.vm_count
  byte_length = 5
}

resource "proxmox_vm_qemu" "k3s_vm" {

  count = var.vm_count
  name        = "lab-k8s-${count.index + 1}"
  vmid        = 2000 + count.index

  target_node = var.node_name
  clone      = var.vm_template
  full_clone = true
  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "host"
  }

  agent  = 1
  os_type = "cloud-init"
  memory = var.vm_memory
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "25G"
        }
      }
    }
    ide {
      # pick ide2 if your template uses ide2
      ide2 {
        cloudinit {
          storage = "local-lvm"  # or local-lvm if CI allowed there
        }
      }
    }
  }
  network {
    model  = "virtio"
    bridge = "vmbr0"
    id     = 0
    tag    = 2
    macaddr = format(
      "02:%s:%s:%s:%s:%s",
      substr(random_id.mac[count.index].hex, 0, 2),
      substr(random_id.mac[count.index].hex, 2, 2),
      substr(random_id.mac[count.index].hex, 4, 2),
      substr(random_id.mac[count.index].hex, 6, 2),
      substr(random_id.mac[count.index].hex, 8, 2)
    )
  }

  lifecycle {
    ignore_changes = [
      network,
      disks
    ]
  }

  ipconfig0 = "ip=192.168.50.${15 + count.index}/24,gw=192.168.50.1"

  vm_state = "running"
  nameserver = "1.1.1.1 8.8.8.8"

  ciuser  = "root"
  cipassword = var.vm_password

  vga {
    type = "std"
  }

  
  sshkeys = file(var.ssh_pubkey_path)

  onboot = true
}
