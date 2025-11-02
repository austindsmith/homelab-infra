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
  default = 2048
}

variable "vm_cores" {
  type    = number
  default = 1
}

variable "vm_count" {
  type    = number
  default = 5
}