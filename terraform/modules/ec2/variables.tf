variable "instance_type" {
  type        = string
  description = "The type of the instance"
  default     = "t2.micro"
}

variable "instance_name" {
  type        = string
  description = "The name to tag the instances with"
}

variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
  default     = "ami-0360c520857e3138f" # Ubuntu 24.04 LTS in us-east-1
}

variable "user_data" {
  description = "User data script for the instance"
  type        = string
  default     = ""
}

variable "key_name" {
  type        = string
  description = "The name of the key pair to use for the instances"
}

variable "subnet_id" {
  description = "The subnet ID for the instance"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate"
  type        = list(string)
  default     = []
}
