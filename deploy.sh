#!/bin/bash
set -e

echo "Deplying infrastructure"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

echo "Getting clusters IPS"
CLUSTER1_IPS=$(terraform -chdir=terraform output -json cluster1_public_ips | jq -r '.[]')
CLUSTER2_IPS=$(terraform -chdir=terraform output -json cluster2_public_ips | jq -r '.[]')

echo "Deploying web server"
for ip in $CLUSTER1_IPS $CLUSTER2_IPS; do
  echo "Deploying to $ip"
  scp -i ~/.ssh/lab1-8415.pem -r web-server/* ubuntu@$ip:/home/ubuntu/app/
  echo "Starting web server on $ip"
  ssh -i ~/.ssh/lab1-8415.pem ubuntu@$ip "
    cd /home/ubuntu/app &&
    uv run uvicorn main:app --host 0.0.0.0 --port 8000 &"
done
