#!/bin/bash
set -e

echo "Deplying infrastructure"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

echo "Getting clusters IPS"
CLUSTER1_IPS=$(terraform -chdir=terraform output -json cluster1.public_ips | jq -r '.[]')
CLUSTER2_IPS=$(terraform -chdir=terraform output -json cluster2.public_ips | jq -r '.[]')

echo "Deploying web server"
for ip in $CLUSTER1_IPS $CLUSTER2_IPS; do
  scp -i ~/.ssh/mykey.pem -r web-server/* ec2-user@$ip:/home/ec2-user/app/
  ssh -i ~/.ssh/mykey.pem ec2-user@$ip "
    cd /home/ec2-user/app &&
    uv run uvicorn main:app --host 0.0.0.0 --port 8000 &"
done
