
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
 
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "tf-sec-gr" {
  name        = "tf-provisioner-sg"
  description = "Security group for terraform provisioner"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "tf-provisioner-sg"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ubuntu"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "instance" {
  ami             = var.ec2_ami
  instance_type   = var.ec2_type
  key_name        = var.key_name
  security_groups = ["tf-provisioner-sg"]

 # Add this block to customize root volume
  root_block_device {
    volume_size = 100  # Size in GB
    volume_type = "gp3"
  }
  tags = {
    Name = "terraform-provisioner"
  }

  provisioner "local-exec" {
    command = "echo http://${self.public_ip} > public_ip.txt"
  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y && sudo apt-get install unzip jq docker.io -y",
      "sudo wget https://releases.hashicorp.com/terraform/1.10.4/terraform_1.10.4_linux_amd64.zip",
      "sudo unzip terraform_1.10.4_linux_amd64.zip && sudo mv terraform /usr/local/bin/",
      "sudo sleep 5 && terraform version",
      "sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl",
      "sudo curl -# -LO https://get.helm.sh/helm-v3.5.3-linux-amd64.tar.gz && sudo tar -xzvf helm-v3.5.3-linux-amd64.tar.gz",
      "sudo mv linux-amd64/helm /usr/local/bin/helm",
      "sudo helm version"
    ]
  }

  provisioner "file" {
   source      = "./modules/kind"
   destination = "/tmp/kind"
}
 
  provisioner "remote-exec" {
  inline = [
    "cd /tmp/kind",
    "sudo terraform init",
    "sudo terraform validate",
    "sudo terraform apply -var-file=template.tfvars -auto-approve",
    "sudo terraform state list"
  ]
}

  provisioner "file" {
    content     = self.public_ip
    destination = "/home/ubuntu/my_public_ip.txt"
  }
}



