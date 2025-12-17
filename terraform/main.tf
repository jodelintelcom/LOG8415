module "network" {
  source = "./modules/network"
}

module "clusterMySql" {
  source                 = "./modules/cluster"
  cluster_name           = "clusterMySql"
  instances_count        = 3
  instance_type          = "t2.micro"
  ami_id                 = "ami-0360c520857e3138f"
  key_name               = "lab1-8415"
  subnet_id              = module.network.subnet_id
  vpc_security_group_ids = [module.network.security_group_id]
}

module "proxy" {
  source                 = "./modules/ec2"
  instance_name          = "proxy"
  instance_type          = "t2.large"
  ami_id                 = "ami-0360c520857e3138f"
  key_name               = "lab1-8415"
  subnet_id              = module.network.subnet_id
  vpc_security_group_ids = [module.network.security_group_id]

  user_data = <<-EOF
#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3 python3-venv curl

curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH=/home/ubuntu/.local/bin:$PATH

echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/ubuntu/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/ubuntu/.profile

mkdir -p /opt/app
chown ubuntu:ubuntu /opt/app

uv pip install --system fastapi uvicorn requests pymysql

EOF
}


module "gatekeeper" {
  source                 = "./modules/ec2"
  instance_name          = "gatekeeper"
  instance_type          = "t2.large"
  ami_id                 = "ami-0360c520857e3138f"
  key_name               = "lab1-8415"
  subnet_id              = module.network.subnet_id
  vpc_security_group_ids = [module.network.security_group_id]

  user_data = <<-EOF
#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3 python3-venv curl

curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH=/home/ubuntu/.local/bin:$PATH

echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/ubuntu/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/ubuntu/.profile

mkdir -p /opt/app
chown ubuntu:ubuntu /opt/app

uv pip install --system fastapi uvicorn requests
EOF
}

