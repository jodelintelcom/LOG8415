# Unused file, may be used in later labs

resource "aws_lb" "alb" {
  name               = "${var.alb_name}"
  load_balancer_type = "application"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "tg_cluster1" {
  name     = "tg-cluster1"
  vpc_id   = var.vpc_id
  port     = 8000
  protocol = "HTTP"
}

resource "aws_lb_target_group" "tg_cluster2" {
  name     = "tg-cluster2"
  vpc_id   = var.vpc_id
  port     = 8000
  protocol = "HTTP"
}

resource "aws_lb_listener_rule" "rule_cluster1" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_cluster1.arn
  }
  condition {
    path_pattern {
      values = ["/cluster1"]
    }
  }
}

resource "aws_lb_listener_rule" "rule_cluster2" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_cluster2.arn
  }
  condition {
    path_pattern {
      values = ["/cluster2"]
    }
  }
}