#!/bin/bash

set -euo pipefail

K3S_MASTER_USER="$1"

if [ -z "${K3S_MASTER_USER}" ]; then
    echo "Error: K3S_MASTER_USER is not provided." >&2
    echo "Usage: $0 <your_username>" >&2
    echo "Example: $0 alice" >&2
    exit 1
fi

if ! id -u "${K3S_MASTER_USER}" &>/dev/null; then
    echo "Error: User '${K3S_MASTER_USER}' does not exist." >&2
    echo "Please create the user manually before running this script, e.g.:" >&2
    echo "  sudo useradd -m -s /bin/bash ${K3S_MASTER_USER}" >&2
    echo "  sudo passwd ${K3S_MASTER_USER}" >&2
    exit 1
else
    echo "User '${K3S_MASTER_USER}' already exists. Proceeding..."
fi

if [ ! -d "/home/${K3S_MASTER_USER}" ]; then
    echo "Warning: User home directory /home/${K3S_MASTER_USER} does not exist. Attempting to create it."
    sudo mkdir -p "/home/${K3S_MASTER_USER}"
    sudo chown "${K3S_MASTER_USER}":"${K3S_MASTER_USER}" "/home/${K3S_MASTER_USER}"
fi

echo "Setting up Kubeconfig for user: ${K3S_MASTER_USER}."

sudo cp /etc/rancher/k3s/k3s.yaml "/home/${K3S_MASTER_USER}/k3s.yaml"
sudo chown "${K3S_MASTER_USER}":"${K3S_MASTER_USER}" "/home/${K3S_MASTER_USER}/k3s.yaml"
chmod 600 "/home/${K3S_MASTER_USER}/k3s.yaml"

echo "Kubeconfig setup complete for ${K3S_MASTER_USER}."

echo "Installing Helm..."

curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list >/dev/null

sudo apt update

sudo apt upgrade -y

sudo apt install helm -y

echo "Adding hl-k3s Helm repo..."

sudo helm repo add hl-k3s https://achrovisual.github.io/hl-k3s/ --kubeconfig /etc/rancher/k3s/k3s.yaml

echo "Adding hl-k3s git repo..."

mkdir -p repos

cd repos/

if [ ! -d "hl-k3s" ]; then
    git clone https://github.com/achrovisual/hl-k3s
else
    echo "hl-k3s repository already exists. Skipping clone."
fi

cd hl-k3s

echo "Installing Argo CD..."

sudo helm repo add argo https://argoproj.github.io/argo-helm

sudo helm install argo-cd charts/private/argo-cd --namespace argo-cd --create-namespace --kubeconfig /etc/rancher/k3s/k3s.yaml

sudo helm dependency build charts/private/argo-cd

echo "Setting up Argo CD and apps (MetalLB, OpenTelemetry Collector)..."

sudo helm template charts/private/argo-cd-setup/ --kubeconfig /etc/rancher/k3s/k3s.yaml | sudo kubectl apply -f - -n argo-cd

echo "Initial Argo CD admin password:"

sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""