#!/bin/bash
set -e

SSH_KEY="$HOME/.ssh/lab1-8415.pem"
APP_DIR="/home/ubuntu/app"

echo "Fetching IPs from Terraform..."
PROXY_IP=$(terraform -chdir=terraform output -raw proxy_public_ip)
GATEKEEPER_IP=$(terraform -chdir=terraform output -raw gatekeeper_public_ip)

echo "Proxy IP = $PROXY_IP"
echo "Gatekeeper IP = $GATEKEEPER_IP"


wait_for_ssh() {
  local ip=$1
  echo "Waiting for SSH on $ip..."
  until ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$ip "echo ok" 2>/dev/null; do
    sleep 3
  done
  echo "SSH READY → $ip"
}

install_uv() {
  local ip=$1
  echo "Installing UV on $ip..."

  ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$ip 'bash -s' <<'EOF'
set -e
if [ ! -f /home/ubuntu/.local/bin/uv ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.profile
EOF
}


deploy_python_service() {
  local ip=$1
  local file=$2
  local port=$3

  wait_for_ssh $ip
  install_uv $ip

  ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$ip "mkdir -p $APP_DIR"

  scp -o StrictHostKeyChecking=no -i $SSH_KEY $file requirements.txt ubuntu@$ip:$APP_DIR/

  ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$ip 'bash -s' <<EOF
set -e
export PATH="\$HOME/.local/bin:\$PATH"

cd $APP_DIR

uv venv venv
uv pip install -r requirements.txt --python venv/bin/python
pkill -f uvicorn || true

nohup uv run --python venv/bin/python uvicorn $(basename $file .py):app \
  --host 0.0.0.0 --port $port > server.log 2>&1 &

disown
EOF

  echo "Service deployed → http://$ip:$port"
}


deploy_python_service $PROXY_IP proxy.py 8001
deploy_python_service $GATEKEEPER_IP gatekeeper.py 8000
echo "Proxy Url: http://$PROXY_IP:8001"
echo "Gatekeeper → http://$GATEKEEPER_IP:8000"
