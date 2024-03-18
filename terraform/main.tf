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

data "aws_s3_bucket" "default" {
  bucket = var.default_bucket
}

resource "aws_instance" "vpn_server" {
  ami           = var.ami_id
  instance_type = "t4g.nano"

  key_name = "eugeny"

  user_data = <<EOF
#!/bin/bash
curl "${var.script_url}" -o /home/ubuntu/script.sh
chmod 700 /home/ubuntu/script.sh
/home/ubuntu/script.sh
EOF

  root_block_device {
    volume_type = "gp3"
  }

  security_groups = ["allow_connecting"]

  iam_instance_profile = aws_iam_instance_profile.esklv-vpnS3FullAccess.name

  tags = {
    Name = "vpn_server"
  }
}

resource "aws_security_group" "allow_connecting" {
  name        = "allow_connecting"
  description = "Allow SSH and HTTPS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "allow_connecting"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_connecting.id
  for_each          = toset(var.my_ips)
  cidr_ipv4         = each.key
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_udp_on_443_ipv4" {
  security_group_id = aws_security_group.allow_connecting.id
  for_each          = toset(var.my_ips)
  cidr_ipv4         = each.key
  from_port         = 443
  ip_protocol       = "udp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_connecting.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "esklv-vpnS3FullAccess" {
  name               = "esklv-vpnS3FullAccess"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
}

data "aws_iam_policy_document" "esklv-vpnS3FullAccess" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.default.arn]
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${data.aws_s3_bucket.default.bucket}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "esklv-vpnS3FullAccess" {
  name   = "esklv-vpnS3FullAccess"
  policy = data.aws_iam_policy_document.esklv-vpnS3FullAccess.json
}

resource "aws_iam_role_policy_attachment" "esklv-vpnS3FullAccess" {
  role       = aws_iam_role.esklv-vpnS3FullAccess.name
  policy_arn = aws_iam_policy.esklv-vpnS3FullAccess.arn
}

resource "aws_iam_instance_profile" "esklv-vpnS3FullAccess" {
  name = "esklv-vpnS3FullAccess"
  role = aws_iam_role.esklv-vpnS3FullAccess.name
}