variable "proxmox_host" {
  description = "Proxmox host address or IP"
  type        = string
}
variable "proxmox_token_id" {
  description = "Proxmox API Token ID (user@realm!tokenname)"
  type        = string
}
variable "proxmox_token_secret" {
  description = "Proxmox API Token secret"
  type        = string
}
variable "vm_template" {
  description = "Name or ID of the Proxmox template to clone"
  type        = string
}
variable "vm_count" {
  description = "Number of K3s cluster nodes"
  type        = string
  default     = 3
}