#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HARBOR_REGISTRY="${HARBOR_REGISTRY:-harbor.thinktron.co}"
HARBOR_PROJECT="${HARBOR_PROJECT:-sec1}"
IMAGE_NAME="${HARBOR_REGISTRY}/${HARBOR_PROJECT}/code-server-astral-uv"
VERSION="${1:-latest}"
CUDA_VERSION="${CUDA_VERSION:-12.2.0}"
CUDA_FLAVOR="${CUDA_FLAVOR:-base}"
UBUNTU_VERSION="${UBUNTU_VERSION:-22.04}"

# Parse command line arguments
while [[ $# -gt 1 ]]; do
  case $2 in
    --cuda-flavor)
      CUDA_FLAVOR="$3"
      shift 2
      ;;
    --cuda-version)
      CUDA_VERSION="$3"
      shift 2
      ;;
    --ubuntu-version)
      UBUNTU_VERSION="$3"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Derive short CUDA version (e.g., 12.2.0 -> 12.2)
CUDA_SHORT="${CUDA_VERSION%.*}"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Building Kubeflow Notebook Docker Image ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Image:${NC} ${IMAGE_NAME}:${VERSION}"
echo -e "${GREEN}CUDA Version:${NC} ${CUDA_VERSION}"
echo -e "${GREEN}CUDA Flavor:${NC} ${CUDA_FLAVOR}"
echo -e "${GREEN}Ubuntu Version:${NC} ${UBUNTU_VERSION}"
echo -e "${YELLOW}─────────────────────────────────────────────${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Build the image
echo -e "${BLUE}Building image...${NC}"
docker build \
  --build-arg CUDA_VERSION="${CUDA_VERSION}" \
  --build-arg CUDA_FLAVOR="${CUDA_FLAVOR}" \
  --build-arg UBUNTU_VERSION="${UBUNTU_VERSION}" \
  --tag "${IMAGE_NAME}:${VERSION}-cuda${CUDA_SHORT}-ubuntu${UBUNTU_VERSION}-${CUDA_FLAVOR}" \
  --tag "${IMAGE_NAME}:${VERSION}" \
  --tag "${IMAGE_NAME}:latest" \
  --progress=plain \
  .

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Image built successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Image Details:${NC}"
    docker images "${IMAGE_NAME}:${VERSION}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  • Test locally: ${YELLOW}./scripts/test-local.sh${NC}"
    echo -e "  • Test GPU: ${YELLOW}./scripts/test-gpu.sh${NC}"
    echo -e "  • Push to registry: ${YELLOW}./scripts/push.sh ${VERSION}${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi
