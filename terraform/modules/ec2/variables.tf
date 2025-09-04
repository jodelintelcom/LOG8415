variable "instance_type" {
  type        = string
  description = "The type of the instance"
  default     = "t2.micro"
}

variable "instance_name" {
  type = string
  description = "The name to tag the instances with"
}

variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
  default     = "ami-0360c520857e3138f" # Ubuntu 24.04 LTS in us-east-1
}