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
apt-get install -y mysql-server wget openssh-client

wget https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xzf sakila-db.tar.gz
mysql < sakila-db/sakila-schema.sql
mysql < sakila-db/sakila-data.sql

INSTANCE_INDEX=${count.index}

cat <<MYSQLCFG >> /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
server-id=$((INSTANCE_INDEX + 1))
bind-address=0.0.0.0
MYSQLCFG

if [ "$INSTANCE_INDEX" -eq 0 ]; then
  cat <<MYSQLCFG >> /etc/mysql/mysql.conf.d/mysqld.cnf
log_bin=mysql-bin
binlog_do_db=sakila
MYSQLCFG
fi

systemctl restart mysql
sleep 10

if [ "$INSTANCE_INDEX" -eq 0 ]; then

  mysql <<'SQL'
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
SQL

  mysql -e "SHOW MASTER STATUS\G" > /tmp/master_status.txt
  awk '/File:/ {print $2}' /tmp/master_status.txt > /tmp/master_file
  awk '/Position:/ {print $2}' /tmp/master_status.txt > /tmp/master_pos


  mysql -e "UNLOCK TABLES;"

else

  sleep 30

  MASTER_IP=$(getent hosts ${var.cluster_name}-01 | awk '{ print $1 }')

  mysql -e "SHOW MASTER STATUS\G" > /tmp/master_status.txt
  MASTER_FILE=$(awk '/File:/ {print $2}' /tmp/master_status.txt)
  MASTER_POS=$(awk '/Position:/ {print $2}' /tmp/master_status.txt)

  mysql <<SQL
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_IP',
  MASTER_USER='repl',
  MASTER_PASSWORD='replpass',
  MASTER_LOG_FILE='$MASTER_FILE',
  MASTER_LOG_POS=$MASTER_POS;
START SLAVE;
SQL

fi
EOF
}
