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
  default = "t3.micro" # Free Tier에 t3.micro가 포함되는 계정/기간이면 유리
}

variable "root_volume_gb" {
  type    = number
  default = 30
}

# SSH 키페어 이름(없으면 null) - SSM으로 접속 가능하면 SSH 없어도 됨
variable "key_name" {
  type    = string
  default = null
}

# 예: "1.2.3.4/32" (본인 공인IP/32). null이면 SSH 인바운드 rule 생성 안 함.
variable "ssh_ingress_cidr" {
  type    = string
  default = null
}

# EIP는 기본 OFF 권장 (필요할 때만 ON)
variable "allocate_eip" {
  type    = bool
  default = false
}

variable "attach_ecr_policy" {
  type    = bool
  default = false
}

# 앱 레포(bootstrap.sh가 있으면 실행, 없으면 스킵)
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
    Owner   = "unknown"
  }
}
