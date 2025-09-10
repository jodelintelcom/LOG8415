output "instance_ids" {
  value = module.instance[*].id
}

output "private_ips" {
  value = module.instance[*].private_ip
}

output "public_ips" {
  value = module.instance[*].public_ip
}

output "instance_names" {
  value = [for i in range(var.instances_count) : "${var.cluster_name}-${format("%02d", i + 1)}" ]
}