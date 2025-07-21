#!/bin/bash

# --- Input Argument ---
# K3S_MASTER_USER will be the first argument passed to the script.
K3S_MASTER_USER="$1"

# Basic validation: Check if the username was provided.
if [ -z "$K3S_MASTER_USER" ]; then
    echo "Error: K3S_MASTER_USER is not provided."
    echo "Usage: $0 <your_username>"
    echo "Example: $0 alice"
    exit 1
fi

# --- Kubeconfig Setup for User ---
echo "Setting up Kubeconfig for user: ${K3S_MASTER_USER}..."

# Run these commands to copy the kubeconfig to your user's home directory and set correct permissions:
sudo cp /etc/rancher/k3s/k3s.yaml /home/${K3S_MASTER_USER}/k3s.yaml
sudo chown ${K3S_MASTER_USER}:${K3S_MASTER_USER} /home/${K3S_MASTER_USER}/k3s.yaml
chmod 600 /home/${K3S_MASTER_USER}/k3s.yaml

echo "Kubeconfig setup complete for ${K3S_MASTER_USER}."

---

# Display a message indicating the start of Helm installation.
echo "Installing Helm..."

# Download the Helm signing key, dearmor it, and add it to the system's keyring.
# This ensures the authenticity of the Helm packages.
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null

# Add the Helm stable Debian repository to the system's apt sources list.
# This allows apt to find and install Helm packages.
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# Update the package list to include the newly added Helm repository.
sudo apt update

# Upgrade all installed packages to their latest versions. The -y flag
# automatically answers yes to prompts.
sudo apt upgrade -y

# Install Helm using apt. The -y flag automatically answers yes to prompts.
sudo apt install helm -y

# Display a message indicating the addition of the hl-k3s Helm repository.
echo "Adding hl-k3s Helm repo..."

# Add the hl-k3s Helm repository. This repository contains charts specific to k3s.
# The --kubeconfig flag specifies the Kubernetes configuration file to use.
sudo helm repo add hl-k3s https://achrovisual.github.io/hl-k3s/ --kubeconfig /etc/rancher/k3s/k3s.yaml

# Display a message indicating the cloning of the hl-k3s git repository.
echo "Adding hl-k3s git repo..."

# Create a directory named 'repos' to store git repositories.
mkdir repos

# Change the current directory to 'repos'.
cd repos/

# Clone the hl-k3s git repository from GitHub. This repository likely contains
# Kubernetes manifests, Helm charts, or other configuration files.
git clone https://github.com/achrovisual/hl-k3s

# Change the current directory to the cloned 'hl-k3s' repository.
cd hl-k3s

# Display a message indicating the start of Argo CD installation.
echo "Installing Argo CD..."

# Add the Argo Helm repository. Argo CD is a declarative GitOps continuous
# delivery tool for Kubernetes.
sudo helm repo add argo https://argoproj.github.io/argo-helm

# Install Argo CD using its Helm chart.
# --namespace argo-cd: Specifies the namespace for Argo CD.
# --create-namespace: Creates the namespace if it doesn't exist.
# --kubeconfig: Specifies the Kubernetes configuration file.
# Note: The path 'charts/private/argo-cd' assumes the script is run from a location
# where this path is valid, typically from the root of the hl-k3s repository or similar.
sudo helm install argo-cd charts/private/argo-cd --namespace argo-cd --create-namespace --kubeconfig /etc/rancher/k3s/k3s.yaml

# Build the dependencies for the Argo CD Helm chart. This ensures all required
# sub-charts are fetched.
sudo helm dependency build charts/private/argo-cd

# Display a message indicating the setup of Argo CD applications.
echo "Setting up Argo CD and apps (MetalLB, OpenTelemetry Collector)..."

# Render the Kubernetes manifests from the 'argo-cd-setup' Helm chart as a template
# and apply them to the Kubernetes cluster using kubectl.
# This chart likely defines Argo CD Application resources that manage other
# applications like MetalLB and OpenTelemetry Collector.
# --kubeconfig: Specifies the Kubernetes configuration file.
# -n argo-cd: Specifies the namespace where these resources should be applied.
# Note: Similar to the previous Helm install, the path 'charts/private/argo-cd-setup/'
# assumes a correct relative path.
sudo helm template charts/private/argo-cd-setup/ --kubeconfig /etc/rancher/k3s/k3s.yaml | sudo kubectl apply -f - -n argo-cd

# Display a message indicating that the initial Argo CD admin password will be shown.
echo "Initial Argo CD admin password:"

# Retrieve the initial admin password for Argo CD.
# It fetches the 'argocd-initial-admin-secret' Kubernetes secret in the 'argo-cd' namespace,
# extracts the 'password' field, and decodes it from base64.
sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d