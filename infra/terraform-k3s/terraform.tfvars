aws_region    = "ap-northeast-2"
name_prefix   = "portfolio"
instance_type = "t4g.small"

# 프리티어/과금 안정: 최소 30 유지
root_volume_size = 30

allocate_eip = true
enable_ssm   = true

# SSH 사용 시 변경 
# key_name         = null
# ssh_ingress_cidr = null

app_repo_url = "https://github.com/siyoung-devops/blockchain-gitops.git"
app_repo_ref = "main"

tags = {
  Project = "portfolio-k3s"
  Owner   = "siyoung"
}
