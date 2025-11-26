provider "proxmox" {
  endpoint          = var.pm_api_url
  api_token = var.pm_api_token
  insecure     = true
  ssh {
    agent = false
    username = "root"
    private_key = file("~/.ssh/id_rsa")
  }
}

provider "talos" {
  
}