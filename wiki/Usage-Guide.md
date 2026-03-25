# Usage Guide

Comprehensive guide for using code-server-astraluv in your daily workflows.

## Table of Contents

1. [SSH Access](#ssh-access)
2. [Package Management with UV](#package-management-with-uv)
3. [GPU Workflows](#gpu-workflows)
4. [JupyterLab (Optional)](#jupyterlab-optional)
5. [Working with Multiple Python Versions](#working-with-multiple-python-versions)
6. [Tips & Tricks](#tips--tricks)

---

## SSH Access

Connect your local VS Code (Remote-SSH extension) or JetBrains Gateway directly to the container.

### VS Code Remote-SSH

1. Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension locally
2. Add to `~/.ssh/config`:
   ```
   Host kubeflow-notebook
       HostName 127.0.0.1
       Port 2222
       User jovyan
       IdentityFile ~/.ssh/kubeflow_ed25519
       StrictHostKeyChecking no
       ServerAliveInterval 30
   ```
3. `Ctrl+Shift+P` > `Remote-SSH: Connect to Host` > `kubeflow-notebook`
4. Open `/home/jovyan` as workspace
5. Install any VS Code extensions you need — they run on the remote host

### JetBrains Gateway

1. Install JetBrains Gateway
2. Add SSH connection: `jovyan@127.0.0.1:2222`
3. Select IDE (PyCharm, IntelliJ, etc.)
4. Gateway installs the IDE backend inside the container

### File Transfer via SCP/SFTP

```bash
# Upload files
scp -P 2222 -i ~/.ssh/kubeflow_ed25519 local_file.py jovyan@localhost:/home/jovyan/

# Download files
scp -P 2222 -i ~/.ssh/kubeflow_ed25519 jovyan@localhost:/home/jovyan/results.csv ./

# SFTP session
sftp -P 2222 -i ~/.ssh/kubeflow_ed25519 jovyan@localhost
```

---

## Package Management with UV

UV is a modern Python package manager — **10-100x faster than pip**.

### Basic Commands

```bash
# Install Python (not pre-installed)
uv python install 3.11

# Install packages
uv pip install pandas numpy matplotlib

# Install specific version
uv pip install numpy==1.24.0

# Install from requirements file
uv pip install -r requirements.txt

# List installed packages
uv pip list
```

### Virtual Environments

```bash
# Create
uv venv myproject
source myproject/bin/activate

# Install packages
uv pip install -r requirements.txt

# Deactivate
deactivate
```

### Project Configuration (pyproject.toml)

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
    "pandas>=2.0.0",
    "numpy>=1.24.0",
    "torch>=2.0.0",
]
```

```bash
uv pip install -e .
```

---

## GPU Workflows

### Check GPU Availability

```bash
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"
```

### Install GPU Packages

```bash
# PyTorch wheel URL depends on your CUDA version: cu118, cu121, cu124, cu126
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

# TensorFlow with GPU
uv pip install tensorflow[and-cuda]
```

### GPU Example (PyTorch)

```python
import torch

x = torch.randn(1000, 1000, device='cuda')
y = torch.randn(1000, 1000, device='cuda')
z = torch.mm(x, y)

print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"Allocated: {torch.cuda.memory_allocated() / 1e9:.2f} GB")
```

---

## JupyterLab (Optional)

JupyterLab is not pre-installed. Install it when needed:

```bash
uv python install 3.11
uv pip install jupyterlab
jupyter lab --ip=0.0.0.0 --port=8889 --no-browser &
```

Access at http://localhost:8889 (expose port with `-p 8889:8889`).

---

## Working with Multiple Python Versions

```bash
# Install multiple versions
uv python install 3.11
uv python install 3.12

# Create venv with specific version
uv venv --python 3.12 py312-env
source py312-env/bin/activate

# List installed versions
uv python list
```

---

## Tips & Tricks

### Docker Compose

```yaml
services:
  notebook:
    image: danieldu28121999/code-server-astraluv:latest
    ports:
      - "2222:22"
    volumes:
      - ./project:/home/jovyan/project
      - ./ssh-keys:/etc/ssh/authorized_keys:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

### Resource Limits

```bash
docker run -m 16g --cpus 8 -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  danieldu28121999/code-server-astraluv:latest
```

### View Logs

```bash
docker logs -f container-name
```

---

**Next Steps**: [Kubeflow Deployment](Kubeflow-Deployment) | [Troubleshooting](Troubleshooting) | [Contributing](Contributing)
