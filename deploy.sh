#!/bin/bash
set -e

echo "Deplying infrastructure"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

echo "Getting clusters IPS"
CLUSTER1_IPS=$(terraform -chdir=terraform output -json cluster1_public_ips | jq -r '.[]')
CLUSTER2_IPS=$(terraform -chdir=terraform output -json cluster2_public_ips | jq -r '.[]')


wait_for_ssh() {
  local ip=$1
  local max_wait=180
  local waited=0
  echo "Waiting for SSH to be ready on $ip..."
  until ssh -o StrictHostKeyChecking=no -i ~/.ssh/lab1-8415.pem ubuntu@$ip "echo ok" 2>/dev/null; do
    sleep 5
    waited=$((waited+5))
    if [ $waited -ge $max_wait ]; then
      echo "Timeout: SSH is not ready on $ip after $max_wait seconds"
      return 1
    fi
  done
  echo "SSH is ready on $ip"
}

install_uv() {
  local ip=$1
  echo "Installing uv on $ip..."
  ssh -i ~/.ssh/lab1-8415.pem ubuntu@$ip 'bash -s' <<'EOF'
    set -e
    if [ ! -f /home/ubuntu/.local/bin/uv ]; then
      curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.profile
EOF
}

deploy_cluster() {
  local ips=$1
  local cname=$2
  for ip in $ips; do
    wait_for_ssh $ip
    install_uv $ip
    echo "Deploying to $ip ($cname)"
    scp -i ~/.ssh/lab1-8415.pem -r web-server/* ubuntu@$ip:/home/ubuntu/app/
    ssh -i ~/.ssh/lab1-8415.pem ubuntu@$ip "mkdir -p /home/ubuntu/.aws"
    scp -i ~/.ssh/lab1-8415.pem ~/.aws/credentials ubuntu@$ip:/home/ubuntu/.aws/credentials
    ssh -i ~/.ssh/lab1-8415.pem ubuntu@$ip 'bash -s' <<EOF
      set -e
      cd /home/ubuntu/app
      echo "cluster_name=$cname" > /home/ubuntu/app/.env
      TOKEN=\$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
      echo "instance_id=\$(curl -s -H "X-aws-ec2-metadata-token: \$TOKEN" \
        http://169.254.169.254/latest/meta-data/instance-id)" >> /home/ubuntu/app/.env
      export PATH="\$HOME/.local/bin:\$PATH"
      setsid /home/ubuntu/.local/bin/uv run uvicorn main:app --host 0.0.0.0 --port 8000 > server.log 2>&1 &
      disown
EOF
  done
}

deploy_lb() {
  local lb_ip=$(terraform -chdir=terraform output -raw custom_lb_public_ip)

  wait_for_ssh $lb_ip

  echo "Deploying the load balancer to $lb_ip..."

  cat > lb.env <<EOF
  cluster1_urls=$(for ip in $CLUSTER1_IPS; do echo -n "http://$ip:8000,"; done | sed 's/,$//')
  cluster2_urls=$(for ip in $CLUSTER2_IPS; do echo -n "http://$ip:8000,"; done | sed 's/,$//')
EOF

  ssh -i ~/.ssh/lab1-8415.pem ubuntu@$lb_ip 'bash -s' <<'EOF'
    set -e
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip curl

    echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/ubuntu/.bashrc
    echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/ubuntu/.profile

    mkdir -p /home/ubuntu/app
    chown -R ubuntu:ubuntu /home/ubuntu/app
EOF
  install_uv $lb_ip
  scp -i ~/.ssh/lab1-8415.pem -r custom-load-balancer/* ubuntu@$lb_ip:/home/ubuntu/app/
  scp -i ~/.ssh/lab1-8415.pem lb.env ubuntu@$lb_ip:/home/ubuntu/app/.env
  ssh -i ~/.ssh/lab1-8415.pem ubuntu@$lb_ip "mkdir -p /home/ubuntu/.aws"
  scp -i ~/.ssh/lab1-8415.pem ~/.aws/credentials ubuntu@$lb_ip:/home/ubuntu/.aws/credentials
  ssh -i ~/.ssh/lab1-8415.pem ubuntu@$lb_ip "chmod 600 /home/ubuntu/.aws/credentials"


  ssh -i ~/.ssh/lab1-8415.pem ubuntu@$lb_ip 'bash -s' <<'EOF'
    set -e
    cd /home/ubuntu/app
    /home/ubuntu/.local/bin/uv add boto3 fastapi uvicorn requests
    export PATH="$HOME/.local/bin:$PATH"
    pkill -f "uvicorn" || true
    setsid /home/ubuntu/.local/bin/uv run uvicorn main:app --host 0.0.0.0 --port 8080 > lb.log 2>&1 &
    disown
EOF

  echo "Load balancer deployed to $lb_ip"
}


deploy_cluster "$CLUSTER1_IPS" "cluster1"
deploy_cluster "$CLUSTER2_IPS" "cluster2"
deploy_lb

LB_IP=$(terraform -chdir=terraform output -raw custom_lb_public_ip)
echo "Load Balancer IP: $LB_IP"

echo "Waiting for 20 seconds to run the benchmark"
sleep 20

LB_IP=http://$LB_IP:8080 python3 benchmark.py
