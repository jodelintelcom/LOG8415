output "ids" {
  description = "List of IDs of instances created"
  value       = aws_instance.this.*.id
}

output "public_ip" {
  description = "List of public IP adresses related to our instances"
  value       = aws_instance.this.*.public_ip
}

output "private_ip" {
  description = "List of private IP adresses related to our instances"
  value       = aws_instance.this.*.private_ip
}
