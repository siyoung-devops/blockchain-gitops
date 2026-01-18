#!/bin/bash
set -euo pipefail

LOG=/var/log/portfolio-user-data.log
exec > >(tee -a "$LOG") 2>&1

echo "[INFO] user-data start: $(date -Is)"

retry() {
  local n=0
  local max=10
  local delay=5
  while true; do
    "$@" && break
    n=$((n+1))
    if [ "$n" -ge "$max" ]; then
      echo "[ERROR] failed after $max attempts: $*"
      return 1
    fi
    echo "[WARN] retry $n/$max after ${delay}s: $*"
    sleep "$delay"
    delay=$((delay*2))
  done
}

# ---- packages (AL2023에서 충돌 대비 allowerasing) ----
retry dnf -y update --allowerasing
retry dnf -y install git jq bash-completion ca-certificates --allowerasing
if ! command -v curl >/dev/null 2>&1; then
  retry dnf -y install curl --allowerasing
fi

# ---- k3s config ----
mkdir -p /etc/rancher/k3s
cat >/etc/rancher/k3s/config.yaml <<'YAML'
write-kubeconfig-mode: "0644"
disable:
  - traefik
YAML

# ---- install k3s ----
if ! command -v k3s >/dev/null 2>&1; then
  echo "[INFO] installing k3s..."
  retry sh -c 'curl -sfL https://get.k3s.io | sh -'
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "[INFO] waiting for k3s api..."
retry k3s kubectl version --short

echo "[INFO] waiting for node Ready..."
retry k3s kubectl wait --for=condition=Ready node --all --timeout=300s

# ---- helm ----
if ! command -v helm >/dev/null 2>&1; then
  echo "[INFO] installing helm..."
  retry sh -c 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
fi

# ---- Terraform이 만든 config.env 읽기 ----
if [ -f /opt/bootstrap/config.env ]; then
  # shellcheck disable=SC1091
  source /opt/bootstrap/config.env
fi

APP_REPO_URL="${APP_REPO_URL:-}"
APP_REPO_REF="${APP_REPO_REF:-main}"

if [ -z "$APP_REPO_URL" ]; then
  echo "[WARN] APP_REPO_URL empty -> k3s+helm only, exit."
  exit 0
fi

# ---- repo clone ----
mkdir -p /opt/app
cd /opt/app

if [ -d repo/.git ]; then
  cd repo
  retry git fetch --all --prune
else
  retry git clone "$APP_REPO_URL" repo
  cd repo
fi

git checkout "$APP_REPO_REF" || true

# ---- nip.io 도메인용 public ip ----
PUBLIC_IP="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || true)"
DOMAIN_SUFFIX="local"
if [ -n "$PUBLIC_IP" ]; then
  DOMAIN_SUFFIX="${PUBLIC_IP}.nip.io"
fi
echo "[INFO] DOMAIN_SUFFIX=$DOMAIN_SUFFIX"

# ✅ bootstrap.sh는 "있으면 실행", 없으면 스킵
if [ -f scripts/bootstrap.sh ]; then
  chmod +x scripts/bootstrap.sh || true
  echo "[INFO] running scripts/bootstrap.sh"
  retry env DOMAIN_SUFFIX="$DOMAIN_SUFFIX" /bin/bash scripts/bootstrap.sh
  echo "[INFO] bootstrap.sh finished"
else
  echo "[WARN] scripts/bootstrap.sh not found -> skipping app install."
fi

echo "[DONE] user-data finished: $(date -Is)"
