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
  count       = var.vm_count

  name        = "lab-k8s-${count.index + 1}"
  target_node = var.node_name
  vmid        = 2000 + count.index

  # use the template NAME
  clone       = "ubuntu-24-04-ci"
  full_clone  = true

  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "x86-64-v3"
  }

  memory = var.vm_memory
  scsihw = "virtio-scsi-pci"
  agent  = 1

  # keep template disks → no disk{} here
  # keep template cloud-init drive → no delete of ide2
  # so: DO NOT set boot=...; let Proxmox inherit from template

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    id     = 2
    macaddr = format(
      "02:%s:%s:%s:%s:%s",
      substr(random_id.mac[count.index].hex, 0, 2),
      substr(random_id.mac[count.index].hex, 2, 2),
      substr(random_id.mac[count.index].hex, 4, 2),
      substr(random_id.mac[count.index].hex, 6, 2),
      substr(random_id.mac[count.index].hex, 8, 2)
    )
  }

  # cloud-init network
  ipconfig0 = "ip=192.168.50.${15 + count.index}/24,gw=192.168.50.1"

  ciuser  = "ubuntu"
  sshkeys = file(var.ssh_pubkey_path)

  onboot = true
}
