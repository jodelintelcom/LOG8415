variable "instance_type" {
  type        = string
  description = "The type of the instance"
  default     = "t2.micro"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The list of VPC subnet IDs"
  default     = []
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}
