provider "aws" {
  region = var.AWS_REGION
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "example" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh

  tags = {
    Name        = var.key_name
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
}

resource "aws_vpc" "k3s-vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name        = "Argocd-vpc"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_internet_gateway" "k3s-igw" {
  vpc_id = aws_vpc.k3s-vpc.id

  tags = {
    Name        = "Argocd-igw"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_eip" "net-eip" {
  tags = {
    Name        = "Argocd-eip"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_subnet" "k3s-public" {
  count                   = 2
  vpc_id                  = aws_vpc.k3s-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "Argocd-public-${count.index + 1}"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_subnet" "k3s-private" {
  count                   = 2
  vpc_id                  = aws_vpc.k3s-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 3)
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "Argocd-private-${count.index + 1}"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_nat_gateway" "k3s-nat" {
  allocation_id = aws_eip.net-eip.id
  subnet_id     = aws_subnet.k3s-public[0].id

  tags = {
    Name        = "Argocd-nat"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_route_table" "k3s-rt-public" {
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s-igw.id
  }

  tags = {
    Name        = "Argocd-route-table"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_route_table" "k3s-rt-private" {
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.k3s-nat.id
  }

  tags = {
    Name        = "Argocd-route-table"
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Module      = "networking"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.k3s-public[count.index].id
  route_table_id = aws_route_table.k3s-rt-public.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.k3s-private[count.index].id
  route_table_id = aws_route_table.k3s-rt-private.id
}