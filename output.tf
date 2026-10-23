

output "vpc_id" {
  value = aws_vpc.kind_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.kind_vpc.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "security_group_id" {
  value = aws_security_group.tf_sec_gr.id
}

output "instance_id" {
  value = aws_instance.instance.id
}

output "public_ip" {
  value = aws_instance.instance.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.instance.public_ip}"
}
