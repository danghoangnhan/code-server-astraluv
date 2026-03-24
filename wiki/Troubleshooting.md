# Troubleshooting Guide

Common issues and solutions for code-server-astraluv.

---

## Container Issues

### Container Won't Start

**Symptoms**: `docker run` fails or container exits immediately

**Solutions**:

1. Check disk space:
```bash
df -h  # Need at least 20GB free
```

2. Check Docker status:
```bash
docker ps -a
docker logs container-id
```

3. Pull image again:
```bash
docker pull danieldu28121999/code-server-astraluv:latest
```

4. Check Docker daemon:
```bash
docker info
```

---

### Out of Memory

**Symptoms**: Container crashes, OOM Killer messages

**Solutions**:

1. Increase memory limit:
```bash
docker run -m 16g \
  -p 8888:8888 \
  code-server-astraluv:latest
```

2. Reduce process count:
```bash
# Stop unused services
docker exec container-id ps aux
```

3. Clear cache:
```bash
docker exec container-name apt clean
docker exec container-name rm -rf ~/.cache
```

---

### Port Already in Use

**Symptoms**: `bind: address already in use` error

**Solutions**:

1. Find process using port:
```bash
lsof -i :8888
lsof -i :8889
```

2. Kill process:
```bash
kill -9 process-id
```

3. Use different ports:
```bash
docker run -p 9888:8888 -p 9889:8889 \
  code-server-astraluv:latest
```

---

## Service Issues

### code-server Not Responding

**Symptoms**: http://localhost:8888 times out or shows error

**Solutions**:

1. Wait for startup (30+ seconds)

2. Check if service is running:
```bash
docker exec container-name pgrep -f code-server
```

3. Check logs:
```bash
docker logs container-name | grep code-server
```

4. Restart container:
```bash
docker restart container-id
```

---

### JupyterLab Not Responding

**Symptoms**: http://localhost:8889 shows connection error

**Solutions**:

1. Wait for startup (30+ seconds)

2. Check if JupyterLab is running:
```bash
docker exec container-name pgrep -f "jupyter lab"
```

3. Check Jupyter logs:
```bash
docker logs container-name | grep -i jupyter
```

4. Test from inside container:
```bash
docker exec container-name curl -s http://localhost:8889/ | head
```

---

## GPU Issues

### GPU Not Detected

**Symptoms**: `nvidia-smi` fails or shows 0 GPUs

**Solutions**:

1. Check Docker GPU support:
```bash
docker run --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi
```

2. Ensure `--gpus` flag is used:
```bash
docker run --gpus all \
  -p 8888:8888 \
  code-server-astraluv:latest
```

3. Check NVIDIA Docker installation:
```bash
which nvidia-docker
nvidia-docker --version
```

4. Restart Docker daemon:
```bash
sudo systemctl restart docker
```

---

### CUDA Not Available in Python

**Symptoms**: `torch.cuda.is_available()` returns False

**Solutions**:

1. Install GPU package version:
```bash
# Wrong
uv pip install torch

# Correct
# PyTorch wheel URL depends on your CUDA version: cu118, cu121, cu124, cu126
uv pip install torch --index-url https://download.pytorch.org/whl/cu126
```

2. Verify container has GPU:
```bash
docker exec container-name nvidia-smi
```

3. Check CUDA version match:
```bash
# Container CUDA version
docker exec container-name nvcc --version

# PyTorch CUDA version
python -c "import torch; print(torch.version.cuda)"
```

---

## Performance Issues

### Slow Startup

**Causes**: Large image, slow network, disk I/O

**Solutions**:

1. Use base variant (smallest):
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-base
```

2. Pre-pull image:
```bash
docker pull image-name
# Then run immediately
```

3. Check disk speed:
```bash
dd if=/dev/zero of=test.img bs=1M count=100
```

---

### Slow Package Installation

**Causes**: Using `pip` instead of `uv`

**Solutions**:

1. Use UV (10-100x faster):
```bash
# Instead of: pip install package
# Use: uv pip install package
```

2. Use cache:
```bash
# First install: uv pip install -r requirements.txt
# Subsequent: much faster due to cache
```

---

### Slow Jupyter Notebooks

**Causes**: Large outputs, unsaved notebooks

**Solutions**:

1. Clear output:
```
Kernel → Restart Kernel and Clear All Outputs
```

2. Break into smaller notebooks

3. Use `_` variable for output suppression:
```python
_ = matplotlib_plot()  # Prevents display
```

---

## Storage Issues

### Files Lost After Restart

**Causes**: Not using persistent volume

**Solutions**:

1. Use volume mount:
```bash
docker run -v /path/to/data:/home/jovyan/project \
  -p 8888:8888 \
  code-server-astraluv:latest
