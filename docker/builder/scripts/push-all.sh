#!/bin/bash
# docker/builder/scripts/push-all.sh
# Push all built images to registry

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${BUILDER_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/build.sh"

# Default values
REGISTRY="${REGISTRY:-ghcr.io}"
ORG="${ORG:-cicd}"
VERSION="${VERSION:-latest}"

# Check for built images file
BUILT_IMAGES="${BUILDER_DIR}/built-images.txt"

if [[ ! -f "${BUILT_IMAGES}" ]]; then
    log_error "No built images found. Run build.sh first."
    exit 1
fi

# Authenticate
authenticate_registry

# Push all images
echo -e "\n${BLUE}Pushing all built images to ${REGISTRY}/${ORG}...${NC}"
echo "========================================"

while IFS= read -r image; do
    if [[ -n "${image}" ]]; then
        push_image "${image}"
    fi
done < "${BUILT_IMAGES}"

echo -e "\n${GREEN}All images pushed successfully!${NC}"
echo "========================================"
