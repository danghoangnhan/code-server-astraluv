#!/usr/bin/env bash
# Create an SSH Service for a Kubeflow notebook created via the Dashboard.
#
# Kubeflow auto-creates an HTTP Service for port 8888 but not for SSH (port 22).
# This script creates the missing SSH Service.
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
  type: ClusterIP
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
echo "Connect via port-forward:"
echo "  kubectl port-forward svc/${NOTEBOOK_NAME}-ssh -n ${NAMESPACE} 2222:22"
echo "  ssh -p 2222 jovyan@localhost"
