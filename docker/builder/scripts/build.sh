#!/bin/bash
# docker/builder/scripts/build.sh
# Comprehensive build script for GitHub Actions runner Docker images
# Supports building, tagging, and pushing to registries

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_REGISTRY="ghcr.io"
DEFAULT_ORG="cicd"
DEFAULT_TAG="latest"
DEFAULT_PLATFORMS="linux/amd64"
BUILDKIT_PLATFORMS="linux/amd64,linux/arm64"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
BUILDER_DIR="${PROJECT_ROOT}/docker/builder"

# Load environment variables
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    # shellcheck disable=SC1091
    source "${PROJECT_ROOT}/.env"
fi

# Registry credentials (from environment)
REGISTRY="${REGISTRY:-${DEFAULT_REGISTRY}}"
REGISTRY_USERNAME="${REGISTRY_USERNAME:-}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-}"
ORG="${ORG:-${DEFAULT_ORG}}"

# Tags
VERSION="${VERSION:-${DEFAULT_TAG}}"
IMAGE_TAG="${REGISTRY}/${ORG}/gh-runner:${VERSION}"
LATEST_TAG="${REGISTRY}/${ORG}/gh-runner:latest"

# Build options
DRY_RUN="${DRY_RUN:-false}"
USE_CACHE="${USE_CACHE:-true}"
CACHE_FROM_REGISTRY="${CACHE_FROM_REGISTRY:-false}"
PUSH_TO_REGISTRY="${PUSH_TO_REGISTRY:-false}"
USE_BUILDX="${USE_BUILDX:-true}"
PLATFORMS="${PLATFORMS:-${DEFAULT_PLATFORMS}}"

# Print usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <image-type>

Build, tag, and optionally push GitHub Actions runner Docker images.

Image Types:
  base              Build base image
  cpp               Build C++ language pack
  python            Build Python language pack
  nodejs            Build Node.js language pack
  go                Build Go language pack
  flutter           Build Flutter language pack
  flet              Build Flet language pack
  cpp-only          Build C++ composite runner
  python-only       Build Python composite runner
  web               Build Web composite runner
  flutter-only      Build Flutter composite runner
  flet-only         Build Flet composite runner
  full-stack        Build full stack runner
  all               Build all images (requires buildx)
  builder           Build the builder image itself

Options:
  -h, --help        Show this help message
  --dry-run         Show commands without executing
  --no-cache        Disable build cache
  --cache-from      Use registry cache
  --push            Push images to registry after building
  --no-buildx       Use regular docker build (no multi-platform)
  --platforms       Specify platforms (default: linux/amd64)
  --version <tag>   Specify version tag (default: latest)
  --registry <url>  Specify registry (default: ghcr.io)
  --org <name>      Specify organization (default: cicd)
  --tag <tag>       Override all tags

Examples:
  $(basename "$0") base
  $(basename "$0") cpp --push --version 1.0.0
  $(basename "$0") all --push --cache-from
  $(basename "$0") full-stack --registry docker.io --org myorg --push

Environment Variables:
  REGISTRY          Registry URL
  REGISTRY_USERNAME Registry username (for authentication)
  REGISTRY_PASSWORD Registry password/token
  ORG               Organization name
  VERSION           Image version tag
EOF
}

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Authenticate to registry
authenticate_registry() {
    if [[ -n "${REGISTRY_PASSWORD}" && -n "${REGISTRY_USERNAME}" ]]; then
        log_info "Authenticating to registry: ${REGISTRY}"
        if [[ "${DRY_RUN}" == "true" ]]; then
            echo "docker login ${REGISTRY} -u ${REGISTRY_USERNAME} -p ***"
        else
            echo "${REGISTRY_PASSWORD}" | docker login "${REGISTRY}" -u "${REGISTRY_USERNAME}" --password-stdin
            if [[ $? -eq 0 ]]; then
                log_success "Successfully authenticated to ${REGISTRY}"
            else
                log_error "Failed to authenticate to ${REGISTRY}"
                return 1
            fi
        fi
    else
        log_warning "No credentials provided, skipping registry authentication"
    fi
}

