# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = var.ami_ids
  instance_type          = var.Bastion_instance_type
  subnet_id              = aws_subnet.k3s-public[0].id
  key_name               = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name        = "bastion-host"
    Environment = "production"
    Role        = "bastion"
    ManagedBy   = "Terraform"
    Access      = "SSH"
  }

  provisioner "file" {
    source      = "${path.module}/${var.key_name}.pem"
    destination = "/tmp/terraform-key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }
}

# MySQL Server
resource "aws_instance" "k3s_database" {
  ami                    = var.ami_ids
  instance_type          = var.Bastion_instance_type
  key_name               = aws_key_pair.example.key_name
  subnet_id              = aws_subnet.k3s-private[0].id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    delete_on_termination = true
  }


  tags = {
    Name        = "mysql-argocd-backend"
    Environment = "production"
    Role        = "mysql"
    Cluster     = "k3s"
    ManagedBy   = "Terraform"
    Backup      = "Enabled"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y wget gnupg lsb-release",

      "wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb",
      "sudo DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.24-1_all.deb",
      "sudo apt-get update -y",

      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server",
      "mysql --version || echo 'MySQL installation failed'",

      "sudo sed -i 's/^bind-address\\s*=\\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf",
      "sudo systemctl restart mysql",

      "sudo mysql -e \"CREATE DATABASE k3s_db;\"",
      "sudo mysql -e \"CREATE USER 'k3s_user'@'%' IDENTIFIED BY 'k3s_password';\"",
      "sudo mysql -e \"GRANT ALL PRIVILEGES ON k3s_db.* TO 'k3s_user'@'%';\"",
      "sudo mysql -e \"FLUSH PRIVILEGES;\""
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.example.private_key_pem
      host        = self.private_ip

      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }
}
