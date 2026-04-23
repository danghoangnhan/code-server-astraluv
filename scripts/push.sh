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

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Pushing Image to Harbor                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Registry:${NC} ${HARBOR_REGISTRY}"
echo -e "${GREEN}Image:${NC} ${IMAGE_NAME}:${VERSION}"
echo -e "${YELLOW}─────────────────────────────────────────────${NC}"
echo ""

# Check if image exists locally
if ! docker images "${IMAGE_NAME}:${VERSION}" --format '{{.Repository}}' | grep -q "${IMAGE_NAME}"; then
  echo -e "${RED}✗ Image ${IMAGE_NAME}:${VERSION} not found locally${NC}"
  echo -e "${YELLOW}Please build the image first: ./scripts/build.sh ${VERSION}${NC}"
  exit 1
fi

# Check Harbor login
if ! docker info 2>/dev/null | grep -q "${HARBOR_REGISTRY}" && ! grep -q "${HARBOR_REGISTRY}" ~/.docker/config.json 2>/dev/null; then
  echo -e "${YELLOW}Not logged in to ${HARBOR_REGISTRY}. Attempting login...${NC}"
  if [ -n "${HARBOR_USERNAME}" ] && [ -n "${HARBOR_PASSWORD}" ]; then
    echo "${HARBOR_PASSWORD}" | docker login "${HARBOR_REGISTRY}" -u "${HARBOR_USERNAME}" --password-stdin
  else
    docker login "${HARBOR_REGISTRY}"
  fi
  echo ""
fi

# Get image size
IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${VERSION}" --format '{{.Size}}')
echo -e "${BLUE}Image size: ${IMAGE_SIZE}${NC}"
echo ""

# Push the image
echo -e "${BLUE}Pushing ${IMAGE_NAME}:${VERSION}...${NC}"
docker push "${IMAGE_NAME}:${VERSION}"

# If not latest, also tag and push as latest
if [ "${VERSION}" != "latest" ]; then
  echo ""
  echo -e "${BLUE}Tagging as latest...${NC}"
  docker tag "${IMAGE_NAME}:${VERSION}" "${IMAGE_NAME}:latest"

  echo -e "${BLUE}Pushing ${IMAGE_NAME}:latest...${NC}"
  docker push "${IMAGE_NAME}:latest"
fi

# Success
echo ""
echo -e "${GREEN}✓ Image pushed successfully!${NC}"
echo ""
echo -e "${BLUE}Image Details:${NC}"
echo -e "  • Repository: ${IMAGE_NAME}"
echo -e "  • Tag: ${VERSION}"
echo -e "  • Size: ${IMAGE_SIZE}"
echo ""
echo -e "${BLUE}Pull Commands:${NC}"
echo -e "  ${YELLOW}docker pull ${IMAGE_NAME}:${VERSION}${NC}"
if [ "${VERSION}" != "latest" ]; then
  echo -e "  ${YELLOW}docker pull ${IMAGE_NAME}:latest${NC}"
fi
echo ""
echo -e "${BLUE}Use in Kubeflow:${NC}"
echo -e "  Update your notebook YAML with:"
echo -e "  ${YELLOW}image: ${IMAGE_NAME}:${VERSION}${NC}"
echo ""