# Build image with standard docker build
build_standard() {
    local image_type="$1"
    local dockerfile=""
    local build_context="${PROJECT_ROOT}"
    local build_args=""

    case "${image_type}" in
        base)
            dockerfile="docker/linux/base/Dockerfile.base"
            ;;
        cpp)
            dockerfile="docker/linux/language-packs/cpp/Dockerfile.cpp"
            ;;
        python)
            dockerfile="docker/linux/language-packs/python/Dockerfile.python"
            ;;
        nodejs)
            dockerfile="docker/linux/language-packs/nodejs/Dockerfile.nodejs"
            ;;
        go)
            dockerfile="docker/linux/language-packs/go/Dockerfile.go"
            ;;
        flutter)
            dockerfile="docker/linux/language-packs/flutter/Dockerfile.flutter"
            ;;
        flet)
            dockerfile="docker/linux/language-packs/flet/Dockerfile.flet"
            ;;
        cpp-only)
            dockerfile="docker/linux/composite/Dockerfile.cpp-only"
            ;;
        python-only)
            dockerfile="docker/linux/composite/Dockerfile.python-only"
            ;;
        web)
            dockerfile="docker/linux/composite/Dockerfile.web"
            ;;
        flutter-only)
            dockerfile="docker/linux/composite/Dockerfile.flutter-only"
            ;;
        flet-only)
            dockerfile="docker/linux/composite/Dockerfile.flet-only"
            ;;
        full-stack)
            dockerfile="docker/linux/composite/Dockerfile.full-stack"
            ;;
        builder)
            dockerfile="docker/builder/Dockerfile.builder"
            build_context="${BUILDER_DIR}"
            ;;
        *)
            log_error "Unknown image type: ${image_type}"
            return 1
            ;;
    esac

    if [[ ! -f "${PROJECT_ROOT}/${dockerfile}" ]]; then
        log_error "Dockerfile not found: ${dockerfile}"
        return 1
    fi

    # Determine tags
    local image_name="gh-runner:${image_type}-${VERSION}"
    local full_tag="${REGISTRY}/${ORG}/${image_name}"

    if [[ "${image_type}" == "builder" ]]; then
        full_tag="${REGISTRY}/${ORG}/gh-builder:${VERSION}"
    fi

    # Build command
    local build_cmd="docker build"

    if [[ "${USE_CACHE}" == "false" ]]; then
        build_cmd+=" --no-cache"
    fi

    build_cmd+=" -f ${PROJECT_ROOT}/${dockerfile}"
    build_cmd+=" -t ${full_tag}"
    build_cmd+=" ${build_context}"

    log_info "Building ${image_type} image..."
    log_info "Tag: ${full_tag}"
    log_info "Dockerfile: ${dockerfile}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "Build command: ${build_cmd}"
        return 0
    fi

    # Execute build
    if ! eval "${build_cmd}"; then
        log_error "Build failed for ${image_type}"
        return 1
    fi

    log_success "Successfully built ${image_type}"
    echo "${full_tag}" >> "${BUILDER_DIR}/built-images.txt"

    # Push if requested
    if [[ "${PUSH_TO_REGISTRY}" == "true" ]]; then
        push_image "${full_tag}"
    fi

    return 0
}

# Build image with buildx (multi-platform)
build_buildx() {
    local image_type="$1"
    local dockerfile=""
    local build_context="${PROJECT_ROOT}"
    local cache_from=""
    local cache_to=""

    case "${image_type}" in
        base)
            dockerfile="docker/linux/base/Dockerfile.base"
            ;;
        cpp)
            dockerfile="docker/linux/language-packs/cpp/Dockerfile.cpp"
            ;;
        python)
            dockerfile="docker/linux/language-packs/python/Dockerfile.python"
            ;;
        nodejs)
            dockerfile="docker/linux/language-packs/nodejs/Dockerfile.nodejs"
            ;;
        go)
            dockerfile="docker/linux/language-packs/go/Dockerfile.go"
            ;;
        flutter)
            dockerfile="docker/linux/language-packs/flutter/Dockerfile.flutter"
            ;;
        flet)
            dockerfile="docker/linux/language-packs/flet/Dockerfile.flet"
            ;;
        cpp-only)
            dockerfile="docker/linux/composite/Dockerfile.cpp-only"
            ;;
        python-only)
            dockerfile="docker/linux/composite/Dockerfile.python-only"
            ;;
        web)
            dockerfile="docker/linux/composite/Dockerfile.web"
            ;;
        flutter-only)
            dockerfile="docker/linux/composite/Dockerfile.flutter-only"
            ;;
        flet-only)
            dockerfile="docker/linux/composite/Dockerfile.flet-only"
            ;;
        full-stack)
            dockerfile="docker/linux/composite/Dockerfile.full-stack"
            ;;
        all)
            build_all_buildx
            return $?
            ;;
        builder)
            dockerfile="docker/builder/Dockerfile.builder"
            build_context="${BUILDER_DIR}"
            ;;
        *)
            log_error "Unknown image type: ${image_type}"
            return 1
            ;;
    esac

    if [[ ! -f "${PROJECT_ROOT}/${dockerfile}" ]]; then
        log_error "Dockerfile not found: ${dockerfile}"
        return 1
    fi

    # Setup buildx
    setup_buildx

    # Determine tags
    local image_name="gh-runner:${image_type}-${VERSION}"
    local full_tag="${REGISTRY}/${ORG}/${image_name}"

    if [[ "${image_type}" == "builder" ]]; then
        full_tag="${REGISTRY}/${ORG}/gh-builder:${VERSION}"
    fi

    local tags="--tag ${full_tag}"
    if [[ "${image_type}" != "builder" ]]; then
        tags+=" --tag ${REGISTRY}/${ORG}/gh-runner:${image_type}-${VERSION}"
    fi

    # Build command
    local build_cmd="docker buildx build"
    build_cmd+=" --platform ${PLATFORMS}"
    build_cmd+=" -f ${PROJECT_ROOT}/${dockerfile}"
    build_cmd+=" ${tags}"
    build_cmd+=" ${build_context}"

    # Cache options
    if [[ "${CACHE_FROM_REGISTRY}" == "true" ]]; then
        cache_from="--cache-from=type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-${image_type}"
        cache_to="--cache-to=type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-${image_type},mode=max"
        build_cmd+=" ${cache_from} ${cache_to}"
    fi

    if [[ "${PUSH_TO_REGISTRY}" == "true" ]]; then
        build_cmd+=" --push"
    else
        build_cmd+=" --load"
    fi

    log_info "Building ${image_type} image with buildx..."
    log_info "Tags: ${full_tag}"
    log_info "Platforms: ${PLATFORMS}"
    log_info "Dockerfile: ${dockerfile}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "Build command: ${build_cmd}"
        return 0
    fi

    # Execute build
    if ! eval "${build_cmd}"; then
        log_error "Build failed for ${image_type}"
        return 1
    fi

    log_success "Successfully built ${image_type}"
    echo "${full_tag}" >> "${BUILDER_DIR}/built-images.txt"

    return 0
}

