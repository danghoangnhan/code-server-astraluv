"""Test GPU functionality"""
import subprocess
import pytest
import os

IMAGE_NAME = (
    os.getenv("HARBOR_REGISTRY", "harbor.thinktron.co")
    + "/"
    + os.getenv("HARBOR_PROJECT", "sec1")
    + "/code-server-astral-uv:latest"
)

# Configuration
GPU_COMMAND_TIMEOUT = 120


def check_gpu_available():
    """Check if GPUs are available on the system"""
    try:
        result = subprocess.run(
            ["docker", "run", "--rm", "--gpus", "all", "nvidia/cuda:12.2.0-runtime-ubuntu22.04", "nvidia-smi"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def run_gpu_container(command, timeout=GPU_COMMAND_TIMEOUT):
    """Execute command in GPU-enabled container"""
    try:
        result = subprocess.run(
            ["docker", "run", "--rm", "--gpus", "all", IMAGE_NAME, "bash", "-c", command],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result
    except subprocess.TimeoutExpired as e:
        # Create a result-like object for timeout errors
        class TimeoutResult:
            returncode = 1
            stdout = ""
            stderr = f"Command timed out after {timeout} seconds"

        return TimeoutResult()

@pytest.fixture(scope="module", autouse=True)
def check_gpu_support():
    """Check GPU availability before running tests"""
    gpu_available = check_gpu_available()
    if not gpu_available:
        pytest.skip("GPU not available or nvidia-docker2 not installed", allow_module_level=True)


@pytest.mark.gpu
def test_torch_installed():
    """Test PyTorch is installed"""
    result = run_gpu_container("python -c 'import torch; print(torch.__version__)'")
    assert result.returncode == 0, f"Failed to import PyTorch: {result.stderr}"
    print(f"✓ PyTorch version: {result.stdout.strip()}")

@pytest.mark.gpu
def test_cuda_available():
    """Test CUDA is available in PyTorch"""
    result = run_gpu_container("python -c 'import torch; print(torch.cuda.is_available())'")
    assert result.returncode == 0, f"Failed to check CUDA availability: {result.stderr}"
    assert "True" in result.stdout, f"CUDA not available: {result.stdout}"
    print(f"✓ CUDA is available")


@pytest.mark.gpu
def test_cuda_device_count():
    """Test CUDA device count"""
    result = run_gpu_container("python -c 'import torch; print(torch.cuda.device_count())'")
    assert result.returncode == 0, f"Failed to get device count: {result.stderr}"
    try:
        device_count = int(result.stdout.strip())
    except ValueError:
        pytest.fail(f"Invalid device count output: {result.stdout}")
    assert device_count > 0, f"No CUDA devices found"
    print(f"✓ CUDA device count: {device_count}")

@pytest.mark.gpu
def test_gpu_computation():
    """Test GPU computation works"""
    cmd = """python -c '
import torch
x = torch.rand(100, 100).cuda()
y = torch.rand(100, 100).cuda()
z = torch.matmul(x, y)
assert z.is_cuda
print("✓ GPU computation successful")
print(f"Device: {z.device}")
'"""
    result = run_gpu_container(cmd)
    assert result.returncode == 0, f"GPU computation failed: {result.stderr}"
    assert "successful" in result.stdout, f"Unexpected output: {result.stdout}"
    print(result.stdout.strip())


@pytest.mark.gpu
def test_cuda_version():
    """Test CUDA version"""
    result = run_gpu_container("python -c 'import torch; print(torch.version.cuda)'")
    assert result.returncode == 0, f"Failed to get CUDA version: {result.stderr}"
    print(f"✓ CUDA version: {result.stdout.strip()}")


@pytest.mark.gpu
def test_nvidia_smi():
    """Test nvidia-smi is accessible"""
    result = run_gpu_container("nvidia-smi --query-gpu=name --format=csv,noheader")
    assert result.returncode == 0, f"nvidia-smi failed: {result.stderr}"
    gpu_name = result.stdout.strip()
    assert gpu_name, "No GPU name returned"
    print(f"✓ GPU: {gpu_name}")


@pytest.mark.gpu
def test_gpu_memory_allocation():
    """Test GPU memory allocation"""
    cmd = """python -c '
import torch
tensor = torch.zeros(10, 10, 10).cuda()
memory_mb = torch.cuda.memory_allocated(0) / 1024**2
print(f"Memory allocated: {memory_mb:.2f} MB")
assert memory_mb > 0
'"""
    result = run_gpu_container(cmd)
    assert result.returncode == 0, f"Memory allocation test failed: {result.stderr}"
    print(f"✓ {result.stdout.strip()}")

if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s", "-m", "gpu"])
