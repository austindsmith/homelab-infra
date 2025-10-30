# Hardware requirements for k3s:
# https://docs.k3s.io/installation/requirements
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
    # Allows for randomization of MAC address for quicker apply/destroy
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

# Aids creating MAC address
resource "random_id" "mac" {
  count       = var.lxc_count
  byte_length = 5
}

resource "proxmox_lxc" "test-container" {
  count        = var.lxc_count
  hostname     = "LXC-test-${count.index + 1}"
  target_node  = var.node_name
  vmid         = 2000 + count.index
  ostemplate   = "local:vztmpl/${var.lxc_template}"
  cores        = var.lxc_cores
  memory       = var.lxc_memory
  password     = var.lxc_password
  unprivileged = true
  onboot       = true
  start        = true

  # This set is to get rid of the overlayfs error when installing k3s
  features {
    # Allows for containers within containers
    nesting = true
    # Allows the container to use the Linux keyring
    #keyctl  = true
    # Allows the container to use FUSE as a fallback to overlayfs
    #fuse    = true
  }

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.50.${15 + count.index}/24"
    gw     = "192.168.50.1"
    tag    = 2
    hwaddr = format("02:%s:%s:%s:%s:%s",
      substr(random_id.mac[count.index].hex, 0, 2),
      substr(random_id.mac[count.index].hex, 2, 2),
      substr(random_id.mac[count.index].hex, 4, 2),
      substr(random_id.mac[count.index].hex, 6, 2),
      substr(random_id.mac[count.index].hex, 8, 2)
    )
  }


  # writes to /root/.ssh/authorized_keys
  ssh_public_keys = file(var.ssh_pubkey_path)
}

