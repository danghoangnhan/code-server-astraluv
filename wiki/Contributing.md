# Contributing Guide

How to contribute to code-server-astraluv project.

---

## Getting Started

### Prerequisites

- Git knowledge
- Docker installed
- Python 3.10+ installed
- 30GB+ free disk space (for building)

### Clone Repository

```bash
git clone https://github.com/danghoangnhan/code-server-astraluv.git
cd code-server-astraluv
```

---

## Development Setup

### Local Build

Build the base variant:

```bash
./scripts/build.sh latest --cuda-flavor base
```

Takes 10-15 minutes first time (uses cache afterwards).

### Run Local Container

```bash
mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest
```

### Running Tests

```bash
# Install test dependencies
pip install pytest docker

# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_image.py -v

# Run with coverage
pytest tests/ --cov=. --cov-report=html
```

---

## Making Changes

### Code Style

- Python: Follow PEP 8
- Bash: Use ShellCheck
- Docker: Use best practices

### File Structure

```
code-server-astraluv/
├── Dockerfile              # Main image definition
├── scripts/
│   ├── build.sh           # Build script
│   ├── push.sh            # Harbor push script
│   └── test-*.sh          # Test scripts
├── s6/
│   ├── cont-init.d/       # Initialization scripts
│   └── services.d/        # Service definitions (sshd)
├── config/                # Configuration files
├── tests/                 # Python tests
│   ├── test_image.py      # Image tests
│   ├── test_kubeflow.py   # Kubeflow tests
│   └── test_gpu.py        # GPU tests
└── wiki/                  # Documentation
```

### Dockerfile Changes

When modifying `Dockerfile`:

1. Follow multi-stage pattern
2. Keep layers small
3. Group related commands
4. Document why changes
5. Test all CUDA variants

Example:

```dockerfile
# Install packages (group related installs)
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### Testing Your Changes

Always test locally before submitting:

```bash
# Build your changes
./scripts/build.sh test-build --cuda-flavor base

# Run all tests
pytest tests/ -v

# Test specific functionality
./scripts/test-local.sh

# Clean up
docker rmi harbor.thinktron.co/sec1/code-server-astral-uv:test-build-cuda12.8-ubuntu22.04-base
```

---

## Adding Features

### Adding a Python Package

1. Update `Dockerfile`:
```dockerfile
RUN uv pip install --system package-name
```

2. Add test in `tests/test_image.py`:
```python
def test_package_installed(running_container):
    result = running_container.exec_run("python -c 'import package'")
    assert result.exit_code == 0
```

3. Update documentation in `wiki/`

### Adding a Service

1. Create service in `s6/services.d/`:
```bash
mkdir -p s6/services.d/myservice
touch s6/services.d/myservice/run
chmod +x s6/services.d/myservice/run
```

2. Create service script:
```bash
#!/command/with-contenv bash
exec s6-setuidgid jovyan \
  /path/to/service --options
```

3. Test service starts:
```bash
docker run harbor.thinktron.co/sec1/code-server-astral-uv:latest pgrep -f myservice
```

### Adding GPU Support

Ensure changes work with GPU:

```bash
# If you have GPU
docker run --gpus all \
  -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest

