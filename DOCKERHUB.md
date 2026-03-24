# Kubeflow Notebook with Astral UV, SSH, and GPU Support

A **minimal**, production-ready Docker image for Kubeflow notebooks featuring multi-CUDA GPU support, Astral UV for fast Python package management, VS Code Server, and built-in SSH access.

## Quick Start

```bash
docker pull danieldu28121999/code-server-astraluv:latest

# Run with GPU
docker run --gpus all -p 8888:8888 danieldu28121999/code-server-astraluv:latest

# Access VS Code at http://localhost:8888
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
docker pull danieldu28121999/code-server-astraluv:latest

# Specific CUDA + Ubuntu + flavor
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-base
docker pull danieldu28121999/code-server-astraluv:latest-cuda11.8-ubuntu22.04-base
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.6-ubuntu24.04-devel

# Pinned release
docker pull danieldu28121999/code-server-astraluv:v2.0.0-cuda12.8-ubuntu22.04-base
```

## CUDA Flavor Variants

| Variant | Size | Use Case |
|---------|------|----------|
| **base** | ~8 GB | Minimal CUDA runtime — inference, PyTorch, TensorFlow |
| **runtime** | ~10 GB | Full CUDA runtime libraries |
| **devel** | ~12 GB | Full toolkit with `nvcc` compiler — custom CUDA kernels |

## Features

- **Multi-CUDA GPU Support**: CUDA 11.8 through 12.8 on Ubuntu 22.04/24.04
- **Astral UV**: 10-100x faster than pip for Python package management
- **VS Code Server**: Full IDE in browser on port 8888
- **SSH Access**: Built-in OpenSSH for VS Code Remote SSH and JetBrains Gateway
- **No Python pre-installed**: Install any version via `uv python install 3.11`
- **Kubeflow Compliant**: `jovyan` user (UID 1000), port 8888, NB_PREFIX, s6-overlay
- **Security**: Non-root user, pubkey-only SSH, Trivy scanning

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
docker run -d -p 8888:8888 -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  danieldu28121999/code-server-astraluv:latest
ssh -p 2222 jovyan@localhost
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NB_USER` | `jovyan` | Username |
| `NB_PREFIX` | `/notebooks/jovyan` | Kubeflow URL prefix |
| `CODE_SERVER_AUTH` | `none` | Auth mode (`none` or `password`) |
| `CUDA_HOME` | `/usr/local/cuda` | CUDA path |

## Links

- **Source**: [GitHub](https://github.com/danghoangnhan/code-server-astraluv)
- **Wiki**: [Documentation](https://github.com/danghoangnhan/code-server-astraluv/wiki)
- **Issues**: [Bug Reports](https://github.com/danghoangnhan/code-server-astraluv/issues)
- **License**: MIT
