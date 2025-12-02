resource "aws_lb" "k3s_master_lb" {
  name               = "argocd-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [
    aws_subnet.k3s-public[0].id,
    aws_subnet.k3s-public[1].id
  ]

  tags = {
    Name        = "Argocd-NLB"
    Environment = "production"
    Project     = "Argocd"
    Role        = "nlb"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "k3s_master_argocd" {
  name        = "Argocd-tg"
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

  tags = {
    Name        = "k3s-argocd-tg"
    Environment = "production"
    Project     = "Argocd"
    Role        = "argocd-nodeport-tg"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "k3s_master_keycloak" {
  name        = "Keycloak-tg"
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

  tags = {
    Name        = "k3s-keycloak-tg"
    Environment = "production"
    Project     = "Argocd"
    Role        = "keycloak-nodeport-tg"
    ManagedBy   = "Terraform"
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

  tags = {
    Name        = "argocd-nlb-listener"
    Environment = "production"
    Project     = "Argocd"
    Role        = "argocd-listener"
    ManagedBy   = "Terraform"
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

  tags = {
    Name        = "keycloak-nlb-listener"
    Environment = "production"
    Project     = "Argocd"
    Role        = "keycloak-listener"
    ManagedBy   = "Terraform"
  }
}