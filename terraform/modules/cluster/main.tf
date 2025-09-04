module "instance" {
  count         = var.instances_count
  source        = "../ec2" # ajuste si besoin
  instance_name = "${var.cluster_name}-${format("%02d", count.index + 1)}"
  instance_type = var.instance_type
  ami_id        = var.ami_id
}
