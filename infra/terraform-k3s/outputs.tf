locals {
  public_ip = var.allocate_eip && length(aws_eip.k3s) > 0 ? aws_eip.k3s[0].public_ip : aws_instance.k3s.public_ip
}

output "public_ip" {
  value = local.public_ip
}

output "grafana_url" {
  value = "http://grafana.${local.public_ip}.nip.io"
}

output "prometheus_url" {
  value = "http://prometheus.${local.public_ip}.nip.io"
}

output "alertmanager_url" {
  value = "http://alertmanager.${local.public_ip}.nip.io"
}
