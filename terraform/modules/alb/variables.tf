# Unused file, may be used in later labs

variable "alb_name" {
  type        = string
  description = "The name of the Application Load Balancer"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to deploy the ALB in"
}