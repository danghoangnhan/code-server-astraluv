# Kubeflow Deployment Guide

Deploying code-server-astraluv to Kubeflow for team collaboration.

## Overview

The image is fully Kubeflow-compatible with:
- Standard `jovyan` user (UID 1000)
- Automatic `NB_PREFIX` support
- VS Code Server (code-server) on port 8888
- SSH access on port 22 for VS Code Remote / JetBrains Gateway
- GPU enablement via Kubeflow configuration
- Persistent storage integration

---

## Deployment Variants

Four example manifests are provided in the `kubeflow/` directory:

| Manifest | Use Case |
|----------|----------|
| `kubeflow/notebook.yaml` | CPU-only notebook |
| `kubeflow/notebook-gpu.yaml` | GPU-enabled notebook |
| `kubeflow/notebook-ssh.yaml` | CPU + SSH access |
| `kubeflow/notebook-gpu-ssh.yaml` | GPU + SSH access |

```bash
kubectl apply -f kubeflow/notebook.yaml          # CPU
kubectl apply -f kubeflow/notebook-gpu.yaml       # GPU
kubectl apply -f kubeflow/notebook-ssh.yaml       # CPU + SSH
kubectl apply -f kubeflow/notebook-gpu-ssh.yaml   # GPU + SSH
```

---

## Minimal Notebook Spec

```yaml
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: ml-notebook
  namespace: kubeflow-user
spec:
  template:
    spec:
      containers:
      - name: notebook
        image: danieldu28121999/code-server-astraluv:latest
        ports:
        - containerPort: 8888
          name: notebook-port
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
        volumeMounts:
        - name: workspace
          mountPath: /home/jovyan
        env:
        - name: NB_PREFIX
          value: /notebook/kubeflow-user/ml-notebook
      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: workspace-ml-notebook
```

---

## SSH-Enabled Deployment

To enable SSH access for VS Code Remote or JetBrains Gateway:

### 1. Create SSH Key Secret

```bash
# Generate key pair
ssh-keygen -t ed25519 -C "kubeflow-notebook" -f ~/.ssh/kubeflow_ed25519
```

Edit `k8s/ssh-secret.yaml` with your public key, then apply:
```bash
kubectl apply -f k8s/ssh-secret.yaml
```

### 2. Deploy SSH-Enabled Notebook

```bash
kubectl apply -f kubeflow/notebook-gpu-ssh.yaml
kubectl apply -f k8s/ssh-service.yaml
```

The SSH-enabled manifests add:
- Port 22 (SSH) to the container
- `ssh-keys` volume mount from the Secret
- Annotation `notebooks.kubeflow.org/ssh-enabled: "true"`

### 3. Connect via SSH

```bash
# Port-forward SSH
kubectl port-forward -n kubeflow-user svc/pytorch-ssh-notebook-ssh 2222:22 &

# Connect
ssh -i ~/.ssh/kubeflow_ed25519 jovyan@127.0.0.1 -p 2222
```

### 4. VS Code Remote SSH

Add to `~/.ssh/config`:
```
Host kubeflow-notebook
    HostName 127.0.0.1
    Port 2222
    User jovyan
    IdentityFile ~/.ssh/kubeflow_ed25519
    StrictHostKeyChecking no
    ServerAliveInterval 30
```

Then: `Ctrl+Shift+P` > `Remote-SSH: Connect to Host` > `kubeflow-notebook`

---

## GPU Configuration

```yaml
resources:
  requests:
    nvidia.com/gpu: "1"
  limits:
    nvidia.com/gpu: "1"
tolerations:
- key: nvidia.com/gpu
  operator: Exists
  effect: NoSchedule
```

Verify in container:
```bash
nvidia-smi
```

---

## Storage Configuration

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: workspace-ml-notebook
  namespace: kubeflow-user
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```

---

## CUDA Variant Selection

| Variant | Image Tag | Use Case |
|---------|-----------|----------|
| Base | `latest-cuda12.2-base` | Most workflows |
| Runtime | `latest-cuda12.2-runtime` | Full CUDA runtime |
| Devel | `latest-cuda12.2-devel` | Building CUDA extensions |

---

## Accessing the Notebook

1. Log into Kubeflow UI
2. Navigate to Notebooks
3. Click CONNECT on your notebook
4. code-server loads in browser
5. For SSH: port-forward and connect via local IDE

---

## Troubleshooting

**Notebook won't start**:
```bash
kubectl describe notebook ml-notebook -n kubeflow-user
kubectl logs notebook/ml-notebook -n kubeflow-user -c notebook
```

**SSH connection refused**:
```bash
kubectl exec -it <pod> -- pgrep -f sshd
kubectl port-forward -n kubeflow-user svc/<notebook>-ssh 2222:22 &
```

**GPU not available**: Check node has GPU and tolerations are set.

**Out of memory**: Increase memory limits in the spec.

---

**Next Steps**: [Troubleshooting](Troubleshooting) | [Contributing](Contributing)
