output "admin_sg_id" {
  value = aws_security_group.admin_sg.id
}

output "mysql_sg_id" {
  value = aws_security_group.mysql_sg.id
}

output "proxy_sg_id" {
  value = aws_security_group.proxy_app_sg.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}
