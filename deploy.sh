#!/bin/bash
set -e

# Global variables
SSH_KEY="$HOME/.ssh/lab1-8415.pem"
APP_DIR="/home/ubuntu/app"

MYSQL_USER="labuser"
MYSQL_PASS="labpass"

# Fetch IPs from Terraform
echo "Fetching IPs from Terraform..."

PROXY_IP=$(terraform -chdir=terraform output -raw proxy_public_ip)
GATEKEEPER_IP=$(terraform -chdir=terraform output -raw gatekeeper_public_ip)

CLUSTER_PUBLIC_IPS=$(terraform -chdir=terraform output -json cluster_public_ips)
CLUSTER_PRIVATE_IPS=$(terraform -chdir=terraform output -json cluster_private_ips)

MANAGER_SSH_IP=$(echo "$CLUSTER_PUBLIC_IPS" | jq -r '.[0]')
WORKER1_SSH_IP=$(echo "$CLUSTER_PUBLIC_IPS" | jq -r '.[1]')
WORKER2_SSH_IP=$(echo "$CLUSTER_PUBLIC_IPS" | jq -r '.[2]')

MANAGER_PRIVATE_IP=$(echo "$CLUSTER_PRIVATE_IPS" | jq -r '.[0]')
WORKER1_PRIVATE_IP=$(echo "$CLUSTER_PRIVATE_IPS" | jq -r '.[1]')
WORKER2_PRIVATE_IP=$(echo "$CLUSTER_PRIVATE_IPS" | jq -r '.[2]')

echo "Proxy IP      = $PROXY_IP"
echo "Gatekeeper IP = $GATEKEEPER_IP"
echo "Manager SSH   = $MANAGER_SSH_IP"
echo "Workers SSH   = $WORKER1_SSH_IP , $WORKER2_SSH_IP"

# Useful functions

wait_for_ssh() {
  local ip=$1
  echo "Waiting for SSH on $ip..."
  until ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" "echo ok" >/dev/null 2>&1; do
    sleep 3
  done
  echo "SSH READY : $ip"
}

wait_for_mysql() {
  local ip=$1
  echo "Waiting for MySQL on $ip..."
  until ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" "sudo mysql -e 'SELECT 1'" >/dev/null 2>&1; do
    sleep 3
  done
  echo "MySQL READY : $ip"
}

install_sakila() {
  local ip=$1
  echo "Installing Sakila DB on $ip"

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" <<EOF
set -e
cd /tmp

sudo apt install -y wget

wget -q https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xzf sakila-db.tar.gz

sudo mysql < sakila-db/sakila-schema.sql
sudo mysql < sakila-db/sakila-data.sql
EOF
}


install_mysql() {
  local ip=$1
  echo "Installing MySQL on $ip"

  wait_for_ssh "$ip"

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" <<EOF
set -e
export DEBIAN_FRONTEND=noninteractive

sudo apt update -y
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql
EOF

  wait_for_mysql "$ip"
}

# Configure MySQL instances

init_mysql_manager() {
  local ip=$1
  echo "Initializing MySQL manager on $ip"

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" <<EOF
set -e

sudo mysql <<SQL
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON sakila.* TO '${MYSQL_USER}'@'%';
GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

sudo sed -i '/server-id/d' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i '/log-bin/d' /etc/mysql/mysql.conf.d/mysqld.cnf

echo "server-id = 1" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
echo "log-bin = mysql-bin" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

sudo systemctl restart mysql
EOF

  wait_for_mysql "$ip"
}

init_mysql_worker() {
  local ip=$1
  local id=$2
  echo "Initializing MySQL worker $id on $ip"

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" <<EOF
set -e

sudo sed -i '/server-id/d' /etc/mysql/mysql.conf.d/mysqld.cnf
echo "server-id = $id" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

sudo systemctl restart mysql
EOF

  wait_for_mysql "$ip"
}

# Replication setup

get_master_status() {
  local ip=$1
  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" \
    "sudo mysql -N -e 'SHOW MASTER STATUS;'"
}

setup_replication_worker() {
  local worker_ssh=$1
  local master_private=$2
  local log_file=$3
  local log_pos=$4

  echo "Setting up replication on $worker_ssh"

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$worker_ssh" <<EOF
sudo mysql <<SQL
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='${master_private}',
  MASTER_USER='${MYSQL_USER}',
  MASTER_PASSWORD='${MYSQL_PASS}',
  MASTER_LOG_FILE='${log_file}',
  MASTER_LOG_POS=${log_pos};
START SLAVE;
SQL
EOF
}

create_benchmark_table() {
  local ip=$1
  echo "Creating benchmark table on $ip"

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" <<EOF
sudo mysql sakila <<SQL
CREATE TABLE IF NOT EXISTS cluster_benchmark (
  id INT AUTO_INCREMENT PRIMARY KEY,
  val INT
);
SQL
EOF
}

# Services deployment

install_uv() {
  local ip=$1

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" <<EOF
set -e
if [ ! -f /home/ubuntu/.local/bin/uv ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.bashrc
echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.profile
EOF
}

deploy_python_service() {
  local ip=$1
  local file=$2
  local port=$3

  wait_for_ssh "$ip"
  install_uv "$ip"

  ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" "mkdir -p $APP_DIR"
  scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$file" requirements.txt ubuntu@"$ip":"$APP_DIR/"

  ssh -T -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$ip" <<EOF
set -e
export PATH="\$HOME/.local/bin:\$PATH"

cd $APP_DIR
uv venv venv
uv pip install -r requirements.txt --python venv/bin/python
pkill -f uvicorn || true

nohup uv run --python venv/bin/python uvicorn \$(basename $file .py):app \
  --host 0.0.0.0 --port $port > server.log 2>&1 &
disown
EOF

  echo "Service deployed : http://$ip:$port"
}

# Execution flow

install_mysql "$MANAGER_SSH_IP"
install_mysql "$WORKER1_SSH_IP"
install_mysql "$WORKER2_SSH_IP"

install_sakila "$MANAGER_SSH_IP"

init_mysql_manager "$MANAGER_SSH_IP"
init_mysql_worker "$WORKER1_SSH_IP" 2
init_mysql_worker "$WORKER2_SSH_IP" 3

read LOG_FILE LOG_POS _ <<< "$(get_master_status "$MANAGER_SSH_IP")"

setup_replication_worker "$WORKER1_SSH_IP" "$MANAGER_PRIVATE_IP" "$LOG_FILE" "$LOG_POS"
setup_replication_worker "$WORKER2_SSH_IP" "$MANAGER_PRIVATE_IP" "$LOG_FILE" "$LOG_POS"

create_benchmark_table "$MANAGER_SSH_IP"

deploy_python_service "$PROXY_IP" proxy.py 8001
deploy_python_service "$GATEKEEPER_IP" gatekeeper.py 8000

echo " Proxy is running on:  http://$PROXY_IP:8001"
echo " Gatekeeper is running on: http://$GATEKEEPER_IP:8000"