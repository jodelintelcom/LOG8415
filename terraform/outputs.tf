output "private_ip_cluster1" {
  description = "List of private IP adresses related to our first instance"
  value       = module.cluster1.private_ip
}

output "private_ip_cluster2" {
  description = "List of private IP adresses related to our second instance"
  value       = module.cluster2.private_ip
}

output "public_ip_cluster1" {
  description = "List of public IP adresses related to our first instance"
  value       = module.cluster1.public_ip
}

output "public_ip_cluster2" {
  description = "List of public IP adresses related to our second instance"
  value       = module.cluster2.public_ip
}
