variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  type        = list(string)
  description = "The list of CIDR block for the public subnet"
}
