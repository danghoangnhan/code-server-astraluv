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
docker run -p 8888:8888 \
  danieldu28121999/code-server-astraluv:latest
```

2. **Verify services are running**:

From another terminal:
```bash
# Check code-server
curl http://localhost:8888/

# Check JupyterLab
curl http://localhost:8889/
```

3. **Access in browser**:
- code-server: http://localhost:8888
- JupyterLab: http://localhost:8889

4. **Test Python**:

In terminal (Ctrl+` in code-server):
```bash
python --version
uv --version
```

5. **Stop container**:
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
- Python version
- UV installation
- code-server installation
- JupyterLab installation
- System dependencies

### Kubeflow Tests

Located in `tests/test_kubeflow.py`:

```bash
pytest tests/test_kubeflow.py -v
```

Tests:
- jovyan user
- NB_PREFIX handling
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
- Both services running
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

GitHub Actions workflow:
- Build image
- Run pytest suite
- Security scan with Trivy
- Upload to Docker Hub

View results:
```bash
# In GitHub repository
Actions → Docker Image CI → Latest run
```

---

## Manual Testing Checklist

### code-server Testing

- [ ] Access at http://localhost:8888
- [ ] Open file and run Python code
- [ ] Terminal works (Ctrl+`)
- [ ] Git integration works
- [ ] Install extension (test with Python extension)

### JupyterLab Testing

- [ ] Access at http://localhost:8889
- [ ] Create new notebook
- [ ] Execute Python code in cells
- [ ] Plot visualization with matplotlib
- [ ] Export notebook to PDF

### UV Testing

```bash
# Terminal in code-server or JupyterLab
uv --version
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
- [ ] Both code-server and JupyterLab accessible
- [ ] NB_PREFIX works correctly
- [ ] Storage persists after restart
- [ ] GPU enabled if configured

---

## Performance Testing

### Startup Time

```bash
time docker run -p 8888:8888 \
  code-server-astraluv:latest \
  sleep 60
```

Expected: ~30 seconds to container running

### Package Installation Speed

```bash
# Time UV vs pip
time uv pip install torch  # Expected: ~30-60 seconds
time pip install torch     # Expected: ~5-10 minutes
```

### Container Size

```bash
docker images | grep code-server-astraluv
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
trivy image danieldu28121999/code-server-astraluv:latest
```

Or in CI/CD (automatic with GitHub Actions):
- Trivy scans for CVEs
- Results in GitHub Security tab
- Checks CRITICAL and HIGH severity

### Non-root Verification

```bash
docker run code-server-astraluv:latest whoami
# Output: jovyan (not root)
```

### File Permissions

```bash
docker run code-server-astraluv:latest ls -la /home/jovyan/
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
docker run -v $(pwd):/logs code-server-astraluv:latest > /logs/startup.log 2>&1
```

### Services Not Responding

Wait 30 seconds for startup, then:
```bash
curl -v http://localhost:8888/
docker exec container-id curl -s http://localhost:8889/
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
