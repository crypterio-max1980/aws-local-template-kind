

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# --------------------------------------------------
# 1. Create a new VPC
# --------------------------------------------------

resource "aws_vpc" "kind_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "terraform-provisioner-vpc"
    Environment = var.environment
  }
}

# --------------------------------------------------
# 2. Public subnet
# --------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.kind_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-provisioner-public-subnet"
  }
}

# --------------------------------------------------
# 3. Internet Gateway
# --------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.kind_vpc.id

  tags = {
    Name = "terraform-provisioner-igw"
  }
}

# --------------------------------------------------
# 4. Public route table
# --------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.kind_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "terraform-provisioner-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --------------------------------------------------
# 5. SSH key pair
# --------------------------------------------------

resource "aws_key_pair" "generated_key" {
  key_name   = "ubuntu"
  public_key = file(pathexpand("~/.ssh/id_rsa.pub"))

  tags = {
    Name = "terraform-provisioner-key"
  }
}

# --------------------------------------------------
# 6. Security group in the new VPC
# --------------------------------------------------

resource "aws_security_group" "tf_sec_gr" {
  name        = "tf-provisioner-sg"
  description = "Security group for Terraform and Kind EC2"
  vpc_id      = aws_vpc.kind_vpc.id

  ingress {
    description = "SSH from approved public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "tf-provisioner-sg"
    Environment = var.environment
  }
}

# --------------------------------------------------
# 7. EC2 instance
# --------------------------------------------------

resource "aws_instance" "instance" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.tf_sec_gr.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name

  root_block_device {
    volume_size           = 100
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name        = "terraform-provisioner"
    Environment = var.environment
  }

  # Save public IP locally
  provisioner "local-exec" {
    command = "echo http://${self.public_ip} > ${path.module}/public_ip.txt"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
    timeout     = "10m"
  }

  # ------------------------------------------------
  # 8. Install Terraform, Docker, kubectl and Helm
  # ------------------------------------------------

  provisioner "remote-exec" {
    inline = [
      "set -eu",
      "sudo apt-get update -y",
      "sudo apt-get install -y unzip jq curl ca-certificates docker.io",
      "sudo systemctl enable --now docker",
      "sudo usermod -aG docker ubuntu",

      # Terraform 1.10.4
      "cd /tmp",
      "curl -fsSLo terraform.zip https://releases.hashicorp.com/terraform/1.10.4/terraform_1.10.4_linux_amd64.zip",
      "unzip -o terraform.zip",
      "sudo install -m 0755 terraform /usr/local/bin/terraform",
      "rm -f terraform.zip terraform",
      "terraform version",

      # Install kubectl
      "KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)",
      "curl -fsSLo kubectl https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl",
      "sudo install -m 0755 kubectl /usr/local/bin/kubectl",
      "rm -f kubectl",
      "kubectl version --client",

      # Helm v3.17.3
      "curl -fsSLo helm.tar.gz https://get.helm.sh/helm-v3.17.3-linux-amd64.tar.gz",
      "tar -xzf helm.tar.gz",
      "sudo install -m 0755 linux-amd64/helm /usr/local/bin/helm",
      "rm -rf helm.tar.gz linux-amd64",
      "helm version"
    ]
  }

  # ------------------------------------------------
  # 9. Upload Kind Terraform module
  # ------------------------------------------------

  provisioner "file" {
    source      = "${path.module}/modules/kind"
    destination = "/tmp/kind"
  }

  # ------------------------------------------------
  # 10. Run the Kind Terraform configuration
  # ------------------------------------------------

  provisioner "remote-exec" {
    inline = [
      "set -eu",
      "test -d /tmp/kind",
      "test -f /tmp/kind/template.tfvars",
      "cd /tmp/kind && terraform init",
      "cd /tmp/kind && terraform validate",
      "cd /tmp/kind && terraform apply -var-file=template.tfvars -auto-approve",
      "cd /tmp/kind && terraform state list"
    ]
  }

  # Save public IP on EC2
  provisioner "file" {
    content     = self.public_ip
    destination = "/home/ubuntu/my_public_ip.txt"
  }
}
