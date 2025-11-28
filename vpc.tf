# Provider Configuration
provider "aws" {
  region = var.AWS_REGION
}

# Fetch available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Generate a private key for SSH access
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "example" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
}

# Create VPC
resource "aws_vpc" "k3s-vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "k3s-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k3s-igw" {
  vpc_id = aws_vpc.k3s-vpc.id

  tags = {
    Name = "k3s-igw"
  }
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "net-eip" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_eip" "net-eip1" {
  tags = {
    Name = "nat-eip1"
  }
}

# Create public subnets (2)
resource "aws_subnet" "k3s-public" {
  count                   = 2
  vpc_id                  = aws_vpc.k3s-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-public-${count.index + 1}"
  }
}

# Create private subnets (2)
resource "aws_subnet" "k3s-private" {
  count                   = 2
  vpc_id                  = aws_vpc.k3s-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 3)
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "k3s-private-${count.index + 1}"
  }
}

# NAT Gateway 1
resource "aws_nat_gateway" "k3s-nat" {
  allocation_id = aws_eip.net-eip.id
  subnet_id     = aws_subnet.k3s-public[0].id

  tags = {
    Name = "k3s-nat"
  }
}

# NAT Gateway 2
resource "aws_nat_gateway" "k3s-nat1" {
  allocation_id = aws_eip.net-eip1.id
  subnet_id     = aws_subnet.k3s-public[1].id

  tags = {
    Name = "k3s-nat1"
  }
}

# Public Route Table
resource "aws_route_table" "k3s-rt-public" {
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s-igw.id
  }

  tags = {
    Name = "pub-route-table"
  }
}

# Private Route Table
resource "aws_route_table" "k3s-rt-private" {
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.k3s-nat.id
  }

  tags = {
    Name = "pvt-route-table"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.k3s-public[count.index].id
  route_table_id = aws_route_table.k3s-rt-public.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.k3s-private[count.index].id
  route_table_id = aws_route_table.k3s-rt-private.id
}
