module "instance" {
  count                  = var.instances_count
  source                 = "../ec2"
  instance_name          = "${var.cluster_name}-${format("%02d", count.index + 1)}"
  instance_type          = var.instance_type
  key_name               = var.key_name
  ami_id                 = var.ami_id
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id

  user_data = <<-EOF
#!/bin/bash
set -e

apt-get update -y
apt-get install -y mysql-server wget

wget https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xzf sakila-db.tar.gz
mysql < sakila-db/sakila-schema.sql
mysql < sakila-db/sakila-data.sql

sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl restart mysql

EOF
}
