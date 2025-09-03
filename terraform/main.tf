terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.15.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

module "cluster1" {
  source         = "./modules/ec2"
  cluster_name   = "cluster1"
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.subnet_ids
  instance_count = 5
  instance_type  = "t2.micro"
}

module "cluster2" {
  source         = "./modules/ec2"
  cluster_name   = "cluster2"
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.subnet_ids
  instance_count = 4
  instance_type  = "t2.large"
}

module "network" {
  source             = "./modules/network"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "172.16.0.0/16"
}
