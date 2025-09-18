
module "instance" {
  count                  = var.instances_count
  source                 = "../ec2"
  instance_name          = "${var.cluster_name}-${format("%02d", count.index + 1)}"
  instance_type          = var.instance_type
  key_name               = var.key_name
  ami_id                 = var.ami_id
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
  user_data              = <<-EOF
#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3 python3-pip

pip3 install uv

ln -s /usr/local/bin/uv /usr/bin/uv || true

mkdir -p /home/ubuntu/app

echo "cluster_name=${var.cluster_name}" > /home/ubuntu/app/.env
echo "instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /home/ubuntu/app/.env

chown -R ubuntu:ubuntu /home/ubuntu/app
EOF


}
