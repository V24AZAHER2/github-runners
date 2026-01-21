# docker/builder/docker-bake.hcl
# Docker BuildKit Bake file for building all GitHub Actions runner images
# Supports multi-platform builds, caching, and registry push

# Group for all images
group "all" {
    targets = [
        "base",
        "cpp",
        "python",
        "nodejs",
        "go",
        "flutter",
        "flet",
        "cpp-only",
        "python-only",
        "web",
        "flutter-only",
        "flet-only",
        "full-stack",
        "builder"
    ]
}

# Default variables
variable "REGISTRY" {
    default = "ghcr.io"
}

variable "ORG" {
    default = "cicd"
}

variable "VERSION" {
    default = "latest"
}

variable "PLATFORMS" {
    default = "linux/amd64,linux/arm64"
}

# Base image
target "base" {
    context = "."
    dockerfile = "docker/linux/base/Dockerfile.base"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:base-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:base-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-base"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-base,mode=max"
    ]
}

# Language Packs
target "cpp" {
    context = "."
    dockerfile = "docker/linux/language-packs/cpp/Dockerfile.cpp"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:cpp-pack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:cpp-pack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-cpp"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-cpp,mode=max"
    ]
}

target "python" {
    context = "."
    dockerfile = "docker/linux/language-packs/python/Dockerfile.python"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:python-pack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:python-pack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-python"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-python,mode=max"
    ]
}

target "nodejs" {
    context = "."
    dockerfile = "docker/linux/language-packs/nodejs/Dockerfile.nodejs"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:nodejs-pack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:nodejs-pack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-nodejs"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-nodejs,mode=max"
    ]
}

target "go" {
    context = "."
    dockerfile = "docker/linux/language-packs/go/Dockerfile.go"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:go-pack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:go-pack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-go"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-go,mode=max"
    ]
}

target "flutter" {
    context = "."
    dockerfile = "docker/linux/language-packs/flutter/Dockerfile.flutter"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:flutter-pack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:flutter-pack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flutter"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flutter,mode=max"
    ]
}

target "flet" {
    context = "."
    dockerfile = "docker/linux/language-packs/flet/Dockerfile.flet"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:flet-pack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:flet-pack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flet"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flet,mode=max"
    ]
}

# Composite Images
target "cpp-only" {
    context = "."
    dockerfile = "docker/linux/composite/Dockerfile.cpp-only"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:cpp-only-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:cpp-only-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-cpp-only"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-cpp-only,mode=max"
    ]
}

target "python-only" {
    context = "."
    dockerfile = "docker/linux/composite/Dockerfile.python-only"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:python-only-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:python-only-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-python-only"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-python-only,mode=max"
    ]
}

target "web" {
    context = "."
    dockerfile = "docker/linux/composite/Dockerfile.web"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:web-stack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:web-stack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-web"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-web,mode=max"
    ]
}

target "flutter-only" {
    context = "."
    dockerfile = "docker/linux/composite/Dockerfile.flutter-only"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:flutter-only-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:flutter-only-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flutter-only"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flutter-only,mode=max"
    ]
}

target "flet-only" {
    context = "."
    dockerfile = "docker/linux/composite/Dockerfile.flet-only"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:flet-only-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:flet-only-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flet-only"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-flet-only,mode=max"
    ]
}

target "full-stack" {
    context = "."
    dockerfile = "docker/linux/composite/Dockerfile.full-stack"
    tags = [
        "${REGISTRY}/${ORG}/gh-runner:full-stack-${VERSION}",
        "${REGISTRY}/${ORG}/gh-runner:full-stack-latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-full-stack"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-runner:cache-full-stack,mode=max"
    ]
}

# Builder image (for building other images)
target "builder" {
    context = "docker/builder"
    dockerfile = "Dockerfile.builder"
    tags = [
        "${REGISTRY}/${ORG}/gh-builder:${VERSION}",
        "${REGISTRY}/${ORG}/gh-builder:latest"
    ]
    platforms = split(",", PLATFORMS)
    cache_from = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-builder:cache"
    ]
    cache_to = [
        "type=registry,ref=${REGISTRY}/${ORG}/gh-builder:cache,mode=max"
    ]
}
