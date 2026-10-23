
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "key_name" {
  default = "ubuntu"
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.20.1.0/24"
}

variable "ec2_ami" {
  description = "Ubuntu AMI ID in the selected region"
  type        = string
  default     = "ami-0345dd2cef523536e"
}

variable "ec2_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "ssh_allowed_cidr" {
  description = "Your public IPv4 address in CIDR notation"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition = (
      can(cidrnetmask(var.ssh_allowed_cidr)) &&
      endswith(var.ssh_allowed_cidr, "/32")
    )
    error_message = "Provide a valid IPv4 address with a /32 mask."
  }
}



