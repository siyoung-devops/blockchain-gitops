aws_region    = "ap-northeast-2"
name_prefix   = "portfolio"
instance_type = "t3.micro"

# 추후 SSH 열 때 변경
ssh_ingress_cidr = null
key_name         = null

# ✅ 과금 방지 - false 
allocate_eip = false

app_repo_url = "https://github.com/siyoung-devops/blockchain-gitops.git"
app_repo_ref = "main"

tags = {
  Project = "portfolio-k3s"
  Owner   = "siyoung"
}
