resource "aws_launch_template" "k3s_master" {
  name_prefix   = "Argocd-master"
  image_id      = var.ami_ids
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.private_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 200
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "argocd-master"
      Environment = var.environment
      Role        = "k3s-master"
      ManagedBy   = "Terraform"
      Project     = "Argocd"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Install dependencies
    apt-get update -y && apt-get install -y curl wget git unzip ca-certificates

    # K3s symlink
    ln -s /usr/local/bin/k3s /usr/local/bin/kubectl

    # Install Helm
    wget https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz
    tar -zxvf helm-v3.17.0-linux-amd64.tar.gz
    mv linux-amd64/helm /usr/local/bin/
    rm -rf linux-amd64 helm-v3.17.0-linux-amd64.tar.gz

    # Install K3s Master
    curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
      --cluster-init \
      --disable=traefik \
      --datastore-endpoint="mysql://k3s_user:k3s_password@tcp(${aws_instance.k3s_database.private_ip}:3306)/k3s_db"

    sleep 30
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Install Argo CD
    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x argocd && mv argocd /usr/local/bin/

    kubectl create namespace ${var.argocd_namespace} || true

    git clone ${var.git_repo_url} /tmp/argocd
    cd /tmp/argocd/manifests/ha

    kubectl apply -n ${var.argocd_namespace} -f install.yaml
    kubectl create ns keycloak

    # Expose NodePort 31111
    kubectl patch svc argocd-server -n ${var.argocd_namespace} --type='merge' \
      -p='{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8080,"nodePort":31111}]}}'

    # Deploy Keycloak
    mkdir -p /tmp/keycloak-deploy
    git clone https://github.com/Anandreddy125/keycloak.git /tmp/keycloak-deploy
    kubectl apply -f /tmp/keycloak-deploy/

    kubectl patch svc keycloak -n keycloak --type='json' -p='[
      {"op": "replace", "path": "/spec/type", "value": "NodePort"},
      {"op": "replace", "path": "/spec/ports/0/port", "value": 80},
      {"op": "replace", "path": "/spec/ports/0/targetPort", "value": 8080},
      {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31126}
    ]'
  EOF
  )
}

resource "aws_autoscaling_group" "k3s_masters" {
  name_prefix         = "Argocd"
  vpc_zone_identifier = [for subnet in aws_subnet.k3s-private : subnet.id]

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  health_check_type = "EC2"

  launch_template {
    id      = aws_launch_template.k3s_master.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.k3s_master_argocd.arn,
    aws_lb_target_group.k3s_master_keycloak.arn
  ]

  tag {
    key                 = "Name"
    value               = "argocd-master"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "k3s-master"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "Argocd"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "scale_out_masters" {
  name                   = "scale-out-k3s-masters"
  autoscaling_group_name = aws_autoscaling_group.k3s_masters.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_in_masters" {
  name                   = "scale-in-k3s-masters"
  autoscaling_group_name = aws_autoscaling_group.k3s_masters.name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_masters" {
  alarm_name          = "cpu-high-k3s-masters"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 60

  alarm_actions = [aws_autoscaling_policy.scale_out_masters.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.k3s_masters.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_masters" {
  alarm_name          = "cpu-low-k3s-masters"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  alarm_actions = [aws_autoscaling_policy.scale_in_masters.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.k3s_masters.name
  }
}