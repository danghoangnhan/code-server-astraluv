# code-server-astraluv Wiki

Welcome to the **code-server-astraluv** project documentation! A minimal, production-ready Docker image for Kubeflow notebooks with GPU/CUDA support, Astral UV, and built-in SSH access.

## Quick Links

- **[Getting Started](Getting-Started)** — 5-minute quick start guide
- **[Image Variants](Image-Variants)** — Understanding CUDA flavors
- **[Usage Guide](Usage-Guide)** — Using SSH and UV
- **[Kubeflow Deployment](Kubeflow-Deployment)** — Deploy to Kubeflow clusters
- **[Testing](Testing)** — Comprehensive testing guide
- **[Troubleshooting](Troubleshooting)** — Common issues and solutions
- **[Registry](Registry)** — Harbor registry (pulls, tags, build pipeline)
- **[Contributing](Contributing)** — How to contribute

## Design Philosophy

This is a **minimal base image** — no Python or packages are pre-installed. Users install exactly what they need using UV, which is 10-100x faster than pip. This approach:

- Keeps the image small (~3-4 GB vs 8-12 GB)
- Avoids dependency conflicts
- Lets users choose exact Python and package versions
- Supports multiple Python versions via UV

## Project Overview

### What is code-server-astraluv?

A minimal, production-ready Docker image combining:

| Component | Details |
|-----------|---------|
| **Base OS** | Ubuntu 22.04 |
| **GPU Support** | NVIDIA CUDA 11.8–12.8 |
| **IDE Access** | VS Code Remote-SSH on port 22 |
| **Package Manager** | Astral UV (10-100x faster than pip) |
| **Python** | Not pre-installed — install any version via UV |
| **Process Manager** | s6-overlay for multi-service |
| **Kubeflow** | Full compatibility (jovyan user) |

### Key Features

**Minimal Image**
- No Python or packages pre-installed
- Install exactly what you need via UV
- Image stays small (~3-4 GB for base variant)

**SSH Access (Primary IDE Method)**
- Built-in OpenSSH server for VS Code Remote-SSH and JetBrains Gateway
- Connect your local VS Code with full extension support
- Public key authentication only, no root login
- Addresses [kubeflow/notebooks#23](https://github.com/kubeflow/notebooks/issues/23)

**Optional JupyterLab**
- Install via `uv pip install jupyterlab`

**CUDA Variants**
- `base`: Minimal runtime (~3-4 GB)
- `runtime`: Full runtime (~10 GB)
- `devel`: Development toolkit (~12 GB)

**Production Ready**
- Non-root user (jovyan, UID 1000)
- Trivy security scanning
- s6-overlay process management
- Health checks configured

## Image Specifications

```
Name:               code-server-astraluv
Base Image:         nvidia/cuda:${CUDA_VERSION}-${CUDA_FLAVOR}-ubuntu${UBUNTU_VERSION}
User:               jovyan (UID: 1000, GID: 100)
Python:             Not pre-installed (install via UV)
s6-overlay:         v3.1.6.2
Ports Exposed:      22 (SSH)
Registry:           harbor.thinktron.co/sec1/code-server-astral-uv (Harbor)
```

## What's Included

| Category | Components |
|----------|-----------|
| **Pre-installed** | Astral UV & uvx, OpenSSH server, s6-overlay |
| **System tools** | CUDA (configurable: 11.8–12.8), git, wget, curl, vim, htop, build-essential |
| **Not included** | Python, JupyterLab, Python packages — install via UV as needed |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NB_USER` | `jovyan` | Username (Kubeflow requirement) |
| `NB_UID` | `1000` | User ID |
| `NB_GID` | `100` | Group ID |
| `CUDA_HOME` | `/usr/local/cuda` | CUDA installation path |
| `UV_PYTHON_PREFERENCE` | `managed` | UV uses managed Python |

## Security

- Runs as non-root user (`jovyan`)
- SSH: pubkey-only, no root login, `AllowUsers jovyan`
- Weekly Trivy security scans
- SBOM generation for supply chain security
- No hardcoded secrets
- UV copied from official verified image

## CI/CD Pipeline

Automated with GitLab CI + Kaniko (k3s runner):

- **Tag Releases** (`vX.Y.Z`): Builds the full matrix (base/runtime/devel × CUDA × Ubuntu), pushes to Harbor
- **Main Branch**: Builds base variant across CUDA/Ubuntu combos on every push that touches Dockerfile or build inputs
- **Wiki Sync**: `wiki/**` pushed to the GitLab Wiki on every main commit

## Quick Start

```bash
# Pull and run with SSH
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest

mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest

# Connect via SSH
ssh -p 2222 jovyan@localhost

# Install Python: uv python install 3.11
# Install packages: uv pip install pandas numpy torch
```

## FAQ

**Q: Why no Python pre-installed?**
A: Keeps the image minimal. Install any version via `uv python install 3.11` (or 3.10, 3.12, etc.).

**Q: How do I connect VS Code Remote-SSH?**
A: Mount your SSH public key and connect via port 22. See [Getting Started](Getting-Started#ssh-access).

**Q: Which CUDA variant should I use?**
A: Start with `base` (smallest). Use `devel` only if compiling CUDA extensions.

## Support

- **Issues**: [GitHub Issues](https://github.com/danghoangnhan/code-server-astraluv/issues)
- **Wiki**: You're reading it!
- **License**: MIT

## Acknowledgments

- [NVIDIA CUDA](https://hub.docker.com/r/nvidia/cuda) base images
- [Astral UV](https://github.com/astral-sh/uv) official Docker image
- [s6-overlay](https://github.com/just-containers/s6-overlay) process management

---

**Next Steps:**
- New to the project? Start with [Getting Started](Getting-Started)
- Ready to deploy? Check [Kubeflow Deployment](Kubeflow-Deployment)
- Have issues? See [Troubleshooting](Troubleshooting)
