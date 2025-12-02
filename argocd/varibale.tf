variable "environment" {
  description = "Environment name (e.g., production, staging, dev)"
  type        = string
  default     = "production"
}

variable "AWS_REGION" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-east-2"
}

variable "ami_ids" {
  description = "EC2 AMI ID to be used for all servers"
  type        = string
  default     = "ami-0cfde0ea8edd312d4"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "Argocd-key"
}

variable "ssh_user" {
  description = "SSH username for EC2 instances"
  type        = string
  default     = "ubuntu"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_availability_zones" {
  description = "List of availability zones to deploy subnets"
  type        = list(string)
  default     = []
}

variable "sg_name" {
  description = "Default Security Group Name (for private SG)"
  type        = string
  default     = "Argocd-private-sg"
}

variable "Bastion_instance_type" {
  description = "Instance type for the Bastion Host"
  type        = string
  default     = "t2.micro"
}

variable "instance_type" {
  description = "Instance type for K3s Master/Worker nodes"
  type        = string
  default     = "t2.large"
}

variable "lb_name" {
  description = "Load Balancer Name"
  type        = string
  default     = "Argocd-nlb"
}

variable "target_group_name" {
  description = "Target Group Name for ArgoCD + Keycloak"
  type        = string
  default     = "argocd-tg-keycloak"
}

variable "health_check_interval" {
  description = "Time between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for each health check"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of successful checks to mark target healthy"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of failed checks to mark target unhealthy"
  type        = number
  default     = 2
}

variable "k3s_version" {
  description = "Version of K3s to install"
  type        = string
  default     = "v1.21.14+k3s1"
}

variable "k3s_service_port1" {
  description = "Main K3s service port"
  type        = number
  default     = 80
}

variable "k3s_service_port" {
  description = "K3s default NodePort service"
  type        = number
  default     = 31637
}

variable "k3s_api_port" {
  description = "K3s API server port"
  type        = number
  default     = 6443
}

variable "k3s_token" {
  description = "K3s token used for cluster authentication"
  type        = string
  default     = "your_default_k3s_token"
}

variable "shared_token" {
  description = "Shared secret used by K3s nodes"
  type        = string
  default     = "k3s-shared-token-example"
}

variable "init_flag" {
  description = "Initial master node flag (true for first master)"
  type        = string
  default     = "true"
}

variable "git_repo_url" {
  description = "Git repo URL containing ArgoCD manifests"
  type        = string
  default     = "https://github.com/argoproj/argo-cd.git"
}

variable "argocd_namespace" {
  description = "ArgoCD Kubernetes namespace"
  type        = string
  default     = "argocd"
}

variable "argocd_replicas" {
  description = "Replica count for ArgoCD deployments"
  type        = number
  default     = 2
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "Argocd"
    ManagedBy   = "Terraform"
    Owner       = "DevOps-Anand"
    Application = "K3s-ArgoCD-Keycloak"
  }
}