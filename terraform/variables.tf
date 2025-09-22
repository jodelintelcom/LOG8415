# Leave this variable as it is, since our AWS Lab account is only in us-east-1
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

# Change the name of the profile if you want to use a different one than "default"
variable "aws_profile" {
  description = "The AWS CLI profile to use"
  type        = string
  default     = "default"
}

