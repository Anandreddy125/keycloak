terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }
}

# --- AWS & Global Config ---

#variable "AWS_REGION" {
 # description = "us-east-2"
 # type        = string
#}

variable "AWS_REGION" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "ami_ids" {
  description = "Map of AMI IDs for different regions"
  type        = string
   default = "ami-0cfde0ea8edd312d4"
  }

variable "key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = "terraform-key"
}

variable "ssh_user" {
  description = "SSH user for EC2"
  type        = string
  default     = "ubuntu"
}

variable "vpc_availability_zones" {
  type        = list(string)
  description = "Availability Zones"
  default     = []
}
# --- VPC and Network ---

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}


variable "sg_name" {
  description = "Name of the security group"
  type        = string
  default     = "private-sg"
}

# --- Instance Types ---

variable "Bastion_instance_type" {
  type        = string
  default     = "t2.micro"
}

variable "instance_type" {
  type        = string
  default     = "t2.large"
}


# --- Load Balancer and Target Group ---

variable "lb_name" {
  description = "Load Balancer Name"
  type        = string
  default     = "argocd-lb"
}

variable "target_group_name" {
  description = "Target Group Name"
  type        = string
  default     = "argocd-tg&keycloak"

}

# --- Health Check Configuration ---

variable "health_check_interval" {
  type    = number
  default = 30
}

variable "health_check_timeout" {
  type    = number
  default = 5
}

variable "healthy_threshold" {
  type    = number
  default = 2
}

variable "unhealthy_threshold" {
  type    = number
  default = 2
}

# --- K3s Config ---

variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "v1.21.14+k3s1"
}

variable "k3s_service_port1" {
  type    = number
  default = 80
}

variable "k3s_service_port" {
  type    = number
  default = 31637
}

variable "k3s_api_port" {
  type    = number
  default = 6443
}

variable "k3s_token" {
  description = "The K3s token for worker nodes to join the cluster"
  type        = string
  default     = "your_default_k3s_token"
}

variable "shared_token" {
  description = "Shared secret token used by K3s nodes"
  type        = string
  default     = "k3s-shared-token-example"
}

variable "init_flag" {
  description = "Set to true for the first master node to initialize the cluster"
  type        = string
  default     = "true"
}



# --- GitHub & Jenkins Integration ---


variable "git_repo_url" {
  description = "Git repo for Argo CD manifests or apps"
  default     = "https://github.com/argoproj/argo-cd.git"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  default     = "argocd"
}

variable "argocd_replicas" {
  description = "Number of replicas for Argo CD components (server, repo, controller, dex)"
  type        = number
  default     = 2
}
