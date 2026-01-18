variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "name_prefix" {
  type    = string
  default = "portfolio"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# AL2023에서 최소 30GB 요구 케이스가 있어 30 기본값
variable "root_volume_size" {
  type    = number
  default = 30
  validation {
    condition     = var.root_volume_size >= 30
    error_message = "root_volume_size must be >= 30 (AL2023 snapshot 최소 요구 대응)."
  }
}

variable "allocate_eip" {
  type    = bool
  default = true
}

# SSM(세션 매니저) 접속 - true
# Terraform 실행 IAM 계정에 IAM 관련 권한이 필요
variable "enable_ssm" {
  type    = bool
  default = true
}

# SSH 접속용 (옵션)
variable "key_name" {
  type    = string
  default = null
}

variable "ssh_ingress_cidr" {
  type    = string
  default = null
}

variable "app_repo_url" {
  type    = string
  default = ""
}

variable "app_repo_ref" {
  type    = string
  default = "main"
}

variable "tags" {
  type = map(string)
  default = {
    Project = "portfolio-k3s"
  }
}
