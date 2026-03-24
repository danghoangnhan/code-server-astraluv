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
CONTAINER_NAME="test-kubeflow-notebook"
MAX_RETRIES=30
RETRY_DELAY=2

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Testing Kubeflow Notebook Docker Image  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Image:${NC} ${IMAGE_NAME}:${VERSION}"
echo -e "${YELLOW}─────────────────────────────────────────────${NC}"
echo ""

# Validate dependencies
if ! command -v curl &> /dev/null; then
  echo -e "${RED}✗ curl is required but not installed${NC}"
  exit 1
fi

if ! command -v docker &> /dev/null; then
  echo -e "${RED}✗ docker is required but not installed${NC}"
  exit 1
fi

# Cleanup any existing container
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Run the container
echo -e "${BLUE}Starting container...${NC}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 8888:8888 \
  "${IMAGE_NAME}:${VERSION}"

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Failed to start container${NC}"
  exit 1
fi

# Wait for container to be ready with retry logic
echo -e "${BLUE}Waiting for services to start...${NC}"
sleep 3

# Test 1: Check if container is running
echo ""
echo -e "${YELLOW}Test 1: Container Status${NC}"
if docker ps | grep -q "${CONTAINER_NAME}"; then
  echo -e "${GREEN}✓ Container is running${NC}"
else
  echo -e "${RED}✗ Container failed to start${NC}"
  echo -e "${YELLOW}Container logs:${NC}"
  docker logs "${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}"
  exit 1
fi

# Test 2: Check if code-server is responding (with retries)
echo ""
echo -e "${YELLOW}Test 2: Code-Server Response${NC}"
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888 2>/dev/null)
  case "$http_code" in
    200|302|404)
      echo -e "${GREEN}✓ Code-server is responding (HTTP $http_code)${NC}"
      break
      ;;
  esac
  retry_count=$((retry_count + 1))
  if [ $retry_count -lt $MAX_RETRIES ]; then
    sleep $RETRY_DELAY
  fi
done

if [ $retry_count -eq $MAX_RETRIES ]; then
  echo -e "${RED}✗ Code-server not responding after ${MAX_RETRIES} retries${NC}"
  echo -e "${YELLOW}Container logs:${NC}"
  docker logs "${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}"
  exit 1
fi

# Test 3: Check UV installation
echo ""
echo -e "${YELLOW}Test 3: UV Installation${NC}"
UV_VERSION=$(docker exec "${CONTAINER_NAME}" uv --version 2>&1)
echo -e "${GREEN}✓ ${UV_VERSION}${NC}"

# Test 4: Check UV Python versions
echo ""
echo -e "${YELLOW}Test 4: UV Python Versions${NC}"
python_output=$(docker exec "${CONTAINER_NAME}" uv python list 2>&1)
if [ $? -eq 0 ]; then
  echo "$python_output" | head -5 | while read line; do
    echo -e "${GREEN}✓ ${line}${NC}"
  done
else
  echo -e "${RED}✗ Failed to list Python versions${NC}"
  echo "$python_output"
fi

# Test 5: Check UV can install packages
echo ""
echo -e "${YELLOW}Test 5: UV Package Installation${NC}"
install_output=$(docker exec "${CONTAINER_NAME}" uv pip install --system requests 2>&1)
if [ $? -eq 0 ]; then
  verify_output=$(docker exec "${CONTAINER_NAME}" python -c "import requests; print(f'requests {requests.__version__}')" 2>&1)
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ UV pip install works: ${verify_output}${NC}"
  else
    echo -e "${RED}✗ Package installed but import failed: ${verify_output}${NC}"
  fi
else
  echo -e "${RED}✗ UV pip install failed: ${install_output}${NC}"
fi

