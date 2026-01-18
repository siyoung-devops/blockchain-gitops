#!/bin/bash
set -euo pipefail

# --- Configuration ---
LOG_FILE="/var/log/user-data.log"
K3S_CONFIG_FILE="/etc/rancher/k3s/config.yaml"

# Redirect all output to log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] Starting user_data setup at $(date)"

# 0. Setup Swap (Vital for t3.micro)
echo "[INFO] Setting up 2GB Swap..."
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 1. Install System Dependencies
echo "[INFO] Installing system dependencies..."
dnf install -y git jq curl tar --allowerasing

# 2. Install K3s (Disable Traefik to use Nginx)
echo "[INFO] Installing K3s..."
mkdir -p /etc/rancher/k3s
cat > "$K3S_CONFIG_FILE" <<YAML
write-kubeconfig-mode: "0644"
disable:
  - traefik
YAML

if ! command -v k3s &> /dev/null; then
  curl -sfL https://get.k3s.io | sh -
else
  echo "[INFO] K3s already installed."
fi

# Wait for K3s to be ready
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "[INFO] Waiting for K3s to be ready..."
for i in {1..30}; do
  if kubectl get nodes &> /dev/null; then
    echo "[INFO] Kubernetes API is ready."
    break
  fi
  sleep 5
done

# 3. Install Helm
echo "[INFO] Installing Helm..."
if ! command -v helm &> /dev/null; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "[INFO] Helm already installed."
fi

# 4. Install Ingress Nginx
echo "[INFO] Installing Ingress Nginx..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install Nginx Ingress Controller
# Using hostNetwork=true for simple single-node setup (optional, but good for direct IP access on 80/443 without LoadBalancer costs if on public subnet)
# Or use default service type LoadBalancer (which stays Pending on bare metal/simple EC2 without AWS LB Connect, so we use NodePort or hostNetwork)
# For this "Server" setup, we'll assume we want similar behavior to Traefik: binding port 80/443 on the host.
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.hostNetwork=true \
  --set controller.service.externalTrafficPolicy=Local \
  --wait

# 5. Optional: App Repository Setup (if provided)
APP_REPO_URL="${app_repo_url}"
APP_REPO_REF="${app_repo_ref}"

if [ -n "$APP_REPO_URL" ]; then
  echo "[INFO] Setting up Application Repository..."
  mkdir -p /opt/app
  cd /opt/app
  
  if [ -d "repo" ]; then
    rm -rf repo
  fi
  
  git clone "$APP_REPO_URL" repo
  cd repo
  if [ -n "$APP_REPO_REF" ]; then
    git checkout "$APP_REPO_REF"
  fi
  
  echo "[INFO] App repository cloned to /opt/app/repo"
  
  # Ensure bootstrap script is executable if it exists
  if [ -f "scripts/bootstrap.sh" ]; then
    chmod +x scripts/bootstrap.sh
    echo "[INFO] Running application bootstrap script..."
    # Pass necessary env vars
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    
    # Fetch Public IP for nip.io domain
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)
    export DOMAIN_SUFFIX="$${PUBLIC_IP}.nip.io"
    
    ./scripts/bootstrap.sh
  fi
fi

echo "[INFO] User data setup complete at $(date)"
