# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo is a **container image definition**, not a Python application. The primary artifact is the `Dockerfile` — a Kubeflow-compliant CUDA image with SSH access and Astral UV. Images are published to Harbor at `harbor.thinktron.co/sec1/code-server-astral-uv`.

The `pyproject.toml` at the repo root is an **example workspace file for end users**, not the project's own dependencies. It is consumed at container start by `s6/cont-init.d/03-setup-projects` if a user mounts it into `$HOME/project/`. Do not treat it as the project's deps.

## Common commands

Build, test, push (all wrap `docker`):

```bash
# Build a variant (base/runtime/devel; default base, CUDA 12.2.0, Ubuntu 22.04)
./scripts/build.sh latest --cuda-flavor base
./scripts/build.sh latest --cuda-flavor devel --cuda-version 12.8.1 --ubuntu-version 24.04

# Smoke test a built image (starts container, checks SSH/UV/jovyan/s6)
./scripts/test-local.sh

# Build + smoke-test all three variants (base, runtime, devel)
./scripts/test-build.sh

# Push to Harbor (uses HARBOR_USERNAME / HARBOR_PASSWORD env vars if set)
./scripts/push.sh latest

# One-shot: build + push + kubectl apply k8s/* (deploys to namespace kubeflow-user)
./deploy.sh harbor.thinktron.co/sec1
```

Pytest suite (`tests/`) — these tests **spawn the built image via `docker run`** and exec commands inside it. A built image at `harbor.thinktron.co/sec1/code-server-astral-uv:latest` (or `$HARBOR_REGISTRY/$HARBOR_PROJECT/code-server-astral-uv:latest`) must exist on the local Docker daemon first.

```bash
pytest tests/ -v                                  # all tests
pytest tests/test_image.py -v                     # one file
pytest tests/test_image.py::test_uv_installed -v  # one test
pytest tests/test_gpu.py -v -m gpu                # GPU-only (needs --gpus all working)
```

## High-level architecture

**Three layers, in build order:**

1. **`Dockerfile`** — multi-stage. Stage 1 copies the UV binary from `ghcr.io/astral-sh/uv`. Stage 2 builds on `nvidia/cuda:${CUDA_VERSION}-${CUDA_FLAVOR}-ubuntu${UBUNTU_VERSION}`, installs system deps + s6-overlay (with SHA256 verification), creates the `jovyan` user (UID 1000, GID 100, removing Ubuntu 24.04's preexisting `ubuntu` user at UID 1000), hardens sshd (pubkey-only, no root, `AllowUsers jovyan`, `AuthorizedKeysFile /etc/ssh/authorized_keys/%u`), and sets entrypoint to `/init` (s6).

2. **`s6/`** — s6-overlay process manager. `cont-init.d/` runs once at startup as root in numeric order: `01-configure-env` (perms, GPU detection), `02-configure-ssh` (chmod authorized_keys mounted from K8s Secret), `03-setup-projects` (`uv python install 3.13` + `uv sync` against `$HOME/project/pyproject.toml` if present, both via `s6-setuidgid jovyan`). `services.d/sshd/run` runs sshd in foreground as the long-lived service. **No Python or packages are baked into the image** — users install via UV at runtime.

3. **Deploy manifests** — two parallel sets:
   - `k8s/` — plain Kubernetes (Notebook CR + PVC + SSH Secret + LoadBalancer Service). Used by `deploy.sh`.
   - `kubeflow/` — Kubeflow-specific. `notebook.yaml` / `notebook-gpu.yaml` are Notebook CRs. `kubeflow/dashboard/` integrates with the Kubeflow Dashboard "New Notebook" form via a `jupyter-web-app-config` ConfigMap patch (image dropdown) plus PodDefaults for SSH key injection and `/dev/shm`.

**Kubeflow compliance is a hard constraint** enforced by tests in `tests/test_image.py`: user must be `jovyan`, UID `1000`, GID `100`, `$HOME=/home/jovyan`, `/init` (s6) as PID 1. SSH must be pubkey-only, no root, no password.

**SSH is the sole access method.** This was a deliberate migration (commit `567168a`) — code-server (browser IDE) was removed. Do not re-add code-server, JupyterLab, or any other long-running service to the Dockerfile; users install JupyterLab themselves via `uv pip install jupyterlab`.

## CI/CD: GitLab + Kaniko (not GitHub Actions, not local docker build)

`.gitlab-ci.yml` runs on a k3s Kubernetes runner (tag `k3s`) using `gcr.io/kaniko-project/executor`. There is no Docker daemon in CI — Kaniko builds rootless. Stages are `build → test → docs`.

- `build-main` — fires on `main` when `Dockerfile`, `s6/**`, `config/**`, or `scripts/build.sh` changes. Builds matrix: CUDA `[11.8.0, 12.1.1, 12.2.2, 12.4.1, 12.6.3, 12.8.1]` × Ubuntu 22.04, plus CUDA `[12.6.3, 12.8.1]` × Ubuntu 24.04. Tag prefix `latest`, only `base` flavor.
- `build-release` — fires on tags matching `vX.Y.Z`. Same matrix but builds all three CUDA flavors (`base`, `runtime`, `devel`) and tags with the version.
- `trivy-scan` — runs against the `cuda12.8-ubuntu22.04-base` image after `build-main` succeeds, severity CRITICAL/HIGH, `--ignore-unfixed`, `--exit-code 0` (informational).
- `test-image` — runs `pytest tests/test_image.py` **inside** the just-pushed image (the variant set by `TEST_TAG`, default `latest-cuda12.8-ubuntu22.04-base`). Because Kaniko/k3s has no Docker daemon, the job container *is* the image and tests use `subprocess.run(["bash", "-c", cmd])` directly. `tests/test_image.py:run_in_container` switches behavior on `RUN_IN_HOST=true`. Pytest is fetched ad-hoc via `uv run --no-project --with pytest`.

The `sync-wiki` job pushes `wiki/**` to the GitLab Wiki on every `main` commit that touches it. **The `wiki/` directory in this repo is the source of truth** — never edit the wiki repo directly.

The runner needs an `image_pull_secrets` (e.g., `harbor-pull-creds`) configured in `deploy/runner-values.yaml` so the `test-image` stage can pull our private Harbor image as its job container. Without this, the test stage fails with `ErrImagePull`.

## Things to be careful about

- **Don't bake Python or pip packages into the Dockerfile.** The minimal-base philosophy is enforced; image size is a CI/test concern. End users install Python and packages via UV at runtime.
- **Don't change the jovyan UID/GID/home.** Tests will fail and Kubeflow won't accept the image.
- **`uv.lock` is gitignored.** This is intentional — the example pyproject.toml is for end users, not for this repo.
- The `vscode-ssh-config` file at the repo root is a sample SSH config for end users — not project config.
