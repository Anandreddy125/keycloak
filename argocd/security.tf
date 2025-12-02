resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access to the bastion host"
  vpc_id      = aws_vpc.k3s-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL access inside VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Argocd-bastion-sg"
    Environment = "production"
    Role        = "bastion-sg"
    ManagedBy   = "Terraform"
    Project     = "Argocd"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow private communication within the VPC"
  vpc_id      = aws_vpc.k3s-vpc.id

  ingress {
    description = "Allow all traffic within this security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Allow all traffic within the VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description     = "Allow SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ArgoCD (31111) only from Zscaler"
    from_port   = 31111
    to_port     = 31111
    protocol    = "tcp"
    cidr_blocks = ["13.203.17.245/32"]
  }

  ingress {
    description = "Allow Keycloak (31126) only from Zscaler"
    from_port   = 31126
    to_port     = 31126
    protocol    = "tcp"
    cidr_blocks = ["13.203.17.245/32"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s API traffic internal"
    from_port   = var.k3s_api_port
    to_port     = var.k3s_api_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "K3s node communication"
    from_port   = 10250
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "ETCD internal communication"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description     = "Allow Load Balancer to nodes"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Argocd-private-sg"
    Environment = "production"
    Role        = "k3s-master-sg"
    ManagedBy   = "Terraform"
    Project     = "Argocd"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.k3s-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Argocd-nlb-sg"
    Environment = "production"
    Role        = "loadbalancer-sg"
    ManagedBy   = "Terraform"
    Project     = "Argocd"
  }
}