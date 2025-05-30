#!/bin/bash

echo "Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

sudo apt update
sudo apt upgrade -y

sudo apt install helm -y

echo "Adding hl-k3s Helm repo..."
sudo helm repo add hl-k3s https://achrovisual.github.io/hl-k3s/ --kubeconfig /etc/rancher/k3s/k3s.yaml

echo "Adding hl-k3s git repo..."
mkdir repos
cd repos/
git clone https://github.com/achrovisual/hl-k3s
cd hl-k3s

echo "Installing Argo CD..."
# Ensure the charts/argo-cd path is correct relative to where the script is run
# You might need to adjust this path depending on your project structure
sudo helm repo add argo https://argoproj.github.io/argo-helm

sudo helm install argo-cd charts/private/argo-cd --namespace argo-cd --create-namespace --kubeconfig /etc/rancher/k3s/k3s.yaml
sudo helm dependency build charts/private/argo-cd
echo "Setting up Argo CD and apps (MetalLB, OpenTelemetry Collector)..."
# Ensure the charts/argo-cd-setup path is correct relative to where the script is run
# You might need to adjust this path depending on your project structure
sudo helm template charts/private/argo-cd-setup/ --kubeconfig /etc/rancher/k3s/k3s.yaml | sudo kubectl apply -f - -n argo-cd

echo "Initial Argo CD admin password:"
sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d