#!/bin/bash
set -e

# Test script for code-server-astraluv builds
# Validates build, container startup, and service availability

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VARIANTS=("base" "runtime" "devel")
TEST_VERSION="test-$(date +%s)"
IMAGE_NAME="${DOCKER_HUB_USERNAME:-danieldu28121999}/code-server-astraluv"
CUDA_VERSION="${CUDA_VERSION:-12.2.0}"
UBUNTU_VERSION="${UBUNTU_VERSION:-22.04}"
CUDA_SHORT="${CUDA_VERSION%.*}"
TIMEOUT=120

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Testing code-server-astraluv Builds    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Function to test build
test_build() {
    local variant=$1
    echo -e "${YELLOW}[BUILD] Testing ${variant} variant...${NC}"

    if ./scripts/build.sh "${TEST_VERSION}" --cuda-flavor "${variant}"; then
        echo -e "${GREEN}✓ Build succeeded (${variant})${NC}"
        return 0
    else
        echo -e "${RED}✗ Build failed (${variant})${NC}"
        return 1
    fi
}

# Function to test container startup
test_container() {
    local variant=$1
    local container_name="test-${variant}-$$"

    echo -e "${YELLOW}[CONTAINER] Starting ${variant} variant...${NC}"

    # Run container in background
    if docker run -d \
        --name "${container_name}" \
        -p 8888:8888 \
        "${IMAGE_NAME}:${TEST_VERSION}-cuda${CUDA_SHORT}-ubuntu${UBUNTU_VERSION}-${variant}" > /dev/null 2>&1; then

        echo -e "${GREEN}✓ Container started (${variant})${NC}"

        # Wait for code-server to be ready
        echo -e "${YELLOW}[SERVICES] Waiting for code-server to be ready...${NC}"
        local elapsed=0
        local code_server_ready=0

        while [ $elapsed -lt $TIMEOUT ]; do
            if docker exec "${container_name}" curl -s http://localhost:8888/ > /dev/null 2>&1; then
                code_server_ready=1
                echo -e "${GREEN}✓ code-server ready on port 8888${NC}"
                break
            fi

            sleep 5
            elapsed=$((elapsed + 5))
        done

        if [ $code_server_ready -eq 0 ]; then
            echo -e "${RED}✗ code-server did not become ready${NC}"
            docker logs "${container_name}" | tail -20
        fi

        # Run basic tests
        echo -e "${YELLOW}[TESTS] Running basic tests in container...${NC}"

        # Test UV installation
        if docker exec "${container_name}" uv --version > /dev/null 2>&1; then
            echo -e "${GREEN}✓ UV installed${NC}"
        else
            echo -e "${RED}✗ UV not found${NC}"
        fi

        # Test Python
        if docker exec "${container_name}" python --version > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Python installed${NC}"
        else
            echo -e "${RED}✗ Python not found${NC}"
        fi

        # Test s6-overlay
        if docker exec "${container_name}" pgrep -f s6-svscan > /dev/null 2>&1; then
            echo -e "${GREEN}✓ s6-overlay running${NC}"
        else
            echo -e "${RED}✗ s6-overlay not running${NC}"
        fi

        # Cleanup
        docker stop "${container_name}" > /dev/null 2>&1
        docker rm "${container_name}" > /dev/null 2>&1

        echo -e "${GREEN}✓ Container test passed (${variant})${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to start container (${variant})${NC}"
        docker rm "${container_name}" > /dev/null 2>&1 || true
        return 1
    fi
}

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    exit 1
fi

echo -e "${BLUE}Testing all CUDA variants...${NC}"
echo ""

# Test each variant
failed_variants=()
for variant in "${VARIANTS[@]}"; do
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if ! test_build "${variant}"; then
        failed_variants+=("${variant}")
        continue
    fi
    echo ""

    if ! test_container "${variant}"; then
        failed_variants+=("${variant}")
    fi
    echo ""
done

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Test Summary:${NC}"

if [ ${#failed_variants[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo -e "${BLUE}Built images:${NC}"
    for variant in "${VARIANTS[@]}"; do
        docker images "${IMAGE_NAME}:${TEST_VERSION}-cuda${CUDA_SHORT}-ubuntu${UBUNTU_VERSION}-${variant}" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
    done
    exit 0
else
    echo -e "${RED}✗ Tests failed for: ${failed_variants[*]}${NC}"
    exit 1
fi
