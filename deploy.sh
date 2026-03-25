#!/bin/bash
set -euo pipefail

# =============================================================================
# Deploy Kubeflow SSH Notebook — Build, Push, and Apply
# =============================================================================
# Usage:
#   ./deploy.sh <your-registry>
#   ./deploy.sh ghcr.io/daniel-tu
#   ./deploy.sh your-account.dkr.ecr.us-east-1.amazonaws.com
# =============================================================================

REGISTRY="${1:?Usage: ./deploy.sh <container-registry>}"
IMAGE_NAME="code-server-astraluv"
IMAGE_TAG="latest"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
NAMESPACE="kubeflow-user"

echo "============================================="
echo "  Kubeflow SSH Notebook — Deploy"
echo "============================================="
echo "  Image:     ${FULL_IMAGE}"
echo "  Namespace: ${NAMESPACE}"
echo "============================================="

# ---- Step 1: Build the Docker image -----------------------------------------
echo ""
echo "[1/5] Building Docker image..."
docker build -t "${FULL_IMAGE}" .

# ---- Step 2: Push to registry -----------------------------------------------
echo ""
echo "[2/5] Pushing to ${REGISTRY}..."
docker push "${FULL_IMAGE}"

# ---- Step 3: Update the image reference in notebook.yaml --------------------
echo ""
echo "[3/5] Updating image in notebook.yaml..."
sed -i.bak "s|image: your-registry/kubeflow-ssh-notebook:latest|image: ${FULL_IMAGE}|g" k8s/notebook.yaml
rm -f k8s/notebook.yaml.bak

# ---- Step 4: Apply Kubernetes manifests -------------------------------------
echo ""
echo "[4/5] Applying Kubernetes manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/ssh-secret.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/notebook.yaml
kubectl apply -f k8s/ssh-service.yaml

# ---- Step 5: Wait for pod to be ready --------------------------------------
echo ""
echo "[5/5] Waiting for notebook pod to be ready..."
kubectl wait --for=condition=ready pod \
    -l notebook-name=pytorch-ssh-notebook \
    -n "${NAMESPACE}" \
    --timeout=300s

echo ""
echo "============================================="
echo "  Deployment complete!"
echo "============================================="
echo ""
echo "  Get external IP (LoadBalancer):"
echo "    kubectl get svc pytorch-ssh-notebook-ssh -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""
echo "  Connect via SSH:"
echo "    ssh -i ~/.ssh/kubeflow_ed25519 jovyan@<EXTERNAL-IP>"
echo ""
echo "  Or open VS Code:"
echo "    1. Copy vscode-ssh-config to ~/.ssh/config"
echo "    2. Ctrl+Shift+P → Remote-SSH: Connect to Host → kubeflow-notebook"
echo ""
echo "  Fallback (port-forward):"
echo "    kubectl port-forward -n ${NAMESPACE} svc/pytorch-ssh-notebook-ssh 2222:22 &"
echo "    ssh -i ~/.ssh/kubeflow_ed25519 jovyan@127.0.0.1 -p 2222"
echo "============================================="
