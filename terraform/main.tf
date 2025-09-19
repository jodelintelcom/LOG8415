

module "network" {
  source = "./modules/network"
}

module "cluster1" {
  source                 = "./modules/cluster"
  cluster_name           = "cluster1"
  instances_count        = 2
  instance_type          = "t2.micro"
  ami_id                 = "ami-0360c520857e3138f"
  key_name               = "lab1-8415"
  subnet_id              = module.network.subnet_id
  vpc_security_group_ids = [module.network.security_group_id]
}

module "cluster2" {
  source                 = "./modules/cluster"
  cluster_name           = "cluster2"
  instances_count        = 2
  instance_type          = "t2.micro"
  ami_id                 = "ami-0360c520857e3138f"
  key_name               = "lab1-8415"
  subnet_id              = module.network.subnet_id
  vpc_security_group_ids = [module.network.security_group_id]
}

module "custom_lb" {
  source                 = "./modules/ec2"
  instance_name          = "custom-lb"
  instance_type          = "t2.micro"
  ami_id                 = "ami-0360c520857e3138f"
  key_name               = "lab1-8415"
  subnet_id              = module.network.subnet_id
  vpc_security_group_ids = [module.network.security_group_id]
}
