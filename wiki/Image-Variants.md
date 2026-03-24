# Image Variants

Understanding the different CUDA variants available for code-server-astraluv.

## CUDA Flavor Variants

The image is available with 3 different CUDA configurations optimized for different use cases:

### 1. Base Variant (Recommended Starting Point)

**Tag**: `latest-cuda12.2-base` or `v2.0.0-cuda12.2-base`
**Size**: ~8GB
**CUDA Components**: Minimal runtime only

```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.2-base
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

**Tag**: `latest-cuda12.2-runtime`
**Size**: ~10GB
**CUDA Components**: Full runtime library set

```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.2-runtime
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

**Tag**: `latest-cuda12.2-devel`
**Size**: ~12GB
**CUDA Components**: Full toolkit with compiler

```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.2-devel
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
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.2-base
# → Run pre-trained models, no compilation needed
```

**Deep Learning Development**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.2-base
# → Most development work, inference-focused
```

**Research/Custom CUDA Kernels**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.2-devel
# → Need nvcc compiler for custom kernels
```

**Limited Storage Environment**
```bash
docker pull danieldu28121999/code-server-astraluv:latest-cuda12.2-base
# → Minimize disk usage with base variant
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

## Tagging Strategy

### Full Version Tags

When you pull an image, you get specific CUDA variant tags:

```bash
# Full version with flavor
danieldu28121999/code-server-astraluv:v2.0.0-cuda12.2-base

# Just version (defaults to base)
danieldu28121999/code-server-astraluv:v2.0.0

# Major.minor version with flavor
danieldu28121999/code-server-astraluv:2.0-cuda12.2-base

# Latest with flavor
danieldu28121999/code-server-astraluv:latest-cuda12.2-base

# Just latest (defaults to base)
danieldu28121999/code-server-astraluv:latest
```

## Building Specific Variants Locally

```bash
# Build base variant
./scripts/build.sh latest --cuda-flavor base

# Build runtime variant
./scripts/build.sh latest --cuda-flavor runtime

# Build devel variant
./scripts/build.sh latest --cuda-flavor devel
```

## CUDA Version Information

All variants use **CUDA 12.2.0**:

```bash
# Check CUDA version in running container
docker run --gpus all code-server-astraluv:latest nvidia-smi
```

## Switching Between Variants

You can easily switch variants by updating the image tag:

```bash
# Currently using base
docker run -it code-server-astraluv:latest-cuda12.2-base bash

# Switch to devel for compilation
docker run -it code-server-astraluv:latest-cuda12.2-devel bash
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
- **Ubuntu**: 22.04 LTS
- **NVIDIA CUDA**: 12.2.0
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

## SSH Access

All variants include a built-in SSH server (OpenSSH) on port 22 for VS Code Remote SSH and JetBrains Gateway. See [Getting Started](Getting-Started#ssh-access) for setup.

## Recommendations

| Scenario | Variant |
|----------|---------|
| First time / unsure | base |
| Limited disk space | base |
| Data science / ML | base |
| Research / development | base or devel |
| Building custom CUDA | devel |
| Minimal requirements | base |
| Maximum compatibility | devel |

**Pro Tip**: Start with `base`. Upgrade to `devel` only if you need CUDA compilation!
