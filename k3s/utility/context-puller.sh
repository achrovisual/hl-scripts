#!/bin/bash
set -euo pipefail

# --- IMPORTANT PRE-REQUISITE ON YOUR K3S MASTER NODE ---
# The user specified by K3S_MASTER_USER typically does not have direct read access
# to /etc/rancher/k3s/k3s.yaml. To fix the "Permission denied" error,
# you MUST first run the following commands on your K3s master node:
#
# 1. SSH into your K3s master node as K3S_MASTER_USER.
# 2. Run these commands to copy the kubeconfig to your user's home directory
#    and set correct permissions:
#    sudo cp /etc/rancher/k3s/k3s.yaml /home/${K3S_MASTER_USER}/k3s.yaml
#    sudo chown ${K3S_MASTER_USER}:${K3S_MASTER_USER} /home/${K3S_MASTER_USER}/k3s.yaml
#    chmod 600 /home/${K3S_MASTER_USER}/k3s.yaml
#
# After performing these steps on the master, you can then run this script
# on your bastion host.
# --------------------------------------------------------

# --- YQ INSTALLATION CHECK ---
# This script requires 'yq' (a portable YAML processor) to modify the kubeconfig.
# This section checks if 'yq' is installed.
echo "Starting yq installation check..."
if ! command -v yq &> /dev/null
then
    echo "yq not found."
    echo "Please install yq manually. Instructions can be found here:"
    echo "  https://github.com/mikefarah/yq#install"
    exit 1
else
    echo "yq is already installed."
fi
echo "yq check complete."
# -----------------------------

# --- KUBECTL INSTALLATION CHECK ---
# This script requires 'kubectl' to merge and set the Kubernetes context.
# This section checks if 'kubectl' is installed.
echo "Starting kubectl installation check..."
if ! command -v kubectl &> /dev/null
then
    echo "kubectl not found."
    echo "Please install kubectl manually. Instructions can be found here:"
    echo "  Linux: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
    echo "  macOS: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/"
    echo "  Windows: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
    exit 1
else
    echo "kubectl is already installed."
fi
echo "kubectl check complete."
# ----------------------------------

K3S_MASTER_USER=""
K3S_MASTER_IP=""
K3S_MASTER_SSH_PORT="22"
SSH_KEY_PATH=""
CONTEXT_NAME=""

usage() {
    echo "Usage: $0 -u <master_user> -i <master_ip> -c <context_name> [-p <ssh_port>] [-k <ssh_key_path>]"
    echo "  -u <master_user>      : Username for SSH connection to K3s master (e.g., ubuntu, ec2-user)"
    echo "  -i <master_ip>        : IP address or hostname of the K3s master node"
    echo "  -c <context_name>     : Desired name for the Kubernetes context (e.g., my-k3s-cluster)"
    echo "  -p <ssh_port>         : Optional. SSH port for K3s master (default: 22)"
    echo "  -k <ssh_key_path>     : Optional. Path to your SSH private key (e.g., ~/.ssh/id_rsa)"
    exit 1
}

while getopts "u:i:c:p:k:" opt; do
    case "${opt}" in
        u) K3S_MASTER_USER="${OPTARG}" ;;
        i) K3S_MASTER_IP="${OPTARG}" ;;
        c) CONTEXT_NAME="${OPTARG}" ;;
        p) K3S_MASTER_SSH_PORT="${OPTARG}" ;;
        k) SSH_KEY_PATH="${OPTARG}" ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${K3S_MASTER_USER}" ] || [ -z "${K3S_MASTER_IP}" ] || [ -z "${CONTEXT_NAME}" ]; then
    echo "Error: Missing mandatory arguments."
    usage
fi

echo "Starting K3s context retrieval from ${K3S_MASTER_IP}..."

TEMP_KUBECONFIG_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_KUBECONFIG_DIR}"' EXIT
TEMP_KUBECONFIG_FILE="${TEMP_KUBECONFIG_DIR}/k3s.yaml"

echo "Temporary directory created: ${TEMP_KUBECONFIG_DIR}"

echo "Attempting to copy kubeconfig from ${K3S_MASTER_IP}..."
SCP_COMMAND_ARRAY=(scp -P "${K3S_MASTER_SSH_PORT}")
if [ -n "${SSH_KEY_PATH}" ]; then
    SCP_COMMAND_ARRAY+=(-i "${SSH_KEY_PATH}")
fi
SCP_COMMAND_ARRAY+=("${K3S_MASTER_USER}@${K3S_MASTER_IP}:/home/${K3S_MASTER_USER}/k3s.yaml" "${TEMP_KUBECONFIG_FILE}")

if "${SCP_COMMAND_ARRAY[@]}"; then
    echo "Kubeconfig successfully copied to ${TEMP_KUBECONFIG_FILE}"
else
    echo "Error: Failed to copy kubeconfig. Please ensure you performed the pre-requisite steps on the K3s master node. Also check SSH connectivity, username, IP, port, SSH key path, and file permissions on the master."
    rm -rf "${TEMP_KUBECONFIG_DIR}"
    exit 1
fi

echo "Modifying kubeconfig to use ${K3S_MASTER_IP} as the server address..."
sed -i "s|server: https://[^:]*:\([0-9]*\)|server: https://${K3S_MASTER_IP}:\1|" "${TEMP_KUBECONFIG_FILE}"

echo "Renaming context, cluster, and user in the temporary kubeconfig file..."
yq -i -y ".contexts[0].name = \"${CONTEXT_NAME}\"" "${TEMP_KUBECONFIG_FILE}"
yq -i -y ".contexts[0].context.cluster = \"${CONTEXT_NAME}\"" "${TEMP_KUBECONFIG_FILE}"
yq -i -y ".contexts[0].context.user = \"${CONTEXT_NAME}\"" "${TEMP_KUBECONFIG_FILE}"
yq -i -y ".clusters[0].name = \"${CONTEXT_NAME}\"" "${TEMP_KUBECONFIG_FILE}"
yq -i -y ".users[0].name = \"${CONTEXT_NAME}\"" "${TEMP_KUBECONFIG_FILE}"

echo "Merging new context '${CONTEXT_NAME}' into ${HOME}/.kube/config..."
KUBECONFIG_MERGED_PATH="${HOME}/.kube/config.merged"
KUBECONFIG_ORIGINAL_PATH="${HOME}/.kube/config"

mkdir -p "${HOME}/.kube"

if [ -f "${KUBECONFIG_ORIGINAL_PATH}" ]; then
    KUBECONFIG="${KUBECONFIG_ORIGINAL_PATH}:${TEMP_KUBECONFIG_FILE}" kubectl config view --flatten > "${KUBECONFIG_MERGED_PATH}"
    mv "${KUBECONFIG_MERGED_PATH}" "${KUBECONFIG_ORIGINAL_PATH}"
    echo "Merged context into existing kubeconfig."
else
    cp "${TEMP_KUBECONFIG_FILE}" "${KUBECONFIG_ORIGINAL_PATH}"
    echo "Created new kubeconfig file."
fi

export KUBECONFIG="${HOME}/.kube/config"

echo "Context '${CONTEXT_NAME}' has been added/updated in ${HOME}/.kube/config."

echo "Setting '${CONTEXT_NAME}' as the current kubectl context..."
kubectl config use-context "${CONTEXT_NAME}"

echo "Cleaning up temporary files..."
rm -rf "${TEMP_KUBECONFIG_DIR}"
echo "Temporary directory ${TEMP_KUBECONFIG_DIR} removed."

echo "Script finished. You should now be able to manage your K3s cluster."
echo "Try: kubectl get nodes"
