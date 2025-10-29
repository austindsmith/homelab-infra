output "lxc_ip_addresses" {
  value = {
    for ct in proxmox_lxc.test-container :
    ct.hostname => split("/", ct.network[0].ip)[0]
  }
  description = "Test description"
  sensitive   = false
}