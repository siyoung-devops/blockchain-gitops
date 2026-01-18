terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Default VPC/Subnets (간단/프리티어 friendly) ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Group ---
resource "aws_security_group" "k3s_sg" {
  name        = "${var.name_prefix}-k3s-sg"
  description = "k3s single node security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS는 ingress-nginx 쓰면 443도 열어두는게 일반적
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH는 옵션 (SSM 쓰면 안 열어도 됨)
  dynamic "ingress" {
    for_each = var.ssh_ingress_cidr == null ? [] : [1]
    content {
      description = "SSH (restricted)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_ingress_cidr]
    }
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# --- IAM (SSM) Optional ---
resource "aws_iam_role" "ec2_role" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.name_prefix}-ec2-profile"
  role  = aws_iam_role.ec2_role[0].name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- Amazon Linux 2023 최신 AMI ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "k3s" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  iam_instance_profile   = var.enable_ssm ? aws_iam_instance_profile.ec2_profile[0].name : null
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data.sh", {
    app_repo_url = var.app_repo_url
    app_repo_ref = var.app_repo_ref
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-k3s"
  })
}


resource "aws_eip" "k3s" {
  count    = var.allocate_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.k3s.id
  tags     = var.tags
}
