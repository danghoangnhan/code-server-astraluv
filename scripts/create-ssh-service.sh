#!/usr/bin/env bash
# Create an SSH Service for a Kubeflow notebook created via the Dashboard.
#
# Creates an SSH Service with LoadBalancer for external access.
# Users connect via VS Code Remote-SSH from outside the cluster.
#
# Usage:
#   scripts/create-ssh-service.sh <notebook-name> [namespace]
#
# Example:
#   scripts/create-ssh-service.sh my-notebook kubeflow-user

set -euo pipefail

NOTEBOOK_NAME="${1:?Usage: $0 <notebook-name> [namespace]}"
NAMESPACE="${2:-kubeflow-user}"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${NOTEBOOK_NAME}-ssh
  namespace: ${NAMESPACE}
  labels:
    app: ${NOTEBOOK_NAME}
    notebook-name: ${NOTEBOOK_NAME}
spec:
  type: LoadBalancer
  selector:
    notebook-name: ${NOTEBOOK_NAME}
    statefulset: ${NOTEBOOK_NAME}
  ports:
    - name: ssh
      port: 22
      targetPort: 22
      protocol: TCP
EOF

echo "SSH Service created: ${NOTEBOOK_NAME}-ssh.${NAMESPACE}.svc.cluster.local:22"
echo ""
echo ""
echo "Get external IP:"
echo "  kubectl get svc ${NOTEBOOK_NAME}-ssh -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""
echo "Connect via SSH:"
echo "  ssh jovyan@<EXTERNAL-IP>"
echo ""
echo "Fallback (port-forward):"
echo "  kubectl port-forward svc/${NOTEBOOK_NAME}-ssh -n ${NAMESPACE} 2222:22"
echo "  ssh -p 2222 jovyan@localhost"
