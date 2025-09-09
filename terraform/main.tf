module "vpc" {
  source     = "./modules/network"
  vpc_cidr   = "10.0.0.0/16"
  public_subnet_cidr = ["0.0.0.0/0"]
}

module "cluster1" {
  source          = "./modules/cluster"
  cluster_name    = "cluster1"
  instances_count = 2
  instance_type   = "t2.micro"
  ami_id          = "ami-0360c520857e3138f"
  key_name = "ssh_key"
}

module "cluster2" {
  source          = "./modules/cluster"
  cluster_name    = "cluster2"
  instances_count = 2
  instance_type   = "t2.micro"
  ami_id          = "ami-0360c520857e3138f"
  key_name = "ssh_key"
}

/*
module "alb" {
  source   = "./modules/alb"
  alb_name = "alb"
  vpc_id   = module.vpc.vpc_id
}
*/