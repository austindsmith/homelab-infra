# VM IP addresses for Ansible inventory
output "vm_ips" {
  description = "IP addresses of all K3s VMs"
  value = {
    for idx, vm in proxmox_vm_qemu.k3s_vm : 
    vm.name => "192.168.50.${15 + idx}"
  }
}

# Server node IP
output "server_ip" {
  description = "IP address of the K3s server node"
  value       = "192.168.50.15"
}

# Agent node IPs
output "agent_ips" {
  description = "IP addresses of the K3s agent nodes"
  value       = [for idx in range(1, var.vm_count) : "192.168.50.${15 + idx}"]
}

# Cluster endpoint
output "cluster_endpoint" {
  description = "K3s cluster API endpoint"
  value       = "https://192.168.50.15:6443"
}

# VM names
output "vm_names" {
  description = "Names of all VMs"
  value       = [for vm in proxmox_vm_qemu.k3s_vm : vm.name]
}

# VM specifications
output "vm_specs" {
  description = "VM specifications for reference"
  value = {
    memory_mb    = var.vm_memory
    cpu_cores    = var.vm_cores
    disk_size    = var.vm_disk_size
    storage_pool = var.vm_disk_storage
    count        = var.vm_count
  }
}