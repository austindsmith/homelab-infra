variable "pm_api_url" {
  type = string
}

variable "pm_api_token" {
  type = string
}

variable "node_name" {
  type    = string
  default = "proxmox"
}

variable "vm_storage" {
  type    = string
  default = "local-lvm"
}

variable "vm_memory" {
  type    = number
  default = 8192  # 8GB RAM per node for better performance
}

variable "vm_cores" {
  type    = number
  default = 4
}

variable "vm_count" {
  type    = number
  default = 3
}

variable "vm_disk_size" {
  type        = string
  default     = "100G"  # 100GB per node for plenty of space
  description = "Disk size for each VM (e.g., 100G, 200G)"
}

variable "vm_disk_storage" {
  type        = string
  default     = "local-lvm"
  description = "Storage pool for VM disks"
}

# ----------

variable "cluster_name" {
  type = string
  default = "homelab"
}

variable "default_gateway" {
  type = string
  default = "192.168.50.1"
}

variable "talos_cp_01_ip_addr" {
  type = string
  default = "192.168.50.15"
}

variable "talos_worker_01_ip_addr" {
  type = string
  default = "192.168.50.16"
}