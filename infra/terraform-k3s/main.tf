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

# --- Default VPC/Subnet (free-tier friendly) ---
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

  # 필요 시만 열도록 권장 (기본은 열어도 되지만, 서비스가 HTTPS 실제 사용 안 하면 닫아도 됨)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# --- IAM (SSM 사용 가능하게) ---
resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# (선택) ECR pull/push 필요하면 true
resource "aws_iam_role_policy_attachment" "ecr" {
  count      = var.attach_ecr_policy ? 1 : 0
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# --- Latest Amazon Linux 2023 AMI ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

# --- EC2 ---
resource "aws_instance" "k3s" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name

  # Free-tier를 고려해 루트 볼륨을 20GB로(기본은 30GB인 경우가 많음)
  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  # ✅ templatefile() 제거 + user_data.sh 유지
  # 1) Terraform 변수는 config.env에만 주입
  # 2) 실제 로직은 user_data.sh가 수행 (file()로 그대로 붙임)
  user_data = join("\n", [
    <<-BOOT
    #!/bin/bash
    set -euo pipefail
    mkdir -p /opt/bootstrap

    cat >/opt/bootstrap/config.env <<'ENV'
    APP_REPO_URL="${var.app_repo_url}"
    APP_REPO_REF="${var.app_repo_ref}"
    ENV

    chmod 0644 /opt/bootstrap/config.env
    BOOT
    ,
    file("${path.module}/user_data.sh")
  ])

  user_data_replace_on_change = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-k3s"
  })
}

# (선택) Elastic IP: 안정적인 주소 원하면 true
# 단, EIP는 "할당만 하고 인스턴스에 연결이 안 된 상태"로 남아있으면 과금될 수 있습니다.
resource "aws_eip" "k3s" {
  count    = var.allocate_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.k3s.id
  tags     = var.tags
}
