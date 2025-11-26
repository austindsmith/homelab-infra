variable "ssh_pubkey_path" {
  type    = string
  default = "/home/austin/.ssh/id_ed25519.pub"
}

variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type = string
}

variable "node_name" {
  type    = string
  default = "proxmox"
}

variable "vm_template" {
  default = "ubuntu-2004-cloudinit-template"
}

variable "vm_storage" {
  type    = string
  default = "local-lvm"
}

variable "vm_password" {
  type      = string
  sensitive = true
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