# Build all images with buildx
build_all_buildx() {
    log_info "Building all images with buildx..."

    # Define build order (respecting dependencies)
    local images=("base" "cpp" "python" "nodejs" "go" "flutter" "flet" "cpp-only" "python-only" "web" "flutter-only" "flet-only" "full-stack")

    for image in "${images[@]}"; do
        if ! build_buildx "${image}"; then
            log_error "Failed to build ${image}"
            return 1
        fi
    done

    log_success "All images built successfully"
    return 0
}

# Setup buildx environment
setup_buildx() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN: Would setup buildx"
        return 0
    fi

    # Check if buildx is available
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
}

# Push image to registry
push_image() {
    local image="$1"
    log_info "Pushing ${image} to registry..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "docker push ${image}"
        return 0
    fi

    if docker push "${image}"; then
        log_success "Successfully pushed ${image}"
        return 0
    else
        log_error "Failed to push ${image}"
        return 1
    fi
}

# Tag image
tag_image() {
    local source="$1"
    local target="$2"
    log_info "Tagging ${source} as ${target}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "docker tag ${source} ${target}"
        return 0
    fi

    if docker tag "${source}" "${target}"; then
        log_success "Successfully tagged ${target}"
        return 0
    else
        log_error "Failed to tag ${target}"
        return 1
    fi
}

# List built images
list_images() {
    if [[ ! -f "${BUILDER_DIR}/built-images.txt" ]]; then
        log_warning "No built images found"
        return 0
    fi

    echo -e "\n${BLUE}Built Images:${NC}"
    cat "${BUILDER_DIR}/built-images.txt"
}

# Clean up built images list
cleanup() {
    if [[ -f "${BUILDER_DIR}/built-images.txt" ]]; then
        rm "${BUILDER_DIR}/built-images.txt"
        log_success "Cleaned up build artifacts"
    fi
}

# Main execution
main() {
    local image_types=()

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
            --no-cache)
                USE_CACHE="false"
                shift
                ;;
            --cache-from)
                CACHE_FROM_REGISTRY="true"
                shift
                ;;
            --push)
                PUSH_TO_REGISTRY="true"
                shift
                ;;
            --no-buildx)
                USE_BUILDX="false"
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
            --tag)
                VERSION="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                image_types+=("$1")
                shift
                ;;
        esac
    done

    # Validate
    if [[ ${#image_types[@]} -eq 0 ]]; then
        log_error "No image type specified"
        usage
        exit 1
    fi

    # Check for all single image type
    local all_image_types=("base" "cpp" "python" "nodejs" "go" "flutter" "flet" "cpp-only" "python-only" "web" "flutter-only" "flet-only" "full-stack" "builder" "all")
    for image_type in "${image_types[@]}"; do
        if [[ ! " ${all_image_types[*]} " =~ " ${image_type} " ]]; then
            log_error "Invalid image type: ${image_type}"
            usage
            exit 1
        fi
    done

    # Authenticate if pushing
    if [[ "${PUSH_TO_REGISTRY}" == "true" ]]; then
        authenticate_registry || exit 1
    fi

    # Execute builds
    for image_type in "${image_types[@]}"; do
        echo
        log_info "========================================="
        log_info "Processing: ${image_type}"
        log_info "========================================="

        if [[ "${USE_BUILDX}" == "true" ]]; then
            if ! build_buildx "${image_type}"; then
                log_error "Failed to build ${image_type} with buildx"
                exit 1
            fi
        else
            if ! build_standard "${image_type}"; then
                log_error "Failed to build ${image_type}"
                exit 1
            fi
        fi
    done

    # List built images
    if [[ "${DRY_RUN}" != "true" ]]; then
        list_images
        log_success "Build process completed successfully"
    fi

    # Cleanup on success
    if [[ "${DRY_RUN}" != "true" ]]; then
        cleanup
    fi
}

# Handle errors
trap 'log_error "Script failed at line $LINENO"; exit 1' ERR

# Run main function
main "$@"