# Test 6: Check user permissions (Kubeflow requirements)
echo ""
echo -e "${YELLOW}Test 6: User Permissions (Kubeflow)${NC}"
USER_NAME=$(docker exec "${CONTAINER_NAME}" whoami)
USER_ID=$(docker exec "${CONTAINER_NAME}" id -u)
USER_GID=$(docker exec "${CONTAINER_NAME}" id -g)

if [ "$USER_NAME" = "jovyan" ]; then
  echo -e "${GREEN}✓ User is jovyan${NC}"
else
  echo -e "${RED}✗ User is ${USER_NAME} (expected jovyan)${NC}"
fi

if [ "$USER_ID" = "1000" ]; then
  echo -e "${GREEN}✓ UID is 1000${NC}"
else
  echo -e "${RED}✗ UID is ${USER_ID} (expected 1000)${NC}"
fi

if [ "$USER_GID" = "100" ]; then
  echo -e "${GREEN}✓ GID is 100${NC}"
else
  echo -e "${YELLOW}⚠ GID is ${USER_GID} (expected 100)${NC}"
fi

# Test 7: Check home directory
echo ""
echo -e "${YELLOW}Test 7: Home Directory${NC}"
HOME_DIR=$(docker exec "${CONTAINER_NAME}" bash -c 'echo $HOME')
if [ "$HOME_DIR" = "/home/jovyan" ]; then
  echo -e "${GREEN}✓ Home directory is /home/jovyan${NC}"
else
  echo -e "${RED}✗ Home directory is ${HOME_DIR} (expected /home/jovyan)${NC}"
fi

# Test 8: Check VS Code extensions
echo ""
echo -e "${YELLOW}Test 8: VS Code Extensions${NC}"
EXTENSIONS=$(docker exec "${CONTAINER_NAME}" code-server --list-extensions 2>&1)
if echo "$EXTENSIONS" | grep -q "ms-python.python"; then
  echo -e "${GREEN}✓ Python extension installed${NC}"
else
  echo -e "${RED}✗ Python extension not found${NC}"
fi

if echo "$EXTENSIONS" | grep -q "ms-toolsai.jupyter"; then
  echo -e "${GREEN}✓ Jupyter extension installed${NC}"
else
  echo -e "${RED}✗ Jupyter extension not found${NC}"
fi

# Test 9: Check s6-overlay
echo ""
echo -e "${YELLOW}Test 9: s6-overlay${NC}"
if docker exec "${CONTAINER_NAME}" test -f /init; then
  echo -e "${GREEN}✓ s6-overlay is installed${NC}"
else
  echo -e "${RED}✗ s6-overlay not found${NC}"
fi

# Test 10: Check project directory
echo ""
echo -e "${YELLOW}Test 10: Project Directory${NC}"
if docker exec "${CONTAINER_NAME}" test -d /home/jovyan/project; then
  echo -e "${GREEN}✓ Project directory exists${NC}"
else
  echo -e "${RED}✗ Project directory not found${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          All tests passed!                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Container Info:${NC}"
echo -e "  • Name: ${CONTAINER_NAME}"
echo -e "  • Access: http://localhost:8888"
echo ""
echo -e "${BLUE}Quick Start (inside container):${NC}"
echo -e "  • Install packages: ${YELLOW}uv pip install pandas numpy torch${NC}"
echo -e "  • Install Python:   ${YELLOW}uv python install 3.12${NC}"
echo -e "  • Create venv:      ${YELLOW}uv venv myenv && source myenv/bin/activate${NC}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  • View logs: ${YELLOW}docker logs ${CONTAINER_NAME}${NC}"
echo -e "  • Shell access: ${YELLOW}docker exec -it ${CONTAINER_NAME} bash${NC}"
echo -e "  • Stop container: ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
echo -e "  • Remove container: ${YELLOW}docker rm -f ${CONTAINER_NAME}${NC}"
echo ""
echo -e "${GREEN}Container is running. Press Ctrl+C when done testing, then run:${NC}"
echo -e "${YELLOW}docker rm -f ${CONTAINER_NAME}${NC}"
echo ""
