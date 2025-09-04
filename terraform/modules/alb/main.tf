resource "aws_lb" "alb" {
  name               = "${var.alb_name}"
  load_balancer_type = "application"
}