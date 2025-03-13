#!/bin/bash

# Cluster Pool
# Master Nodes: 172.16.4.201 - 172.16.4.203
# Worker Nodes: 172.16.4.204 - 172.16.4.205
# Load Balancers: 172.16.4.206 - 172.16.4.210

master_01=172.16.4.201
master_02=172.16.4.202
master_03=172.16.4.203

worker_01=172.16.4.204
worker_02=172.16.4.205

master_nodes={$master_02 $master_03}
worker_nodes={$worker_01 $worker_02}

if [ $# -ne 1 ]; then
  echo "Usage: $0 <node_type>"
  exit 1
fi

node_type="$1"

if [[ "$node_type" == "server" ]]; then
  # Install K3s server
  curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server --cluster-init --disable=servicelb

  # Install Helm
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

  sudo apt install update
  sudo apt install upgrade -y

  sudo apt install helm

  # Add Argo Helm repo
  sudo helm repo add argo https://argoproj.github.io/argo-helm

  # Install Argo CD with ingress enabled and TLS disabled
  sudo helm upgrade argo-cd argo/argo-cd --version 7.8.10 --namespace argo-cd --kubeconfig /etc/rancher/k3s/k3s.yaml --create-namespace --set nameOverride=argo-cd --set configs.params.server.insecure=true --set server.ingress.enabled=true --set server.service.type="LoadBalancer"

  # Print initial admin password
  sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
elif [[ "$node_type" == "agent" ]]; then
  curl -sfL https://get.k3s.io | K3S_URL=https://$master_01:6443 K3S_TOKEN=SECRET sh -
else
  echo "Error: Invalid node type: $node_type."
  exit 1
fi
