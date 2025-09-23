output "cluster1_public_ips" {
  description = "Public IPs of cluster1"
  value       = module.cluster1.public_ips
}

output "cluster2_public_ips" {
  description = "Public IPs of cluster2"
  value       = module.cluster2.public_ips
}

output "custom_lb_public_ip" {
  description = "Public IP of the custom load balancer"
  value       = module.custom_lb.public_ip
}
