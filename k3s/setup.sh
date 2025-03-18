#!/bin/bash

node_type="$1"
server_token="$2"
server_ip="$3"

if [ -z "$node_type" ] || [ -z "$server_token" ]; then
  echo "Usage: $0 <node_type> <server_token> [server_ip]"
  exit 1
fi

case "$node_type" in
agent)
  if [ -z "$server_ip" ]; then
    echo "Error: Server IP address is required for agent node."
    echo "Usage: $0 agent <server_ip>"
    exit 1
  fi

  curl -sfL https://get.k3s.io | K3S_URL=https://$server_ip:6443 K3S_TOKEN=$server_token sh -
  ;;
server)
  if [ -n "$server_ip" ]; then
    # Install K3s server and register to master node
    curl -sfL https://get.k3s.io | K3S_TOKEN=$server_token sh -s - server --disable=servicelb --server https://$server_ip:6443
  else
    # Install K3s server
    curl -sfL https://get.k3s.io | K3S_TOKEN=$server_token sh -s - server --cluster-init --disable=servicelb

    # Install Helm
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

    sudo apt install update
    sudo apt install upgrade -y

    sudo apt install helm

    # Add MetalLB Helm repo
    sudo helm repo add metallb https://metallb.github.io/metallb

    # Install MetalLB
    sudo helm install metallb metallb/metallb --namespace metallb --kubeconfig /etc/rancher/k3s/k3s.yaml --create-namespace

    # Add hl-k3s Helm repo
    sudo helm repo add hl-k3s https://achrovisual.github.io/hl-k3s/ --kubeconfig /etc/rancher/k3s/k3s.yaml

    # Install MetalLB CRs
    sudo helm install metallb-setup hl-k3s/metallb-setup --version 0.1.0 --namespace metallb --kubeconfig /etc/rancher/k3s/k3s.yaml --set addressPool.name="hl-pool" --set addressPool.ipRange="172.16.4.201-172.16.4.254"

    # Add Argo Helm repo
    sudo helm repo add argo https://argoproj.github.io/argo-helm

    # Install Argo CD with ingress enabled and TLS disabled
    sudo helm install argo-cd argo/argo-cd --version 7.8.10 --namespace argo-cd --kubeconfig /etc/rancher/k3s/k3s.yaml --create-namespace --set nameOverride=argo-cd --set configs.params.server\\.insecure=true --set server.ingress.enabled=true --set server.service.type="LoadBalancer"

    # Print initial admin password
    sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  fi
  ;;
*)
  echo "Invalid node type: $node_type"
  exit 1
  ;;
esac
