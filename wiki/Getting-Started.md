# Getting Started (5 Minutes)

Get the code-server-astraluv image running in just 5 minutes!

## Prerequisites

- Docker installed and running
- 8GB+ disk space (for image download)
- An SSH key pair (ed25519 recommended)
- (Optional) NVIDIA GPU with `nvidia-docker` or `docker --gpus`

## Option 1: Using Pre-Built Image (Fastest)

### 1. Pull from Harbor

```bash
docker pull harbor.thinktron.co/sec1/code-server-astral-uv:latest
```

### 2. Set Up SSH Keys

```bash
# Generate key pair (if you don't have one)
ssh-keygen -t ed25519 -C "kubeflow-notebook" -f ~/.ssh/kubeflow_ed25519

# Create authorized_keys directory
mkdir -p /tmp/ssh-keys
cp ~/.ssh/kubeflow_ed25519.pub /tmp/ssh-keys/jovyan
```

### 3. Run the Container

```bash
# Basic run (CPU only)
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest

# With GPU support
docker run -d --gpus all -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest

# With persistent storage
docker run -d -v $(pwd):/home/jovyan/project \
  -p 2222:22 --gpus all \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest
```

### 4. Connect via SSH

```bash
ssh -i ~/.ssh/kubeflow_ed25519 -p 2222 jovyan@localhost
```

### 5. VS Code Remote-SSH

Add to `~/.ssh/config`:
```
Host kubeflow-notebook
    HostName 127.0.0.1
    Port 2222
    User jovyan
    IdentityFile ~/.ssh/kubeflow_ed25519
    StrictHostKeyChecking no
```

Then in VS Code: `Ctrl+Shift+P` > `Remote-SSH: Connect to Host` > `kubeflow-notebook`

### 6. Install Python and Packages

In the SSH terminal or VS Code Remote terminal:

```bash
# Install Python (any version)
uv python install 3.11

# Install packages (10-100x faster than pip)
uv pip install pandas numpy matplotlib

# Optional: Install JupyterLab
uv pip install jupyterlab
jupyter lab --ip=0.0.0.0 --port=8889 --no-browser &
```

---

## Option 2: Build Locally

```bash
git clone https://github.com/danghoangnhan/code-server-astraluv.git
cd code-server-astraluv
./scripts/build.sh latest --cuda-flavor base
docker run -d -p 2222:22 \
  -v /tmp/ssh-keys:/etc/ssh/authorized_keys:ro \
  harbor.thinktron.co/sec1/code-server-astral-uv:latest
```

---

## First Steps Inside the Container

### Install Packages

```bash
uv --version                      # Verify UV is installed
uv python install 3.11            # Install Python
uv pip install pandas numpy       # Install packages
```

### Create a Virtual Environment

```bash
uv venv myenv
source myenv/bin/activate
uv pip install -r requirements.txt
```

### Check GPU (if available)

```bash
nvidia-smi
# PyTorch wheel URL depends on your CUDA version: cu118, cu121, cu124, cu126
uv pip install torch --index-url https://download.pytorch.org/whl/cu126
python -c "import torch; print(torch.cuda.is_available())"
```

---

## Common Commands

| Command | Purpose |
|---------|---------|
| `uv python install 3.11` | Install Python 3.11 |
| `uv pip install <package>` | Install Python package |
| `uv python list` | List available Python versions |
| `uv venv myenv` | Create virtual environment |
| `source myenv/bin/activate` | Activate environment |

---

## Next Steps

- **Learn more**: See [Usage Guide](Usage-Guide)
- **Deploy to Kubeflow**: See [Kubeflow Deployment](Kubeflow-Deployment)
- **CUDA variants**: See [Image Variants](Image-Variants)
- **Having issues?**: See [Troubleshooting](Troubleshooting)
