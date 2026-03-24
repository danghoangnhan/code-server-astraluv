# Image Variants

Understanding the different CUDA and Ubuntu variants available for code-server-astraluv.

## Supported CUDA Versions

| CUDA Version | Ubuntu 22.04 | Ubuntu 24.04 | PyTorch Wheel Suffix |
|:---:|:---:|:---:|:---:|
| 11.8.0 | ✅ | ❌ | `cu118` |
| 12.1.1 | ✅ | ❌ | `cu121` |
| 12.2.2 | ✅ | ❌ | `cu121` |
| 12.4.1 | ✅ | ❌ | `cu124` |
| 12.6.3 | ✅ | ✅ | `cu126` |
| 12.8.1 | ✅ | ✅ | `cu126` |

> **Note**: Ubuntu 24.04 is only available for CUDA 12.6+. Ubuntu 22.04 is compatible with all CUDA versions.

## Tag Format

```
{version}-cuda{MAJOR.MINOR}-ubuntu{UBUNTU_VERSION}-{flavor}
```

Examples:
```
latest-cuda12.8-ubuntu22.04-base
latest-cuda11.8-ubuntu22.04-devel
v2.1.0-cuda12.6-ubuntu24.04-runtime
```

## CUDA Flavor Variants

The image is available with 3 different CUDA configurations optimized for different use cases:

### 1. Base Variant (Recommended Starting Point)

**Tag**: `latest-cuda12.8-ubuntu22.04-base`
**Size**: ~8GB
**CUDA Components**: Minimal runtime only

```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-base
```

**Best for:**
- GPU-accelerated inference
- Running pre-trained models
- Resource-constrained environments
- Most typical data science workflows

**What's included:**
- CUDA runtime libraries
- cuDNN (for neural networks)
- GPU utilities
- No compiler/development tools

### 2. Runtime Variant

**Tag**: `latest-cuda12.8-ubuntu22.04-runtime`
**Size**: ~10GB
**CUDA Components**: Full runtime library set

```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-runtime
```

**Best for:**
- Full CUDA functionality
- Installing CUDA packages from source
- When you need more CUDA libraries

**What's included:**
- Everything in base
- Additional CUDA runtime libraries
- More development utilities

### 3. Devel Variant

**Tag**: `latest-cuda12.8-ubuntu22.04-devel`
**Size**: ~12GB
**CUDA Components**: Full toolkit with compiler

```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-devel
```

**Best for:**
- Building CUDA extensions
- Compiling custom CUDA kernels
- Development and research
- Advanced GPU programming

**What's included:**
- Everything in runtime
- `nvcc` CUDA compiler
- CUDA headers
- Development libraries
- Documentation

## Comparison Table

| Feature | Base | Runtime | Devel |
|---------|------|---------|-------|
| **Size** | ~8GB | ~10GB | ~12GB |
| **CUDA Runtime** | ✅ | ✅ | ✅ |
| **cuDNN** | ✅ | ✅ | ✅ |
| **CUDA Compiler (nvcc)** | ❌ | ❌ | ✅ |
| **Build Tools** | ❌ | ❌ | ✅ |
| **GPU Inference** | ✅ | ✅ | ✅ |
| **Run PyTorch/TensorFlow** | ✅ | ✅ | ✅ |
| **Build CUDA Extensions** | ❌ | ❌ | ✅ |
| **Compile Custom Kernels** | ❌ | ❌ | ✅ |

## Choosing a Variant

### Decision Tree

```
Do you need to compile CUDA code?
  ├─ YES → Use DEVEL variant
  └─ NO
    └─ Do you have storage constraints?
       ├─ YES → Use BASE variant (smallest)
       └─ NO → Use BASE or RUNTIME (base recommended)
```

### Use Case Examples

**Machine Learning Inference**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-base
# → Run pre-trained models, no compilation needed
```

**Deep Learning Development**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-base
# → Most development work, inference-focused
```

**Research/Custom CUDA Kernels**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-devel
# → Need nvcc compiler for custom kernels
```

**Legacy GPU Support (older architectures)**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda11.8-ubuntu22.04-base
# → For Kepler, Maxwell, or older GPU architectures
```

**Latest Ubuntu with CUDA**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.6-ubuntu24.04-base
# → Ubuntu 24.04 with CUDA 12.6
```

## Python Version Information

All variants include:
- **UV** for installing and managing Python versions
- **No Python pre-installed** — install any version: `uv python install 3.11`
- Ability to install Python 3.10, 3.11, 3.12, or 3.13 via UV

```bash
# Install additional Python versions
uv python install 3.12
uv python install 3.10

