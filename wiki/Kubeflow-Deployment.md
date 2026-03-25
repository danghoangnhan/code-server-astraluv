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
| Base | `latest-cuda12.8-ubuntu22.04-base` | Most workflows |
| Runtime | `latest-cuda12.8-ubuntu22.04-runtime` | Full CUDA runtime |
| Devel | `latest-cuda12.8-ubuntu22.04-devel` | Building CUDA extensions |

> All CUDA versions (11.8, 12.1, 12.2, 12.4, 12.6, 12.8) and Ubuntu versions (22.04, 24.04) are available. See [Image Variants](Image-Variants) for full list.

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

## Dashboard UI Integration

Instead of applying YAML manifests directly, you can make code-server-astraluv available in the Kubeflow Dashboard "New Notebook" form.

### Prerequisites

- Kubeflow 1.7+ with Jupyter Web App (JWA) installed
- `kubectl` access to the `kubeflow` namespace

### Step 1: Add Images to the Dashboard Dropdown

Patch the JWA ConfigMap to include code-server-astraluv images:

```bash
kubectl patch configmap jupyter-web-app-config -n kubeflow \
  --patch-file kubeflow/dashboard/spawner-config-patch.yaml

# Restart JWA to pick up changes
kubectl rollout restart deployment jupyter-web-app -n kubeflow
```

This adds all image variants (CPU, GPU, CUDA versions) to the image selector in the "New Notebook" form.

### Step 2: Deploy PodDefaults (Optional Configurations)

PodDefaults add checkboxes to the "New Notebook" form for SSH and shared memory:

```bash
# Deploy to a user namespace (repeat for each namespace)
kubectl apply -k kubeflow/dashboard/ -n kubeflow-user
```

This creates:
- **Enable SSH access** — injects SSH key volume from `notebook-ssh-key` Secret
- **Mount /dev/shm** — adds 2Gi shared memory for PyTorch DataLoader workers

### Step 3: Create SSH Key Secret

Required if using the SSH PodDefault:

```bash
kubectl create secret generic notebook-ssh-key \
  --from-file=jovyan=$HOME/.ssh/id_ed25519.pub \
  -n kubeflow-user
```

### Step 4: Create Notebook from the Dashboard

1. Open the Kubeflow Dashboard
2. Go to **Notebooks** > **New Notebook**
3. Select a `code-server-astraluv` image from the dropdown
4. Under **Configurations**, check **Enable SSH access** and/or **Mount /dev/shm** as needed
5. Configure CPU, memory, GPU resources as desired
6. Click **Launch**

### Step 5: Create SSH Service (if SSH enabled)

Kubeflow only auto-creates an HTTP Service (port 8888). For SSH access, create the SSH Service:

```bash
scripts/create-ssh-service.sh <notebook-name> kubeflow-user
```

Then connect:
```bash
kubectl port-forward svc/<notebook-name>-ssh -n kubeflow-user 2222:22
ssh -p 2222 jovyan@localhost
```

### Notes

- **PodDefaults are per-namespace** — deploy them to each user namespace where notebooks will be created.
- **Kubeflow 1.8+** supports labeled image options. See comments in `spawner-config-patch.yaml` for the object format.
- The spawner config is a **merge patch** — it replaces the image options, not appends. Add your existing images alongside the code-server-astraluv entries if needed.

For detailed setup instructions, see [`kubeflow/dashboard/README.md`](../kubeflow/dashboard/README.md).

---

**Next Steps**: [Troubleshooting](Troubleshooting) | [Contributing](Contributing)
