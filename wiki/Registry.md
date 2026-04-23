# Container Registry (Harbor)

Images are published to the internal Harbor registry at **`harbor.thinktron.co/sec1/code-server-astral-uv`**.

## Authentication

Harbor requires credentials to pull private images. Log in once:

```bash
docker login harbor.thinktron.co
# Username: your Harbor account
# Password: Harbor password or CLI secret
```

On Kubernetes, create an `imagePullSecret` and reference it in the notebook spec:

```bash
kubectl create secret docker-registry harbor-sec1 \
  --docker-server=harbor.thinktron.co \
  --docker-username=<user> \
  --docker-password=<pass> \
  --namespace=kubeflow-user
```

## Quick Start

```bash
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest

# Run with GPU and SSH
mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan
docker run -d --gpus all -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest

# Connect via VS Code Remote-SSH or:
ssh -p 2222 jovyan@localhost
```

Inside the container:

```bash
uv python install 3.11
uv pip install pandas numpy matplotlib torch
```

## Supported CUDA Versions

| CUDA | Ubuntu 22.04 | Ubuntu 24.04 |
|:---:|:---:|:---:|
| 11.8 | ✅ | - |
| 12.1 | ✅ | - |
| 12.2 | ✅ | - |
| 12.4 | ✅ | - |
| 12.6 | ✅ | ✅ |
| 12.8 | ✅ | ✅ |

## Image Tags

**Format**: `{version}-cuda{MAJOR.MINOR}-ubuntu{VERSION}-{flavor}`

```bash
# Latest (CUDA 12.8, Ubuntu 22.04, base)
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest

# Specific CUDA + Ubuntu + flavor
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest-cuda12.8-ubuntu22.04-base
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest-cuda11.8-ubuntu22.04-base
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest-cuda12.6-ubuntu24.04-devel

# Pinned release
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:v2.0.0-cuda12.8-ubuntu22.04-base
```

## CUDA Flavor Variants

| Variant | Size | Use Case |
|---------|------|----------|
| **base** | ~8 GB | Minimal CUDA runtime — inference, PyTorch, TensorFlow |
| **runtime** | ~10 GB | Full CUDA runtime libraries |
| **devel** | ~12 GB | Full toolkit with `nvcc` compiler — custom CUDA kernels |

## Build Pipeline

Images are built by GitLab CI (`.gitlab-ci.yml`) using **Kaniko** on the k3s runner and pushed to Harbor:

- `build-main` — runs on push to `main` when Dockerfile or build inputs change; pushes `latest-*` tags across all CUDA/Ubuntu combos (base flavor only).
- `build-release` — runs on semver tags (`vX.Y.Z`); pushes the full matrix (base, runtime, devel).

**Required CI variables** (Settings → CI/CD → Variables, masked + protected):
- `HARBOR_USERNAME`
- `HARBOR_PASSWORD`

## Features

- **Multi-CUDA GPU Support**: CUDA 11.8 through 12.8 on Ubuntu 22.04/24.04
- **Astral UV**: 10-100x faster than pip for Python package management
- **SSH Access**: Built-in OpenSSH for VS Code Remote-SSH and JetBrains Gateway
- **No Python pre-installed**: Install any version via `uv python install 3.11`
- **Kubeflow Compliant**: `jovyan` user (UID 1000), s6-overlay
- **Security**: Non-root user, pubkey-only SSH, Harbor vulnerability scanning

## GPU Usage

```bash
# Install PyTorch (match wheel to your CUDA version)
uv pip install torch --index-url https://download.pytorch.org/whl/cu126  # CUDA 12.6+
uv pip install torch --index-url https://download.pytorch.org/whl/cu124  # CUDA 12.4
uv pip install torch --index-url https://download.pytorch.org/whl/cu121  # CUDA 12.1/12.2
uv pip install torch --index-url https://download.pytorch.org/whl/cu118  # CUDA 11.8
```

## SSH Access

```bash
# Local Docker
mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest
ssh -p 2222 jovyan@localhost
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NB_USER` | `jovyan` | Username |
| `CUDA_HOME` | `/usr/local/cuda` | CUDA path |

## Links

- **Source**: [GitLab](https://rd.thinktronltd.com/sec1/code-server-astraluv)
- **Wiki**: Documentation (this wiki)
- **Harbor UI**: https://harbor.thinktron.co/harbor/projects — browse tags, vulnerability reports, manifests
- **License**: MIT
