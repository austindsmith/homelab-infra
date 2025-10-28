# Master node
resource "proxmox_vm_qemu" "k3s_master" {
  name        = "k3s-master-01"
  target_node = "pve"
  clone       = var.vm_template
  os_type = "cloud-init"
  full_clone  = true
  cpu = "host"
  bootdisk = "scsi0"
  scsihw = "virtio-scsi-pci"

  cores  = 2
  sockets = 1
  memory = 4096
  disk {
    slot = 0
    size = "10G"
    type = "scsi"
    storage = "local-zfs"
    iothread = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag     = 2
  }

  ciuser     = "ubuntu"
  cipassword = ""

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

  ipconfig0 = "ip=192.168.50.11/24,gw=192.168.50.1"
  tags      = "k3s"
}


resource "proxmox_vm_qemu" "k3s_worker" {
  count       = 2
  name        = "k3s-worker-0${count.index + 1}"
  target_node = "pve"
  clone       = var.vm_template
  os_type = "cloud-init"
  full_clone  = true
  cpu = "host"
  bootdisk = "scsi0"
  scsihw = "virtio-scsi-pci"

  cores  = 2
  sockets = 1
  memory = 4096
  disk {
    slot = 0
    size = "10G"
    type = "scsi"
    storage = "local-zfs"
    iothread = 1
  }
  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag     = 2
  }
  ciuser     = "ubuntu"
  cipassword = ""

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

  ipconfig0 = "ip=192.168.50.${12 + count.index}/24,gw=192.168.50.1"
  tags      = "k3s"
}