# code-server-astraluv Wiki

Welcome to the **code-server-astraluv** project documentation! A minimal, production-ready Docker image for Kubeflow notebooks with GPU/CUDA support, Astral UV, VS Code Server, and built-in SSH access.

## Quick Links

- **[Getting Started](Getting-Started)** — 5-minute quick start guide
- **[Image Variants](Image-Variants)** — Understanding CUDA flavors
- **[Usage Guide](Usage-Guide)** — Using code-server, SSH, and UV
- **[Kubeflow Deployment](Kubeflow-Deployment)** — Deploy to Kubeflow clusters
- **[Testing](Testing)** — Comprehensive testing guide
- **[Troubleshooting](Troubleshooting)** — Common issues and solutions
- **[Contributing](Contributing)** — How to contribute

## Project Overview

### What is code-server-astraluv?

A minimal, production-ready Docker image combining:

| Component | Details |
|-----------|---------|
| **Base OS** | Ubuntu 22.04 |
| **GPU Support** | NVIDIA CUDA 12.2 |
| **IDE** | VS Code Server (code-server) on port 8888 |
| **SSH** | OpenSSH server on port 22 |
| **Package Manager** | Astral UV (10-100x faster than pip) |
| **Python** | Not pre-installed — install any version via UV |
| **Process Manager** | s6-overlay for multi-service |
| **Kubeflow** | Full compatibility (jovyan user, NB_PREFIX) |

### Key Features

**Minimal Image**
- No Python or packages pre-installed
- Install exactly what you need via UV
- Image stays small (~3-4 GB for base variant)

**Multiple IDE Options**
- VS Code Server (code-server) on port 8888 — enabled by default
- VS Code Remote SSH on port 22 — connect your local VS Code
- JupyterLab — optional, install via `uv pip install jupyterlab`

**SSH Access**
- Built-in OpenSSH server for VS Code Remote SSH and JetBrains Gateway
- Public key authentication only, no root login
- Addresses [kubeflow/notebooks#23](https://github.com/kubeflow/notebooks/issues/23)

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
Base Image:         nvidia/cuda:12.2.0-${CUDA_FLAVOR}-ubuntu22.04
User:               jovyan (UID: 1000, GID: 100)
Python:             Not pre-installed (install via UV)
code-server:        v4.96.2
s6-overlay:         v3.1.6.2
Ports Exposed:      8888 (code-server), 22 (SSH)
Registry:           Docker Hub (danieldu28121999/code-server-astraluv)
```

## CI/CD Pipeline

Automated with GitHub Actions:

- **Tag Releases**: Builds all 3 CUDA variants, pushes to Docker Hub, Trivy scanning
- **Main Branch**: Builds base variant on every push, runs security scans

## Quick Start

```bash
# Pull and run
docker pull danieldu28121999/code-server-astraluv:latest
docker run -p 8888:8888 --gpus all danieldu28121999/code-server-astraluv:latest

# Access code-server at http://localhost:8888
# Install Python: uv python install 3.11
# Install packages: uv pip install pandas numpy torch
```

## FAQ

**Q: Why no Python pre-installed?**
A: Keeps the image minimal. Install any version via `uv python install 3.11` (or 3.10, 3.12, etc.).

**Q: How do I connect VS Code Remote SSH?**
A: Mount your SSH public key and port-forward port 22. See [Getting Started](Getting-Started#ssh-access).

**Q: Which CUDA variant should I use?**
A: Start with `base` (smallest). Use `devel` only if compiling CUDA extensions.

## Support

- **Issues**: [GitHub Issues](https://github.com/danghoangnhan/code-server-astraluv/issues)
- **Wiki**: You're reading it!
- **License**: MIT

---

**Next Steps:**
- New to the project? Start with [Getting Started](Getting-Started)
- Ready to deploy? Check [Kubeflow Deployment](Kubeflow-Deployment)
- Have issues? See [Troubleshooting](Troubleshooting)
