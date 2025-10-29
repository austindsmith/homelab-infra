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

variable "lxc_template" {
  type    = string
  default = "ubuntu-25.04-standard_25.04-1.1_amd64.tar.zst"
}

variable "lxc_storage" {
  type    = string
  default = "local-lvm"
}

variable "lxc_password" {
  type      = string
  sensitive = true
}

variable "lxc_memory" {
  type    = number
  default = 512
}

variable "lxc_cores" {
  type    = number
  default = 1
}

variable "lxc_count" {
  type    = number
  default = 5
}