# List installed versions
uv python list
```

## PyTorch CUDA Compatibility

Install PyTorch with the correct wheel for your CUDA version:

```bash
# CUDA 11.8
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# CUDA 12.1 / 12.2
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# CUDA 12.4
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# CUDA 12.6+
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
```

## Tagging Strategy

### Full Version Tags

When you pull an image, you get specific CUDA and Ubuntu variant tags:

```bash
# Full version with flavor
danieldu28121999/code-server-astraluv:v2.0.0-cuda12.8-ubuntu22.04-base

# Major.minor version with flavor
danieldu28121999/code-server-astraluv:2.0-cuda12.8-ubuntu22.04-base

# Latest with flavor
danieldu28121999/code-server-astraluv:latest-cuda12.8-ubuntu22.04-base

# Just latest (defaults to cuda12.8-ubuntu22.04-base)
danieldu28121999/code-server-astraluv:latest
```

## Building Specific Variants Locally

```bash
# Build base variant (default CUDA 12.2.0, Ubuntu 22.04)
./scripts/build.sh latest --cuda-flavor base

# Build with specific CUDA version
./scripts/build.sh latest --cuda-flavor base --cuda-version 11.8.0

# Build with specific CUDA and Ubuntu version
./scripts/build.sh latest --cuda-flavor devel --cuda-version 12.6.3 --ubuntu-version 24.04
```

## CUDA Version Information

```bash
# Check CUDA version in running container
docker run --gpus all code-server-astraluv:latest nvidia-smi
```

## Switching Between Variants

You can easily switch variants by updating the image tag:

```bash
# Currently using base with CUDA 12.8
docker run -it code-server-astraluv:latest-cuda12.8-ubuntu22.04-base bash

# Switch to devel for compilation
docker run -it code-server-astraluv:latest-cuda12.8-ubuntu22.04-devel bash

# Switch to older CUDA for legacy GPU support
docker run -it code-server-astraluv:latest-cuda11.8-ubuntu22.04-base bash
```

## Performance Comparison

| Metric | Base | Runtime | Devel |
|--------|------|---------|-------|
| Pull time | ~5 min | ~6 min | ~7 min |
| Container startup | ~20 sec | ~20 sec | ~25 sec |
| GPU operations | Same speed | Same speed | Same speed |
| Compilation speed | N/A | N/A | ~2-5 min per compile |

## Ubuntu and NVIDIA Versions

All variants use the same base components:
- **Ubuntu**: 22.04 LTS or 24.04 LTS
- **NVIDIA CUDA**: 11.8.0, 12.1.1, 12.2.2, 12.4.1, 12.6.3, or 12.8.1
- **cuDNN**: Latest compatible
- **Python**: Not pre-installed (install via UV)

## FAQ

**Q: Can I compile CUDA with base variant?**
A: No, you need the devel variant which includes the CUDA compiler (`nvcc`).

**Q: Will PyTorch work with base variant?**
A: Yes! Base variant includes everything needed for GPU-accelerated PyTorch.

**Q: What about TensorFlow?**
A: Yes, TensorFlow also works with all variants. GPU support included in base.

**Q: Can I upgrade from base to devel later?**
A: Yes, just pull the devel variant and run it. The images are independent.

**Q: Is base variant stable for production?**
A: Yes, all variants are production-ready with proper process management and security scanning.

**Q: Which CUDA version should I use?**
A: Use the latest (12.8) unless you have specific compatibility requirements. Use 11.8 for older GPU architectures.

**Q: Can I use Ubuntu 24.04 with CUDA 11.8?**
A: No, Ubuntu 24.04 is only available for CUDA 12.6 and newer.

## SSH Access

All variants include a built-in SSH server (OpenSSH) on port 22 for VS Code Remote SSH and JetBrains Gateway. See [Getting Started](Getting-Started#ssh-access) for setup.

## Recommendations

| Scenario | Variant |
|----------|---------|
| First time / unsure | base, cuda12.8, ubuntu22.04 |
| Limited disk space | base |
| Data science / ML | base |
| Research / development | base or devel |
| Building custom CUDA | devel |
| Older GPU architecture | base, cuda11.8 |
| Latest Ubuntu packages | base, cuda12.6+, ubuntu24.04 |
| Maximum compatibility | devel |

**Pro Tip**: Start with `base`. Upgrade to `devel` only if you need CUDA compilation!