# In container
nvidia-smi
```

---

## Creating Pull Requests

### Before Submitting

1. **Run tests**:
```bash
pytest tests/ -v --tb=short
./scripts/test-build.sh
```

2. **Check code quality**:
```bash
# Python
pylint scripts/*.py
black --check scripts/*.py

# Bash
shellcheck scripts/*.sh
```

3. **Update documentation**:
- Update `README.md` if needed
- Update wiki pages
- Add entry to CHANGELOG

### PR Title Format

Use descriptive titles:

- `feat: add Python 3.13 support`
- `fix: resolve SSH startup issue`
- `docs: update deployment guide`
- `chore: upgrade CUDA to 12.3`
- `test: add GPU memory monitoring tests`

### PR Description Template

```markdown
## Description
Brief description of changes

## Type
- [x] Feature
- [ ] Bug fix
- [ ] Documentation
- [ ] Performance improvement

## Changes
- Change 1
- Change 2
- Change 3

## Testing
- [x] Local tests pass
- [x] All CUDA variants tested
- [x] GPU tested (if applicable)

## Checklist
- [x] Documentation updated
- [x] Tests added/updated
- [x] No breaking changes
```

---

## Reporting Issues

### Issue Title Format

- `[BUG] Issue description`
- `[FEATURE REQUEST] Feature description`
- `[QUESTION] Question about usage`
- `[DOCUMENTATION] Missing/unclear docs`

### Issue Template

```markdown
## Description
Clear description of issue

## Reproduction Steps (for bugs)
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Docker version: output of `docker --version`
- GPU: Yes/No, if yes: output of `nvidia-smi`
- OS: Ubuntu 22.04 / Windows WSL / Mac M1 / etc
- Image variant: base / runtime / devel

## Logs/Output
Relevant error messages or logs
```

---

## Documentation

### Updating Wiki

Wiki pages in `wiki/`:
- [Home.md](Home) - Overview
- [Getting-Started.md](Getting-Started) - Quick start
- [Image-Variants.md](Image-Variants) - CUDA variants
- [Usage-Guide.md](Usage-Guide) - Detailed usage
- [Kubeflow-Deployment.md](Kubeflow-Deployment) - Kubeflow setup
- [Testing.md](Testing) - Testing procedures
- [Troubleshooting.md](Troubleshooting) - Common issues
- [Registry.md](Registry) - Harbor registry usage, auth, build pipeline
- [Contributing.md](Contributing) - Contributing guide

### Wiki Sync (GitLab CI)

`wiki/*.md` is the source of truth. The `.gitlab-ci.yml` `sync-wiki` job pushes these files to the GitLab Wiki on every commit to `main` that touches `wiki/**`.

**Runner**: k3s Kubernetes executor (tag `k3s`). Uses `alpine/git` image — no Kaniko needed for this job.

**Required CI variable**: `WIKI_PUSH_TOKEN` — a **Project Access Token** with `write_repository` scope. Store it **masked** and **protected** in *Settings → CI/CD → Variables*.

**One-time seed** (empty wiki):

```bash
git clone https://<your-host>/<path>.wiki.git
cp -r wiki/* <path>.wiki/
cd <path>.wiki && git add -A && git commit -m "Initial wiki" && git push
```

After the seed, every `main` push that changes `wiki/**` triggers CI and updates the wiki automatically.

### Documentation Style

- Use clear, concise language
- Include examples
- Add links to related sections
- Use consistent formatting
- Update table of contents

---

## Release Process

### Creating a Release

1. **Update version** in relevant files
2. **Update CHANGELOG**
3. **Create git tag**:
```bash
git tag -a v2.0.0 -m "Release v2.0.0"
git push origin v2.0.0
```

4. **GitLab CI** automatically (on tag push matching `vX.Y.Z`):
   - Builds the full image matrix via Kaniko
   - Pushes tagged images to Harbor (`harbor.thinktron.co/sec1/code-server-astral-uv`)
   - Trivy scans the default variant

### Version Scheme

Uses semantic versioning: `MAJOR.MINOR.PATCH`

- `2.0.0` - Major: Breaking changes
- `2.1.0` - Minor: New features
- `2.0.1` - Patch: Bug fixes

---

## Community Guidelines

### Be Respectful

- Treat all community members with respect
- Be open to feedback
- Assume good intent

### Help Others

- Answer questions in issues
- Share knowledge
- Review pull requests
- Help improve documentation

### Report Securely

For security issues:
- Do NOT create public issue
- Email: security@example.com (if available)
- Include: vulnerability description, impact, fix (if you have one)

---

## Resources

- **Repository**: https://github.com/danghoangnhan/code-server-astraluv
- **Issues**: https://github.com/danghoangnhan/code-server-astraluv/issues
- **Discussions**: https://github.com/danghoangnhan/code-server-astraluv/discussions
- **Harbor**: https://harbor.thinktron.co/harbor/projects (project `sec1`)

---

## Project Governance

**Maintainers**: danghoangnhan

- Final decision on PRs and issues
- Release management
- Direction and roadmap

**Contributors**: Anyone who helps

- Code contributions
- Bug reports
- Documentation improvements
- Community support

---

## Acknowledgments

Thanks to all contributors who help improve this project!

See [Contributors](https://github.com/danghoangnhan/code-server-astraluv/graphs/contributors)

---

**Questions?** Open an issue or start a discussion!
