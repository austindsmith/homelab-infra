# Master node
resource "proxmox_vm_qemu" "k3s_master" {
  name        = "k3s-master-01"
  target_node = "pve"
  clone       = var.vm_template
  full_clone  = true

  cores   = 2
  memory  = 4096
  disk_gb = 32

  network {
    model  = "virtio"
    bridge = "vmbr0"
    vlan   = 2
  }

  ciuser     = "ubuntu"
  cipassword = ""

  sshkeys   = <<-EOF
    ${file("~/.ssh/id_rsa.pub")} 
    EOF 
  ipconfig0 = "ip=192.168.50.11/24,gw=192.168.50.1"
  tags      = "k3s"
}


resource "proxmox_vm_qemu" "k3s_worker" {
  count       = 2
  name        = "k3s-worker-0${count.index + 1}"
  target_node = "pve"
  clone       = var.vm_template
  full_clone  = true
  cores       = 2
  memory      = 4096
  disk_gb     = 32
  network {
    model  = "virtio"
    bridge = "vmbr0"
    vlan   = 2
  }
  ciuser     = "ubuntu"
  cipassword = ""

  sshkeys   = <<-EOF
    ${file("~/.ssh/id_rsa.pub")} 
    EOF 
  ipconfig0 = "ip=192.168.50.${12 + count.index}/24,gw=192.168.50.1"
  tags      = "k3s"
}