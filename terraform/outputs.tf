output "k3s_node_ips" {
  value = {
    master = "192.168.50.11"


    workers = [
      for i in proxmox_vm_qemu.k3s_worker :
      i.network_interfaces[0].ip
    ]
  }
}