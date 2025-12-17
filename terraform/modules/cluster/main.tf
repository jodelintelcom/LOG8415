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

INSTANCE_INDEX=${count.index}
INSTANCE_NAME="${var.cluster_name}-${format("%02d", count.index + 1)}"

echo "[mysqld]" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "server-id=$((INSTANCE_INDEX + 1))" >> /etc/mysql/mysql.conf.d/mysqld.cnf

if [ "$INSTANCE_INDEX" -eq 0 ]; then
  echo "log_bin=mysql-bin" >> /etc/mysql/mysql.conf.d/mysqld.cnf
  echo "binlog_do_db=sakila" >> /etc/mysql/mysql.conf.d/mysqld.cnf
fi

systemctl restart mysql
sleep 10

if [ "$INSTANCE_INDEX" -eq 0 ]; then
  mysql <<SQL
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;
SQL

else

  sleep 20

  MASTER_IP=$(getent hosts ${var.cluster_name}-01 | awk '{ print $1 }')

  mysql <<SQL
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_IP',
  MASTER_USER='repl',
  MASTER_PASSWORD='replpass',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=0;
START SLAVE;
SQL
fi
EOF

}
