#!/bin/bash

node_type=""
server_token=""
server_ip=""
address_pool=""
hostname="" # Corresponds to --tls_san

# Loop through all provided arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -n | --node_type)
      node_type="$2"
      shift # Consume the option
      ;;
    -t | --server_token)
      server_token="$2"
      shift # Consume the option
      ;;
    -s | --server_ip)
      server_ip="$2"
      shift # Consume the option
      ;;
    -a | --address_pool)
      address_pool="$2"
      shift # Consume the option
      ;;
    -T | --tls_san) # Using -T for short form, consistent with your original script
      hostname="$2"
      shift # Consume the option
      ;;
    -h | --help)
      echo "Usage: $0 [-n|--node_type <value>] [-t|--server_token <value>] [-s|--server_ip <value>] [-a|--address_pool <value>] [-T|--tls_san <value>]"
      echo ""
      echo "Options:"
      echo "  -n, --node_type     : Type of node to install (agent or server)"
      echo "  -t, --server_token  : K3s server token for joining/initialization"
      echo "  -s, --server_ip     : IP address of the K3s server (required for agent, optional for server joining existing cluster)"
      echo "  -a, --address_pool  : Address pool for MetalLB (required for initial server setup)"
      echo "  -T, --tls_san       : TLS Subject Alternative Name for the K3s server certificate"
      echo "  -h, --help          : Display this help message"
      exit 0
      ;;
    *)
      echo "Invalid option or missing argument for '$1'" >&2
      echo "For usage, run: $0 --help"
      exit 1
      ;;
  esac
  shift # Consume the value (if it exists, otherwise it consumes the next option/argument)
done

# --- Argument Validation ---

if [ -z "$node_type" ] || [ -z "$server_token" ]; then
  echo "Error: --node_type and --server_token are required." >&2
  echo "For usage, run: $0 --help"
  exit 1
fi

# --- Node Type Logic ---

case "$node_type" in
  agent)
    if [ -z "$server_ip" ]; then
      echo "Error: --server_ip is required for an agent node." >&2
      echo "For usage, run: $0 --help"
      exit 1
    fi

    echo "Installing K3s agent on $server_ip..."
    curl -sfL https://get.k3s.io | K3S_URL=https://$server_ip:6443 K3S_TOKEN=$server_token sh -
    ;;
  server)
    tls_san_arg=""
    if [ -n "$hostname" ]; then
      tls_san_arg="--tls-san=$hostname"
    fi

    if [ -n "$server_ip" ]; then
      # Server joining an existing master
      echo "Installing K3s server and attempting to join existing master at $server_ip..."
      curl -sfL https://get.k3s.io | K3S_TOKEN=$server_token sh -s - server --disable=servicelb --server https://$server_ip:6443 "$tls_san_arg"
    else
      # Initial server setup (new cluster)
      if [ -z "$address_pool" ] || [ -z "$server_token" ]; then
          echo "Error: --address_pool and --server_token are required for a new master node." >&2
          echo "For usage, run: $0 --help"
          exit 1
      fi

      echo "Initializing new K3s server cluster..."
      curl -sfL https://get.k3s.io | K3S_TOKEN=$server_token sh -s - server --cluster-init --disable=servicelb "$tls_san_arg"

      echo "Installing Helm..."
      curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

      sudo apt update
      sudo apt upgrade -y

      sudo apt install helm -y

      echo "Adding hl-k3s Helm repo..."
      sudo helm repo add hl-k3s https://achrovisual.github.io/hl-k3s/ --kubeconfig /etc/rancher/k3s/k3s.yaml

      echo "Installing Argo CD..."
      # Ensure the charts/argo-cd path is correct relative to where the script is run
      # You might need to adjust this path depending on your project structure
      sudo helm repo add argo https://argoproj.github.io/argo-helm
      sudo helm install argo-cd charts/argo-cd --namespace argo-cd --create-namespace --kubeconfig /etc/rancher/k3s/k3s.yaml

      echo "Setting up Argo CD and apps (MetalLB, OpenTelemetry Collector)..."
      # Ensure the charts/argo-cd-setup path is correct relative to where the script is run
      # You might need to adjust this path depending on your project structure
      sudo helm template charts/argo-cd-setup/ --kubeconfig /etc/rancher/k3s/k3s.yaml | sudo kubectl apply -f - -n argo-cd

      echo "Initial Argo CD admin password:"
      sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
      echo "" # Add a newline for better readability
    fi
    ;;
  *)
    echo "Error: Invalid node type '$node_type'." >&2
    echo "Node type must be 'agent' or 'server'." >&2
    echo "For usage, run: $0 --help"
    exit 1
    ;;
esac