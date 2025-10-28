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

variable "ssh_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcwZAOfqf6E6p8IkrurF2vR3NccPbMlXFPaFe2+Eh/8QnQCJVTL6PKduXjXynuLziC9cubXIDzQA+4OpFYUV2u0fAkXLOXRIwgEmOrnsGAqJTqIsMC3XwGRhR9M84c4XPAX5sYpOsvZX/qwFE95GAdExCUkS3H39rpmSCnZG9AY4nPsVRlIIDP+/6YSy9KWp2YVYe5bDaMKRtwKSq3EOUhl3Mm8Ykzd35Z0Cysgm2hR2poN+EB7GD67fyi+6ohpdJHVhinHi7cQI4DUp+37nVZG4ofYFL9yRdULlHcFa9MocESvFVlVW0FCvwFKXDty6askpg9yf4FnM0OSbhgqXzD austin@EARTH"
}