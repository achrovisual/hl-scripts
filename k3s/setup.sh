#!/bin/bash

node_type=""
server_token=""
server_ip=""
address_pool=""

while getopts "n:t:s:a:" opt; do
  case "$opt" in
    n) node_type="$OPTARG" ;;
    t) server_token="$OPTARG" ;;
    s) server_ip="$OPTARG" ;;
    a) address_pool="$OPTARG" ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Usage: $0 --node_type <value> --server_token <value> [--server_ip <value>]"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      echo "Usage: $0 --node_type <value> --server_token <value> [--server_ip <value>]"
      exit 1
      ;;
  esac
done

if [ -z "$node_type" ] || [ -z "$server_token" ]; then
  echo "Usage: $0 --node_type <value> --server_token <value> [--server_ip <value>] [--address_pool <value>]"
  exit 1
fi

case "$node_type" in
  agent)
    if [ -z "$server_ip" ]; then
      echo "Error: Server IP address is required for a worker node."
      echo "Usage: $0 --node_type agent --server_token <value> --server_ip <value>"
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
      if [ -z "$address_pool" ] || [ -z "$server_token" ]; then
          echo "Error: address_pool and server_token are required for a master node."
          echo "Usage: $0 --node_type server --server_token <value> --address_pool <value>"
          exit 1
      fi

      curl -sfL https://get.k3s.io | K3S_TOKEN=$server_token sh -s - server --cluster-init --disable=servicelb

      # Install Helm
      curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

      sudo apt update
      sudo apt upgrade -y

      sudo apt install helm

      # Add hl-k3s Helm repo
      sudo helm repo add hl-k3s https://achrovisual.github.io/hl-k3s/ --kubeconfig /etc/rancher/k3s/k3s.yaml

      # Install Argo CD
      sudo helm install argo-cd charts/argo-cd --namespace argo-cd --create-namespace --kubeconfig /etc/rancher/k3s/k3s.yaml\

      # Setup Argo CD and apps
      # This installs MetalLB and OpenTelemetry Collector
      sudo helm template charts/argo-cd-setup/ --kubeconfig /etc/rancher/k3s/k3s.yaml | sudo kubectl apply -f - -n argo-cd

      # Print initial admin password
      sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    fi
    ;;
  *)
    echo "Invalid node type: $node_type"
    exit 1
    ;;
esac