module "cluster1" {
  source          = "./modules/cluster"
  cluster_name    = "cluster1"
  instances_count = 2
  instance_type   = "t2.micro"
  ami_id          = "ami-0360c520857e3138f"
}