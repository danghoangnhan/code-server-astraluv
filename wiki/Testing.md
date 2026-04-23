# Testing Guide

Comprehensive testing procedures for code-server-astraluv.

---

## Quick Local Test (5 minutes)

### Prerequisites
- Docker installed and running
- ~10GB free disk space

### Steps

1. **Run the container**:
```bash
mkdir -p /tmp/ssh-keys && cp ~/.ssh/id_ed25519.pub /tmp/ssh-keys/jovyan
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest
```

2. **Verify SSH is running**:

From another terminal:
```bash
ssh -p 2222 jovyan@localhost
```

3. **Test Python**:

In the SSH session:
```bash
uv --version
uv python install 3.11
python --version
```

4. **Stop container**:
```bash
docker stop $(docker ps -q)
```

---

## Full Local Test Suite

### Prerequisites
- Clone repository
- Install pytest and Docker SDK

```bash
git clone https://github.com/danghoangnhan/code-server-astraluv.git
cd code-server-astraluv
pip install pytest docker
```

### Run All Tests

```bash
# Run Python tests
pytest tests/ -v

# Run shell tests
./scripts/test-local.sh

# Run GPU tests (requires GPU)
./scripts/test-gpu.sh

# Run build tests (tests all CUDA variants)
./scripts/test-build.sh
```

---

## Test Categories

### Unit Tests

Located in `tests/test_image.py`:

```bash
pytest tests/test_image.py -v
```

Tests:
- UV installation
- SSH server running
- System dependencies

### Kubeflow Tests

Located in `tests/test_kubeflow.py`:

```bash
pytest tests/test_kubeflow.py -v
```

Tests:
- jovyan user
- Port accessibility
- Container startup

### GPU Tests

Located in `tests/test_gpu.py`:

```bash
pytest tests/test_gpu.py -v -m gpu
```

Tests:
- NVIDIA GPU detection
- CUDA availability
- PyTorch GPU support
- Memory allocation

### Integration Tests

Full end-to-end tests in `tests/test_integration.py`:

```bash
pytest tests/test_integration.py -v
```

Tests:
- SSH service running
- Network connectivity
- Health checks
- Data persistence

---

## Build Variant Testing

### Test All CUDA Variants

```bash
./scripts/test-build.sh
```

This tests:
- base variant
- runtime variant
- devel variant

For each:
1. Build the image
2. Start container
3. Wait for services
4. Run smoke tests
5. Verify installations
6. Clean up

---

## CI/CD Testing

Tests run automatically on:
- Push to main branch
- Pull requests
- Release tags

GitLab CI pipeline (`.gitlab-ci.yml`):
- Build image via Kaniko on k3s runner
- Run pytest suite
- Security scan with Trivy
- Push to Harbor (`harbor.thinktron.co/sec1/code-server-astral-uv`)

View results:
```bash
# In GitLab project
CI/CD → Pipelines → Latest run
```

---

## Manual Testing Checklist

### SSH Testing

- [ ] SSH connection succeeds on port 22
- [ ] VS Code Remote-SSH connects successfully
- [ ] Terminal works in VS Code Remote
- [ ] File editing works
- [ ] Extensions install on remote host

### JupyterLab Testing (Optional)

- [ ] Install via `uv pip install jupyterlab`
- [ ] Access at exposed port
- [ ] Create new notebook
- [ ] Execute Python code in cells

### UV Testing

```bash
uv --version
uv python install 3.11
uv pip install pandas numpy
python -c "import pandas; print(pandas.__version__)"
```

### GPU Testing

```bash
# If GPU available
nvidia-smi

# Python GPU check
python -c "import torch; print(torch.cuda.is_available())"
```

### Kubeflow Testing

Deploy to Kubeflow and:
- [ ] Notebook starts in Kubeflow UI
- [ ] SSH accessible via LoadBalancer or port-forward
- [ ] Storage persists after restart
- [ ] GPU enabled if configured

---

## Performance Testing

### Startup Time

```bash
time docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest
```

Expected: ~20 seconds to container running

### Package Installation Speed

```bash
# Time UV vs pip
time uv pip install torch  # Expected: ~30-60 seconds
time pip install torch     # Expected: ~5-10 minutes
```

### Container Size

```bash
docker images | grep code-server-astral-uv
```

Expected sizes:
- base: ~8GB
- runtime: ~10GB
- devel: ~12GB

---

## Security Testing

### Vulnerability Scan

```bash
# Using Trivy locally
trivy image harbor.thinktron.co/sec1/code-server-astral-uv:latest
```

Or in CI/CD (automatic with GitLab CI):
- Trivy scans for CVEs on base variant
- Results as job log in the GitLab pipeline
- Checks CRITICAL and HIGH severity
- Harbor also runs its own vulnerability scan on pushed images

### Non-root Verification

```bash
docker run harbor.thinktron.co/sec1/code-server-astral-uv:latest whoami
# Output: jovyan (not root)
```

### File Permissions

```bash
docker run harbor.thinktron.co/sec1/code-server-astral-uv:latest ls -la /home/jovyan/
# Should show jovyan:users ownership
```

---

## Troubleshooting Test Failures

### Container Won't Start

```bash
# Check Docker logs
docker logs container-id

# Check disk space
df -h

# Try with verbose output
docker run -v $(pwd):/logs harbor.thinktron.co/sec1/code-server-astral-uv:latest > /logs/startup.log 2>&1
```

### SSH Not Responding

Wait 20 seconds for startup, then:
```bash
ssh -v -p 2222 jovyan@localhost
docker exec container-id pgrep -f sshd
```

### Tests Timeout

Increase timeout in pytest:
```bash
pytest tests/ -v --timeout=300
```

### GPU Test Fails

```bash
# Check Docker GPU support
docker run --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi

# Check NVIDIA Docker
nvidia-docker --version
```

---

## Coverage Report

Generate test coverage:

```bash
pytest tests/ --cov=. --cov-report=html
# Open htmlcov/index.html in browser
```

---

**Next Steps**: [Troubleshooting](Troubleshooting) | [Contributing](Contributing)
