
resource "aws_lb" "k3s_master_lb" {
  name               = "PNA-CDN-WAF-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [
    aws_subnet.k3s-public[0].id,
    aws_subnet.k3s-public[1].id
  ]
  tags = {
    Name = "PNA-CDN-WAF-NLB"
  }
}

resource "aws_lb_target_group" "k3s_master_argocd" {
  name        = "k3s-argocd-tg"
  port        = 31111
  protocol    = "TCP"
  vpc_id      = aws_vpc.k3s-vpc.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }
}

resource "aws_lb_target_group" "k3s_master_keycloak" {
  name        = "k3s-keycloak-tg"
  port        = 31126
  protocol    = "TCP"
  vpc_id      = aws_vpc.k3s-vpc.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }
}

resource "aws_lb_listener" "k3s_master_argocd" {
  load_balancer_arn = aws_lb.k3s_master_lb.arn
  port              = "31111"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_master_argocd.arn
  }
}

resource "aws_lb_listener" "k3s_master_keycloak" {
  load_balancer_arn = aws_lb.k3s_master_lb.arn
  port              = "31126"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_master_keycloak.arn
  }
}
