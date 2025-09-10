variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "instances_count" {
  type        = number
  description = "The number of instances in the cluster"
  default     = 2
}

variable instance_type {
  type        = string
  description = "The type of the instances in the cluster"
  default     = "t2.micro"
}

variable "ami_id" {
  type        = string
  description = "AMI to use for the instances"
  default     = "ami-0360c520857e3138f" # Ubuntu 24.04 LTS us-east-1
}

variable "key_name" {
  description = "The name of the key pair to use for the instances"
  type        = string
}