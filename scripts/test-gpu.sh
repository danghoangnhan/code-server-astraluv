#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="${DOCKER_HUB_USERNAME:-danieldu28121999}/code-server-astraluv"
VERSION="${1:-latest}"
CUDA_VERSION="${CUDA_VERSION:-12.2.0}"
UBUNTU_VERSION="${UBUNTU_VERSION:-22.04}"
CONTAINER_NAME="test-kubeflow-notebook-gpu"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Testing GPU Support in Docker Image     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if nvidia-docker is available
if ! command -v nvidia-smi &> /dev/null; then
  echo -e "${RED}✗ nvidia-smi not found. GPU testing requires NVIDIA drivers.${NC}"
  exit 1
fi

echo -e "${YELLOW}Host GPU Information:${NC}"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo ""

# Check if docker can access GPU
echo -e "${YELLOW}Testing Docker GPU access...${NC}"
if ! docker run --rm --gpus all nvidia/cuda:${CUDA_VERSION}-base-ubuntu${UBUNTU_VERSION} nvidia-smi &> /dev/null; then
  echo -e "${RED}✗ Docker cannot access GPU. Ensure nvidia-docker2 is installed.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Docker can access GPU${NC}"
echo ""

# Cleanup any existing container
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Run the container with GPU
echo -e "${BLUE}Starting container with GPU support...${NC}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  --gpus all \
  -p 8888:8888 \
  "${IMAGE_NAME}:${VERSION}"

sleep 15

# Test 1: Check nvidia-smi in container
echo ""
echo -e "${YELLOW}Test 1: NVIDIA-SMI in Container${NC}"
if docker exec "${CONTAINER_NAME}" nvidia-smi &> /dev/null; then
  echo -e "${GREEN}✓ nvidia-smi accessible${NC}"
  docker exec "${CONTAINER_NAME}" nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
  echo -e "${RED}✗ nvidia-smi not accessible${NC}"
  docker logs "${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}"
  exit 1
fi

# Test 2: Check CUDA availability in PyTorch
echo ""
echo -e "${YELLOW}Test 2: PyTorch CUDA Availability${NC}"
docker exec "${CONTAINER_NAME}" python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'Device count: {torch.cuda.device_count()}')
    print(f'Current device: {torch.cuda.current_device()}')
    print(f'Device name: {torch.cuda.get_device_name(0)}')
else:
    exit(1)
" && echo -e "${GREEN}✓ PyTorch CUDA is available${NC}" || {
  echo -e "${RED}✗ PyTorch CUDA not available${NC}"
  docker rm -f "${CONTAINER_NAME}"
  exit 1
}

# Test 3: Simple GPU computation
echo ""
echo -e "${YELLOW}Test 3: GPU Computation Test${NC}"
docker exec "${CONTAINER_NAME}" python -c "
import torch
import time

# Create tensors on GPU
x = torch.rand(1000, 1000).cuda()
y = torch.rand(1000, 1000).cuda()

# Perform computation
start = time.time()
z = torch.matmul(x, y)
end = time.time()

print(f'✓ GPU computation successful')
print(f'Result shape: {z.shape}')
print(f'Result device: {z.device}')
print(f'Computation time: {(end-start)*1000:.2f} ms')
" && echo -e "${GREEN}✓ GPU computation works${NC}" || {
  echo -e "${RED}✗ GPU computation failed${NC}"
  docker rm -f "${CONTAINER_NAME}"
  exit 1
}

# Test 4: Memory allocation test
echo ""
echo -e "${YELLOW}Test 4: GPU Memory Allocation${NC}"
docker exec "${CONTAINER_NAME}" python -c "
import torch

# Allocate memory
tensor = torch.zeros(100, 100, 100).cuda()
print(f'✓ Allocated tensor on GPU')
print(f'Tensor size: {tensor.shape}')
print(f'Tensor device: {tensor.device}')
print(f'Memory allocated: {torch.cuda.memory_allocated(0) / 1024**2:.2f} MB')
" && echo -e "${GREEN}✓ GPU memory allocation works${NC}" || {
  echo -e "${RED}✗ GPU memory allocation failed${NC}"
  docker rm -f "${CONTAINER_NAME}"
  exit 1
}

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        GPU tests passed! 🚀                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Cleaning up...${NC}"
docker rm -f "${CONTAINER_NAME}"
echo -e "${GREEN}✓ Container removed${NC}"
echo ""
