#!/bin/bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
DOMAIN_SUFFIX="${DOMAIN_SUFFIX:-local}"

echo "[INFO] KUBECONFIG=$KUBECONFIG"
echo "[INFO] DOMAIN_SUFFIX=$DOMAIN_SUFFIX"

retry() {
  n=0
  max=10
  delay=5
  while true; do
    "$@" && break
    n=$((n+1))
    if [ "$n" -ge "$max" ]; then
      echo "[ERROR] failed after $max attempts: $*"
      return 1
    fi
    echo "[WARN] retry $n/$max after $delay sec: $*"
    sleep "$delay"
    delay=$((delay*2))
  done
}

# helm 없으면 설치 (user_data가 못했을 때 대비)
if ! command -v helm >/dev/null 2>&1; then
  echo "[INFO] helm not found. installing..."
  retry sh -c 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
fi

echo "[INFO] waiting for k8s api..."
for i in $(seq 1 60); do
  if kubectl get --raw='/readyz' >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

echo "[INFO] waiting for node Ready..."
retry kubectl wait --for=condition=Ready node --all --timeout=300s

# 1) ingress-nginx
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

echo "[INFO] installing ingress-nginx..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --set controller.service.type=NodePort \
  --set controller.hostNetwork=true \
  --set controller.service.externalTrafficPolicy=Local

echo "[INFO] waiting ingress-nginx controller rollout..."
retry kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s

# 2) kube-prometheus-stack
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

cat >/tmp/kps-values.yaml <<EOF
grafana:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - grafana.$DOMAIN_SUFFIX
prometheus:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - prometheus.$DOMAIN_SUFFIX
alertmanager:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - alertmanager.$DOMAIN_SUFFIX
EOF

echo "[INFO] installing kube-prometheus-stack..."
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f /tmp/kps-values.yaml

echo "[INFO] waiting monitoring components..."
# grafana deployment
retry kubectl -n monitoring rollout status deploy/kps-grafana --timeout=600s

# prometheus/alertmanager는 statefulset
# 차트 버전별 이름이 바뀔 수 있어서, 존재하면 기다리고 없으면 넘어감
if kubectl -n monitoring get sts kps-kube-prometheus-stack-prometheus >/dev/null 2>&1; then
  retry kubectl -n monitoring rollout status sts/kps-kube-prometheus-stack-prometheus --timeout=600s
fi
if kubectl -n monitoring get sts kps-kube-prometheus-stack-alertmanager >/dev/null 2>&1; then
  retry kubectl -n monitoring rollout status sts/kps-kube-prometheus-stack-alertmanager --timeout=600s
fi

# 3) your apps (optional)
kubectl create namespace blockchain --dry-run=client -o yaml | kubectl apply -f -

if [ -d "apps/bitcoind" ]; then
  echo "[INFO] installing apps/bitcoind..."
  helm upgrade --install bitcoind ./apps/bitcoind -n blockchain
else
  echo "[WARN] apps/bitcoind not found. skip."
fi

if [ -d "apps/observer" ]; then
  echo "[INFO] installing apps/observer..."
  helm upgrade --install observer ./apps/observer -n blockchain
else
  echo "[WARN] apps/observer not found. skip."
fi

echo "[INFO] done."
echo "Grafana      : http://grafana.$DOMAIN_SUFFIX"
echo "Prometheus   : http://prometheus.$DOMAIN_SUFFIX"
echo "Alertmanager : http://alertmanager.$DOMAIN_SUFFIX"

echo "[INFO] Grafana admin password 확인(기본값 사용 시):"
echo "kubectl -n monitoring get secret kps-grafana -o jsonpath='{.data.admin-password}' | base64 -d ; echo"
