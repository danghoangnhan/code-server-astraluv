# Kubeflow Notebook with Astral UV, SSH, and GPU Support

[![CI](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/docker-build-main.yml/badge.svg)](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/docker-build-main.yml)
[![Release](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/build-and-push.yml)
[![Docker Hub](https://img.shields.io/docker/v/danieldu28121999/code-server-astraluv?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/danieldu28121999/code-server-astraluv)
[![GitHub](https://img.shields.io/github/license/danghoangnhan/code-server-astraluv)](https://github.com/danghoangnhan/code-server-astraluv/blob/main/LICENSE)

A **minimal**, production-ready Docker image for Kubeflow notebooks featuring GPU/CUDA support, Astral UV for fast Python package management, and built-in SSH access for VS Code Remote-SSH.

## Table of Contents

- [Design Philosophy](#design-philosophy)
- [Features](#features)
- [Quick Start](#quick-start)
- [Image Variants](#image-variants)
- [Connecting with VS Code](#connecting-with-vs-code)
- [SSH Access](#ssh-access)
- [GPU Support](#gpu-support)
- [Kubeflow Integration](#kubeflow-integration)
- [Environment Variables](#environment-variables)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Design Philosophy

This is a **minimal base image** — no Python or packages are pre-installed. Users install exactly what they need using UV, which is 10-100x faster than pip. This approach:

- Keeps the image small (~3-4 GB vs 8-12 GB)
- Avoids dependency conflicts
- Lets users choose exact Python and package versions
- Supports multiple Python versions via UV

## Features

- **GPU Support**: NVIDIA CUDA 11.8–12.8 on Ubuntu 22.04/24.04 (base, runtime, or devel variants)
- **Astral UV**: Lightning-fast Python package manager — [docs](https://docs.astral.sh/uv/)
- **SSH Access**: Built-in OpenSSH server for VS Code Remote-SSH, JetBrains Gateway, and SCP/SFTP ([kubeflow/notebooks#23](https://github.com/kubeflow/notebooks/issues/23))
- **VS Code Remote-SSH** (port 22) — connect your local VS Code with full extension support
- **JupyterLab** — optional, install via `uv pip install jupyterlab`
- **Kubeflow Compliant**: `jovyan` user (UID 1000), s6-overlay process management
- **External Access**: LoadBalancer service for SSH from outside the cluster
- **CI/CD**: Automated builds, Trivy security scanning, SBOM via GitHub Actions

## Quick Start

### Pull and Run

```bash
docker pull danieldu28121999/code-server-astraluv:latest

# Prepare SSH key for authentication
mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan

# CPU
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  danieldu28121999/code-server-astraluv:latest

# GPU
docker run -d --gpus all -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  danieldu28121999/code-server-astraluv:latest
```

Connect via SSH:
```bash
ssh -p 2222 jovyan@localhost
```

Or open VS Code → `Ctrl+Shift+P` → `Remote-SSH: Connect to Host` → enter `jovyan@localhost:2222`

### Install Python and Packages (Inside Container)

```bash
uv python install 3.11
uv pip install pandas numpy matplotlib

# Optional: JupyterLab
uv pip install jupyterlab
jupyter lab --ip=0.0.0.0 --port=8889 --no-browser &
```

### Deploy to Kubeflow

```bash
kubectl apply -f kubeflow/notebook.yaml          # CPU + SSH
kubectl apply -f kubeflow/notebook-gpu.yaml       # GPU + SSH
kubectl apply -f k8s/ssh-service.yaml             # LoadBalancer for external SSH
```

See the [Kubeflow Deployment Guide](https://github.com/danghoangnhan/code-server-astraluv/wiki/Kubeflow-Deployment) for full instructions.

## Image Variants

All variants include SSH server and UV. **No Python is pre-installed** — install any version via `uv python install`.

| Variant | Use Case | Example Tag |
|---------|----------|-------------|
| **base** | Minimal CUDA runtime, no compiler | `latest-cuda12.8-ubuntu22.04-base` |
| **runtime** | Full CUDA runtime | `latest-cuda12.8-ubuntu22.04-runtime` |
| **devel** | Development toolkit with nvcc | `latest-cuda12.8-ubuntu22.04-devel` |

**Supported CUDA versions**: 11.8, 12.1, 12.2, 12.4, 12.6, 12.8
**Supported Ubuntu versions**: 22.04, 24.04 (24.04 available for CUDA 12.6+)

```bash
# Tag format: latest-cuda{VERSION}-ubuntu{UBUNTU}-{flavor}
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-base
docker pull danieldu28121999/code-server-astraluv:latest-cuda11.8-ubuntu22.04-base
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.6-ubuntu24.04-devel
```

See [Image Variants](https://github.com/danghoangnhan/code-server-astraluv/wiki/Image-Variants) wiki page for details.

## Connecting with VS Code

The primary way to use this image is via **VS Code Remote-SSH** extension on your local machine.

### Setup

1. Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension in VS Code
2. Copy `vscode-ssh-config` to `~/.ssh/config` (or merge into your existing config)
3. Connect: `Ctrl+Shift+P` → `Remote-SSH: Connect to Host` → `kubeflow-notebook`

### Connection Methods

| Method | Command | Best For |
|--------|---------|----------|
| **LoadBalancer** (default) | `ssh jovyan@<EXTERNAL-IP>` | Production, external access |
| **Port-forward** | `kubectl port-forward svc/<name>-ssh 2222:22` then `ssh -p 2222 jovyan@localhost` | Development, debugging |

See `vscode-ssh-config` for a ready-to-use SSH config template.

## SSH Access

Built-in SSH server for connecting local IDEs (VS Code Remote-SSH, JetBrains Gateway) to remote GPU notebook pods. Addresses [kubeflow/notebooks#23](https://github.com/kubeflow/notebooks/issues/23).

### Security

- Public key authentication only (no passwords)
- Root login disabled
- Only `jovyan` user allowed (`AllowUsers jovyan`)
- Keys mounted from Kubernetes Secrets
- Supervised by s6-overlay (auto-restarts on failure)

### Kubeflow Setup

1. **Generate key pair:**
   ```bash
   ssh-keygen -t ed25519 -C "kubeflow-notebook" -f ~/.ssh/kubeflow_ed25519
   ```

2. **Create Secret** — edit `k8s/ssh-secret.yaml` with your public key:
   ```bash
   kubectl apply -f k8s/ssh-secret.yaml
   ```

3. **Deploy and expose SSH:**
   ```bash
   kubectl apply -f kubeflow/notebook-gpu.yaml
   kubectl apply -f k8s/ssh-service.yaml
   ```

4. **Get external IP:**
   ```bash
   kubectl get svc pytorch-ssh-notebook-ssh -n kubeflow-user -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

5. **Connect:**
   ```bash
   ssh -i ~/.ssh/kubeflow_ed25519 jovyan@<EXTERNAL-IP>
   ```

6. **VS Code Remote SSH** — copy `vscode-ssh-config` to `~/.ssh/config`, then `Ctrl+Shift+P` > `Remote-SSH: Connect to Host` > `kubeflow-notebook`.

### Local Docker Setup

```bash
mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  danieldu28121999/code-server-astraluv:latest
ssh -p 2222 jovyan@localhost
```

## GPU Support

```bash
# Install PyTorch with CUDA inside the container
# PyTorch wheel URL depends on your CUDA version: cu118, cu121, cu124, cu126
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
```

```python
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"GPU: {torch.cuda.get_device_name(0)}")
```

**Requirements**: NVIDIA GPU (Compute Capability 3.5+), Driver 450.80.02+, nvidia-docker2 (local) or NVIDIA GPU Operator (K8s).

## Kubeflow Integration

Compatible with [Kubeflow custom image requirements](https://www.kubeflow.org/docs/components/notebooks/container-images/):

- Exposes SSH on port 22
- Runs as `jovyan` user (UID 1000, GID 100)
- Home directory at `/home/jovyan`
- PVC mount compatible
- s6-overlay process management

See [kubeflow/](./kubeflow/) directory for deployment manifests (CPU and GPU variants).

### Dashboard UI

You can create notebooks directly from the Kubeflow Dashboard "New Notebook" form. See [kubeflow/dashboard/](./kubeflow/dashboard/) for spawner config patches and PodDefaults that add images to the dropdown with SSH and shared memory configurations.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NB_USER` | `jovyan` | Username (Kubeflow requirement) |
| `NB_UID` | `1000` | User ID |
| `NB_GID` | `100` | Group ID |
| `CUDA_HOME` | `/usr/local/cuda` | CUDA installation path |
| `UV_PYTHON_PREFERENCE` | `managed` | UV uses managed Python |

## What's Included

| Category | Components |
|----------|-----------|
| **Pre-installed** | Astral UV & uvx, OpenSSH server, s6-overlay |
| **System tools** | CUDA (configurable: 11.8–12.8), git, wget, curl, vim, htop, build-essential |
| **Not included** | Python, JupyterLab, Python packages — install via UV as needed |

## Security

- Runs as non-root user (`jovyan`)
- SSH: pubkey-only, no root login, `AllowUsers jovyan`
- Weekly Trivy security scans
- SBOM generation for supply chain security
- No hardcoded secrets
- UV copied from official verified image

## Troubleshooting

| Problem | Solution |
|---------|----------|
| SSH connection refused | Check sshd: `kubectl exec <pod> -- pgrep -f sshd` and verify LoadBalancer IP is assigned |
| SSH permission denied (publickey) | Verify key mounted: `kubectl exec <pod> -- cat /etc/ssh/authorized_keys/jovyan` |
| GPU not detected | Verify nvidia-docker2: `docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi` |
| Permission denied on /home/jovyan | PVC mount issue: `kubectl exec <pod> -- sudo chown -R jovyan:users /home/jovyan` |
| Package install fails | Use `uv pip install <package>` (build-essential is pre-installed) |
| LoadBalancer pending | Check `kubectl get svc -n kubeflow-user` — may need cloud provider LB controller |

See the [Troubleshooting Guide](https://github.com/danghoangnhan/code-server-astraluv/wiki/Troubleshooting) for more details.

## Tags

Tag format: `{version}-cuda{MAJOR.MINOR}-ubuntu{VERSION}-{flavor}`

- `latest` — latest CUDA + Ubuntu 22.04 + base
- `latest-cuda12.8-ubuntu22.04-base` — explicit latest
- `latest-cuda11.8-ubuntu22.04-devel` — specific CUDA + flavor
- `v2.0.0-cuda12.6-ubuntu24.04-runtime` — pinned release

## Contributing

See our [Contributing Guide](https://github.com/danghoangnhan/code-server-astraluv/wiki/Contributing) for development setup, code style, and PR guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Support

- [GitHub Issues](https://github.com/danghoangnhan/code-server-astraluv/issues)
- [Wiki Documentation](https://github.com/danghoangnhan/code-server-astraluv/wiki)
- [Kubeflow Docs](https://www.kubeflow.org/docs/components/notebooks/)

## Acknowledgments

- [NVIDIA CUDA](https://hub.docker.com/r/nvidia/cuda) base images
- [Astral UV](https://github.com/astral-sh/uv) official Docker image
- [s6-overlay](https://github.com/just-containers/s6-overlay) process management

---

**Built for the Kubeflow community**
