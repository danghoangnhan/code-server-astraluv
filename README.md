# Kubeflow Notebook with Astral UV, SSH, and GPU Support

[![CI](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/docker-build-main.yml/badge.svg)](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/docker-build-main.yml)
[![Release](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/danghoangnhan/code-server-astraluv/actions/workflows/build-and-push.yml)
[![Docker Hub](https://img.shields.io/docker/v/danieldu28121999/code-server-astraluv?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/danieldu28121999/code-server-astraluv)
[![GitHub](https://img.shields.io/github/license/danghoangnhan/code-server-astraluv)](https://github.com/danghoangnhan/code-server-astraluv/blob/main/LICENSE)

A minimal, production-ready Docker image for Kubeflow notebooks with GPU/CUDA support, Astral UV, and built-in SSH — connect via VS Code Remote-SSH or JetBrains Gateway.

## Quick Start

```bash
docker pull danieldu28121999/code-server-astraluv:latest

mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan

# Add --gpus all for GPU workloads
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  danieldu28121999/code-server-astraluv:latest

ssh -p 2222 jovyan@localhost
```

## Documentation

Full documentation lives in the **[Wiki](https://github.com/danghoangnhan/code-server-astraluv/wiki)**:

- **[Home](https://github.com/danghoangnhan/code-server-astraluv/wiki/Home)** — design philosophy, what's included, env vars, security
- **[Getting Started](https://github.com/danghoangnhan/code-server-astraluv/wiki/Getting-Started)** — 5-minute walkthrough
- **[Usage Guide](https://github.com/danghoangnhan/code-server-astraluv/wiki/Usage-Guide)** — VS Code Remote-SSH, JetBrains Gateway, UV, GPU workflows
- **[Image Variants](https://github.com/danghoangnhan/code-server-astraluv/wiki/Image-Variants)** — CUDA 11.8–12.8, Ubuntu 22.04/24.04, base/runtime/devel
- **[Kubeflow Deployment](https://github.com/danghoangnhan/code-server-astraluv/wiki/Kubeflow-Deployment)** — manifests, Dashboard UI, LoadBalancer SSH
- **[Troubleshooting](https://github.com/danghoangnhan/code-server-astraluv/wiki/Troubleshooting)** — common issues and fixes
- **[Contributing](https://github.com/danghoangnhan/code-server-astraluv/wiki/Contributing)** — dev setup, PRs, wiki sync

## License

MIT — see [LICENSE](LICENSE).

## Support

- [GitHub Issues](https://github.com/danghoangnhan/code-server-astraluv/issues)
- [Wiki](https://github.com/danghoangnhan/code-server-astraluv/wiki)
- [Kubeflow Docs](https://www.kubeflow.org/docs/components/notebooks/)
