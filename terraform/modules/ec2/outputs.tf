output "id" {
  description = "ID of instance created"
  value       = aws_instance.instance.id
}

output "public_ip" {
  description = "Public IP address related to the instance"
  value       = aws_instance.instance.public_ip
}

output "private_ip" {
  description = "Private IP address related to the instance"
  value       = aws_instance.instance.private_ip
}
