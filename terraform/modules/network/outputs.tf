output "vpc_id" {
  description = "The ID of our VPC"
  value       = aws_vpc.main.id
}

/*
output "subnet_ids" {
  description = "The list of IDs of our public subnets"
  value       = aws_subnet.public[*].id
}
*/