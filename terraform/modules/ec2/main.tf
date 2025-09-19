resource "aws_instance" "instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = var.user_data
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }
  tags = {
    Name = "${var.instance_name}"
  }
}
