output "cluster1_public_ips" {
  description = "Public IPs of cluster1"
  value       = module.cluster1.public_ips
}

output "cluster2_public_ips" {
  description = "Public IPs of cluster2"
  value       = module.cluster2.public_ips
}
