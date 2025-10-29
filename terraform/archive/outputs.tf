output "k3s_master_ip" {
  value = "192.168.50.11"
}

output "k3s_worker_ips" {
  value = [for i in range(2) : format("192.168.50.%d", 12 + i)]
}
