# Talos Linux Trial Configuration
# Super minimal resources just for testing

variable "talos_vm_count" {
  type        = number
  default     = 3
  description = "Number of Talos VMs for trial (1 control plane + 2 workers)"
}

# Minimal memory for trial - 2GB per node
variable "talos_vm_memory" {
  type        = number
  default     = 2048
  description = "RAM per Talos VM in MB - minimal for trial"
}

# Minimal CPU for trial
variable "talos_vm_cores" {
  type        = number
  default     = 2
  description = "CPU cores per Talos VM - minimal for trial"
}

# Minimal disk for trial
variable "talos_vm_disk_size" {
  type        = string
  default     = "20G"
  description = "Disk size for each Talos VM - minimal for trial"
}

variable "talos_version" {
  type        = string
  default     = "v1.7.6"
  description = "Talos Linux version"
}

variable "kubernetes_version" {
  type        = string
  default     = "v1.30.3"
  description = "Kubernetes version (not installed in trial)"
}

