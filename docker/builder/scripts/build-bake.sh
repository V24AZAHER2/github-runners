#!/bin/bash
# docker/builder/scripts/build-bake.sh
# Build images using Docker BuildKit bake files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${BUILDER_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/build.sh"

BAKE_FILE="${BUILDER_DIR}/docker-bake.hcl"

# Default values
REGISTRY="${REGISTRY:-ghcr.io}"
ORG="${ORG:-cicd}"
VERSION="${VERSION:-latest}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
PUSH_TO_REGISTRY="${PUSH_TO_REGISTRY:-false}"
CACHE_FROM_REGISTRY="${CACHE_FROM_REGISTRY:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [TARGETS]

Build images using Docker BuildKit bake files.

Targets:
  base            Build base image
  cpp             Build C++ language pack
  python          Build Python language pack
  nodejs          Build Node.js language pack
  go              Build Go language pack
  flutter         Build Flutter language pack
  flet            Build Flet language pack
  cpp-only        Build C++ composite runner
  python-only     Build Python composite runner
  web             Build Web composite runner
  flutter-only    Build Flutter composite runner
  flet-only       Build Flet composite runner
  full-stack      Build full stack runner
  all             Build all targets (default)

Options:
  -h, --help      Show this help message
  --dry-run       Show commands without executing
  --push          Push images to registry after building
  --cache-from    Use registry cache
  --platforms     Specify platforms (default: ${PLATFORMS})
  --version <tag> Specify version tag (default: ${VERSION})
  --registry <url> Specify registry (default: ${REGISTRY})
  --org <name>    Specify organization (default: ${ORG})

Examples:
  $(basename "$0") base
  $(basename "$0") all --push --version 1.0.0
  $(basename "$0") cpp python --push --cache-from
EOF
}

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Build using bake
build_bake() {
    local targets=("${@}")
    local bake_cmd="docker buildx bake"

    # Check if bake file exists
    if [[ ! -f "${BAKE_FILE}" ]]; then
        log_error "Bake file not found: ${BAKE_FILE}"
        return 1
    fi

    # Setup buildx
    if ! command_exists docker-buildx && ! docker buildx version >/dev/null 2>&1; then
        log_error "Docker buildx not available"
        return 1
    fi

    # Create builder if not exists
    if ! docker buildx inspect gh-runner-builder >/dev/null 2>&1; then
        log_info "Creating buildx builder: gh-runner-builder"
        docker buildx create --name gh-runner-builder --driver docker-container --use
    else
        log_info "Using existing buildx builder: gh-runner-builder"
        docker buildx use gh-runner-builder
    fi

    # Build bake command
    bake_cmd+=" -f ${BAKE_FILE}"

    # Add variables
    bake_cmd+=" --set *.registry=${REGISTRY}"
    bake_cmd+=" --set *.org=${ORG}"
    bake_cmd+=" --set *.version=${VERSION}"
    bake_cmd+=" --set *.platforms=${PLATFORMS}"

    if [[ "${CACHE_FROM_REGISTRY}" == "true" ]]; then
        bake_cmd+=" --set *.cache-from=type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache"
        bake_cmd+=" --set *.cache-to=type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache,mode=max"
    fi

    if [[ "${PUSH_TO_REGISTRY}" == "true" ]]; then
        bake_cmd+=" --set *.output=type=registry"
    else
        bake_cmd+=" --set *.output=type=docker"
    fi

    # Add targets
    if [[ ${#targets[@]} -gt 0 ]]; then
        for target in "${targets[@]}"; do
            bake_cmd+=" ${target}"
        done
    else
        bake_cmd+=" all"
    fi

    log_info "Building with Bake..."
    log_info "Registry: ${REGISTRY}/${ORG}"
    log_info "Version: ${VERSION}"
    log_info "Platforms: ${PLATFORMS}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "Bake command: ${bake_cmd}"
        return 0
    fi

    # Execute build
    if ! eval "${bake_cmd}"; then
        log_error "Bake build failed"
        return 1
    fi

    log_success "Bake build completed successfully"
    return 0
}

# Main execution
main() {
    local targets=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --push)
                PUSH_TO_REGISTRY="true"
                shift
                ;;
            --cache-from)
                CACHE_FROM_REGISTRY="true"
                shift
                ;;
            --platforms)
                PLATFORMS="$2"
                shift 2
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --registry)
                REGISTRY="$2"
                shift 2
                ;;
            --org)
                ORG="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                targets+=("$1")
                shift
                ;;
        esac
    done

    # Execute build
    if ! build_bake "${targets[@]}"; then
        exit 1
    fi
}

# Run main
main "$@"