```

2. For Kubeflow, use PersistentVolumeClaim

3. Backup important files:
```bash
docker cp container-id:/home/jovyan/project ./backup
```

---

### Permission Denied Errors

**Causes**: File ownership or permissions

**Solutions**:

1. Check ownership:
```bash
docker exec container-name ls -la /home/jovyan/project
```

2. Fix permissions:
```bash
docker exec container-name chown -R jovyan:users /home/jovyan/project
```

---

## Network Issues

### Cannot Reach Container from Host

**Causes**: Network configuration, firewall

**Solutions**:

1. Verify port mapping:
```bash
docker ps  # Check port mappings
```

2. Try localhost explicitly:
```bash
curl http://127.0.0.1:8888
# Not: http://0.0.0.0:8888
```

3. Check firewall:
```bash
sudo ufw allow 8888/tcp
sudo ufw allow 8889/tcp
```

---

### Kubeflow Notebook Not Accessible

**Causes**: NB_PREFIX routing, network policy

**Solutions**:

1. Check NB_PREFIX:
```bash
# In notebook terminal
echo $NB_PREFIX
```

2. Check pod logs:
```bash
kubectl logs -n kubeflow notebook/name
```

3. Port forward to test:
```bash
kubectl port-forward notebook/name 8888:8888 -n kubeflow
# Then access: http://localhost:8888
```

---

## Data Issues

### Large Files Fail to Upload

**Causes**: Timeout, memory, network size limits

**Solutions**:

1. Increase upload size limit (code-server):
```
Preferences → Extensions → Search "File" → Increase size
```

2. Use terminal to transfer:
```bash
# In container terminal
scp large-file.zip user@host:~/
```

3. Use volume mount for large files:
```bash
docker run -v /path/to/large-files:/home/jovyan/data \
  code-server-astraluv:latest
```

---

## Python/Package Issues

### Import Error for Installed Package

**Causes**: Wrong Python version, virtual environment issues

**Solutions**:

1. Check Python version:
```bash
python --version
```

2. Check where package installed:
```bash
python -c "import package; print(package.__file__)"
```

3. Reinstall package:
```bash
uv pip uninstall package
uv pip install package
```

---

### Virtual Environment Issues

**Causes**: Activation problems, wrong path

**Solutions**:

1. Create properly:
```bash
uv venv myenv
source myenv/bin/activate
```

2. Verify activation:
```bash
which python
# Should show: /path/to/myenv/bin/python
```

3. Check packages in environment:
```bash
pip list
```

---

## SSH Issues

### SSH Connection Refused

**Symptoms**: `ssh: connect to host localhost port 2222: Connection refused`

**Solutions**:

1. Check sshd is running:
```bash
docker exec container-name pgrep -f sshd
kubectl exec -it <pod> -- pgrep -f sshd
```

2. Verify port-forward is active (Kubeflow):
```bash
kubectl port-forward -n kubeflow-user svc/pytorch-ssh-notebook-ssh 2222:22 &
```

3. Verify port mapping (Docker):
```bash
docker ps  # Check 2222:22 mapping
```

---

### SSH Permission Denied (publickey)

**Symptoms**: `Permission denied (publickey)` when connecting

**Solutions**:

1. Verify keys are mounted:
```bash
docker exec container-name cat /etc/ssh/authorized_keys/jovyan
kubectl exec -it <pod> -- cat /etc/ssh/authorized_keys/jovyan
```

2. Check file permissions:
```bash
docker exec container-name ls -la /etc/ssh/authorized_keys/
# Directory should be 755, files should be 644
```

3. Verify you're using the correct private key:
```bash
ssh -i ~/.ssh/kubeflow_ed25519 -p 2222 jovyan@localhost -v
```

---

## Getting Help

If issue persists:

1. **Check logs**:
```bash
docker logs container-name
kubectl logs notebook-name -n kubeflow-user
```

2. **Run diagnostics**:
```bash
docker exec container-name nvidia-smi
docker exec container-name pgrep -f sshd
docker exec container-name pgrep -f code-server
```

3. **Report issue**:
- Visit: https://github.com/danghoangnhan/code-server-astraluv/issues
- Include: Error message, commands run, output of diagnostics

---

**Next Steps**: [Contributing](Contributing)
