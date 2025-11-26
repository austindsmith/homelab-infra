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
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.5.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

# Generate Talos machine configurations
resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = "k3s-cluster"
  cluster_endpoint = "https://192.168.50.15:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = "k3s-cluster"
  cluster_endpoint = "https://192.168.50.15:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

# Generate client configuration
data "talos_client_configuration" "this" {
  cluster_name         = "k3s-cluster"
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for i in range(var.vm_count) : "192.168.50.${15 + i}"]
}

# MAC addresses for VMs
resource "random_id" "mac" {
  count       = var.vm_count
  byte_length = 5
}

# Talos VMs
resource "proxmox_vm_qemu" "talos_vm" {
  count = var.vm_count
  name  = "lab-k8s-0${count.index + 1}"
  vmid  = 2000 + count.index

  target_node = var.node_name
  clone       = var.vm_template
  full_clone  = true
  
  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "host"
  }

  agent    = 0  # Talos doesn't use QEMU agent
  os_type  = "l26"  # Linux 2.6+ kernel
  memory   = var.vm_memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.vm_disk_storage
          size    = var.vm_disk_size
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
  vm_state  = "running"
  onboot    = true

  # Talos configuration
  cicustom = "user=local:snippets/talos-${count.index == 0 ? "controlplane" : "worker"}.yaml"
}

# Apply Talos configurations
resource "talos_machine_configuration_apply" "controlplane" {
  depends_on                    = [proxmox_vm_qemu.talos_vm]
  client_configuration          = talos_machine_secrets.this.client_configuration
  machine_configuration_input   = data.talos_machine_configuration.controlplane.machine_configuration
  node                         = "192.168.50.15"
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
        }
        network = {
          hostname = "lab-k8s-01"
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"  # We'll install our own CNI
          }
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on                    = [proxmox_vm_qemu.talos_vm]
  count                        = var.vm_count - 1
  client_configuration          = talos_machine_secrets.this.client_configuration
  machine_configuration_input   = data.talos_machine_configuration.worker.machine_configuration
  node                         = "192.168.50.${16 + count.index}"
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
        }
        network = {
          hostname = "lab-k8s-0${count.index + 2}"
        }
      }
    })
  ]
}

# Bootstrap the cluster
resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                = "192.168.50.15"
}

# Generate kubeconfig
data "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                = "192.168.50.15"
}

# Save configurations locally
resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/../talosconfig"
}

resource "local_file" "kubeconfig" {
  content  = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/../kubeconfig"
}
