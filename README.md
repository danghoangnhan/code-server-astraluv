# Kubeflow Notebook with Astral UV, SSH, and GPU Support

[![License](https://img.shields.io/github/license/danghoangnhan/code-server-astraluv)](https://github.com/danghoangnhan/code-server-astraluv/blob/main/LICENSE)

A minimal, production-ready Docker image for Kubeflow notebooks with GPU/CUDA support, Astral UV, and built-in SSH — connect via VS Code Remote-SSH or JetBrains Gateway.

Images are published to the internal Harbor registry: **`harbor.thinktron.co/sec1/code-server-astral-uv`**.

## Quick Start

```bash
docker login harbor.thinktron.co
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest

mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan

# Add --gpus all for GPU workloads
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest

ssh -p 2222 jovyan@localhost
```

## Documentation

Full documentation lives in the **Wiki**:

- **Home** — design philosophy, what's included, env vars, security
- **Getting Started** — 5-minute walkthrough
- **Usage Guide** — VS Code Remote-SSH, JetBrains Gateway, UV, GPU workflows
- **Image Variants** — CUDA 11.8–12.8, Ubuntu 22.04/24.04, base/runtime/devel
- **Kubeflow Deployment** — manifests, Dashboard UI, LoadBalancer SSH
- **Registry** — Harbor auth, tags, CI build pipeline
- **Troubleshooting** — common issues and fixes
- **Contributing** — dev setup, PRs, wiki sync

## License

MIT — see [LICENSE](LICENSE).
