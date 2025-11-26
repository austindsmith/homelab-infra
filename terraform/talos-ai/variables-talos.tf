# Talos Linux Configuration for K3s Cluster
# Talos uses ~200MB RAM vs Ubuntu's ~1GB+ - saves 2.5GB+ total

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

# Talos Linux template - you'll need to create this
variable "vm_template" {
  default = "talos-linux-template"  # We'll help you create this
}

variable "vm_storage" {
  type    = string
  default = "local-lvm"
}

variable "vm_password" {
  type      = string
  sensitive = true
  default   = ""  # Talos doesn't use passwords, uses SSH keys only
}

# Same memory but more efficient OS
variable "vm_memory" {
  type    = number
  default = 8192  # 8GB RAM per node - but Talos uses ~2.5GB less total
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
  default     = "100G"
  description = "Disk size for each VM"
}

variable "vm_disk_storage" {
  type        = string
  default     = "local-lvm"
  description = "Storage pool for VM disks"
}

# Talos-specific variables
variable "talos_version" {
  type        = string
  default     = "v1.7.6"  # Latest stable Talos version
  description = "Talos Linux version to use"
}

variable "kubernetes_version" {
  type        = string
  default     = "v1.30.3"  # Latest stable K8s version
  description = "Kubernetes version to install"
}
