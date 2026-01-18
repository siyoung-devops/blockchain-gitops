#!/usr/bin/env bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
DOMAIN_SUFFIX="${DOMAIN_SUFFIX:-local}"

echo "[INFO] KUBECONFIG=${KUBECONFIG}"
echo "[INFO] DOMAIN_SUFFIX=${DOMAIN_SUFFIX}"

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

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "[ERROR] missing command: $1"; exit 1; }
}

need_cmd kubectl
need_cmd helm

echo "[INFO] Waiting for k8s api..."
retry kubectl version --short

# -------------------------
# 1) ingress-nginx
# -------------------------
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

# helm repo add는 이미 있으면 에러날 수 있어서 || true 처리
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update

echo "[INFO] Installing ingress-nginx..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx

echo "[INFO] Waiting ingress-nginx-controller Available..."
# chart에 따라 deployment 이름이 다를 수 있어 우선 표준 이름으로 wait
kubectl wait --for=condition=Available deploy/ingress-nginx-controller -n ingress-nginx --timeout=300s \
  || kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s

# -------------------------
# 2) kube-prometheus-stack
# -------------------------
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

cat >/tmp/kps-values.yaml <<EOF
grafana:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - grafana.${DOMAIN_SUFFIX}
    path: /
    pathType: Prefix

prometheus:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - prometheus.${DOMAIN_SUFFIX}
    paths:
      - /
    pathType: Prefix

alertmanager:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - alertmanager.${DOMAIN_SUFFIX}
    paths:
      - /
    pathType: Prefix
EOF

echo "[INFO] Installing kube-prometheus-stack..."
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f /tmp/kps-values.yaml

echo "[INFO] Waiting Grafana rollout..."
kubectl -n monitoring rollout status deploy/kps-grafana --timeout=600s || true

# (선택) Prometheus/Alertmanager는 리소스가 빡빡한 t3.micro에서 느릴 수 있어서 강제 실패는 피함
kubectl -n monitoring get pods -o wide || true

# -------------------------
# 3) Your apps (optional)
# -------------------------
kubectl create namespace blockchain --dry-run=client -o yaml | kubectl apply -f -

if [ -d "apps/bitcoind" ]; then
  echo "[INFO] Installing bitcoind chart..."
  helm upgrade --install bitcoind ./apps/bitcoind -n blockchain
else
  echo "[WARN] apps/bitcoind not found, skipping."
fi

if [ -d "apps/observer" ]; then
  echo "[INFO] Installing observer chart..."
  helm upgrade --install observer ./apps/observer -n blockchain
else
  echo "[WARN] apps/observer not found, skipping."
fi

echo ""
echo "[DONE] Installed. URLs:"
echo "  Grafana:      http://grafana.${DOMAIN_SUFFIX}"
echo "  Prometheus:   http://prometheus.${DOMAIN_SUFFIX}"
echo "  Alertmanager: http://alertmanager.${DOMAIN_SUFFIX}"
