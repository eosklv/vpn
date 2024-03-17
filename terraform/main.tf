terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "esklv-vpn"
    key    = "terraform/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "default" {
  id = var.default_vpc_id
}

resource "aws_instance" "vpn_server" {
  ami           = var.ami_id
  instance_type = "t4g.nano"

  key_name = "eugeny"

  root_block_device {
    volume_type = "gp3"
  }

  security_groups = ["allow_ssh"]

  tags = {
    Name = "vpn_server"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  for_each          = toset(var.my_ips)
  cidr_ipv4         = each.key
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

output "instance_public_ip" {
  description = "Public IP of the VPN server"
  value       = aws_instance.vpn_server.public_ip
}