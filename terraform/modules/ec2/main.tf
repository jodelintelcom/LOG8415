resource "aws_instance" "instance" {
  ami           = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install python3 python3-pip -y

    pip3 install uv

    mkdir -p /home/ec2-user/app

    echo "cluster_name=${var.instance_name}" > /home/ec2-user/app/.env
    echo "instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /home/ec2-user/app/.env
  EOF
  tags = {
    Name = "${var.instance_name}"
  }
}
