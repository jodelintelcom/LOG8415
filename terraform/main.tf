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
  source         = "./modules/cluster"
  cluster_name   = "cluster1"
  subnet_ids     = module.network.subnet_ids
  instance_count = 5
  instance_type  = "t2.micro"
}

module "cluster2" {
  source         = "./modules/cluster"
  cluster_name   = "cluster2"
  subnet_ids     = module.network.subnet_ids
  instance_count = 4
  instance_type  = "t2.large"
}
