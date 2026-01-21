# Docker Image Builder

This directory contains tools for building, tagging, and pushing Docker images for GitHub Actions runners to container registries.

## Overview

The builder system provides:
- **Build images**: Docker-in-Docker or buildx for multi-platform builds
- **Tag images**: Automatic version tagging with semantic versioning
- **Push images**: Push to any container registry (GitHub, Docker Hub, etc.)
- **Caching**: Registry and build cache optimization
- **Multi-platform**: Support for amd64 and arm64 architectures

## Directory Structure

```
docker/builder/
├── Dockerfile.builder         # Docker image builder (Docker-in-Docker)
├── docker-bake.hcl            # BuildKit bake configuration
├── README.md                  # This file
└── scripts/
    ├── build.sh              # Main build script
    ├── build-bake.sh         # Bake-based build script
    └── push-all.sh           # Push all built images
```

## Quick Start

### Prerequisites

1. **Docker**: Version 20.10+ (buildx support required)
2. **Registry access**: GitHub Container Registry (ghcr.io) or Docker Hub
3. **Authentication**: For pushing to registries

### Authentication Setup

#### GitHub Container Registry (ghcr.io)

```bash
# Set credentials
export REGISTRY=ghcr.io
export ORG=cicd
export REGISTRY_USERNAME=<your-github-username>
export REGISTRY_PASSWORD=<your-github-token>
```

**Note**: GitHub token requires `write:packages` and `delete:packages` scopes.

#### Docker Hub

```bash
# Set credentials
export REGISTRY=docker.io
export ORG=myorg
export REGISTRY_USERNAME=<docker-hub-username>
export REGISTRY_PASSWORD=<docker-hub-token>
```

## Build Scripts

### 1. build.sh - Standard Builder

Builds images using standard `docker build` or `docker buildx`.

**Usage:**
```bash
# Build a single image
./scripts/build.sh base
./scripts/build.sh cpp
./scripts/build.sh python

# Build and push to registry
./scripts/build.sh full-stack --push

# Build with version tag
./scripts/build.sh cpp --version 1.0.0 --push

# Build all images
./scripts/build.sh all --push --cache-from

# Dry run (show commands only)
./scripts/build.sh cpp --dry-run
```

**Options:**
- `--dry-run`: Show commands without executing
- `--no-cache`: Disable build cache
- `--cache-from`: Use registry cache
- `--push`: Push images to registry
- `--no-buildx`: Use regular docker build (no multi-platform)
- `--platforms`: Specify platforms (default: linux/amd64)
- `--version <tag>`: Version tag (default: latest)
- `--registry <url>`: Registry URL (default: ghcr.io)
- `--org <name>`: Organization name (default: cicd)
- `--tag <tag>`: Override all tags

### 2. build-bake.sh - BuildKit Bake Builder

Uses Docker BuildKit bake for advanced build features.

**Usage:**
```bash
# Build specific targets
./scripts/build-bake.sh base cpp python

# Build all targets
./scripts/build-bake.sh all --push

# Build with options
./scripts/build-bake.sh cpp --push --cache-from --version 1.0.0
```

**Options:**
- `--dry-run`: Show commands only
- `--push`: Push to registry
- `--cache-from`: Use registry cache
- `--platforms`: Platforms (default: linux/amd64,linux/arm64)
- `--version <tag>`: Version tag
- `--registry <url>`: Registry URL
- `--org <name>`: Organization name

### 3. push-all.sh - Push All Images

Pushes all images built with build.sh to the registry.

**Usage:**
```bash
./scripts/push-all.sh
```

**Note**: Requires images to be built first with `build.sh`.

## Image Types

### Base Images
- **base**: Minimal Ubuntu 22.04 + GitHub Actions runner

### Language Packs (Can be used independently)
- **cpp**: C++ toolchain (GCC, Clang, CMake, Make)
- **python**: Python 3.x with pip, venv, setuptools
- **nodejs**: Node.js 20 LTS with npm, yarn, pnpm
- **go**: Go 1.22 toolchain
- **flutter**: Flutter 3.19 with Dart, Android SDK
- **flet**: Flet 0.22.0 (Python→Flutter) with Flutter

### Composite Images (Full runners)
- **cpp-only**: C++ development runner
- **python-only**: Python/ML development runner
- **web**: Node.js + Go web development runner
- **flutter-only**: Flutter mobile development runner
- **flet-only**: Flet (Python→Flutter) development runner
- **full-stack**: All languages (legacy support)

### Utility
- **builder**: Docker image for building other images

## Build Commands

### Using build.sh

```bash
# 1. Build base image
./scripts/build.sh base --push

# 2. Build language packs
./scripts/build.sh cpp --push
./scripts/build.sh python --push
./scripts/build.sh nodejs --push

# 3. Build composite images
./scripts/build.sh cpp-only --push
./scripts/build.sh python-only --push

# 4. Build with specific version
./scripts/build.sh full-stack --version 2.0.0 --push

# 5. Build all at once
./scripts/build.sh all --push --cache-from

# 6. Build for multiple platforms
./scripts/build.sh all --platforms linux/amd64,linux/arm64 --push
```

### Using build-bake.sh (Advanced)

```bash
# Build with bake - supports registry cache
./scripts/build-bake.sh base cpp python --push --cache-from

# Build all targets
./scripts/build-bake.sh all --push

# Build with custom registry
./scripts/build-bake.sh cpp --registry docker.io --org myorg --push
```

## Registry Configuration

### GitHub Container Registry (ghcr.io)

```bash
# Set environment
export REGISTRY=ghcr.io
export ORG=cicd
export REGISTRY_USERNAME=<your-username>
export REGISTRY_PASSWORD=<your-github-token>

# Build and push
./scripts/build.sh cpp --push --version 1.0.0

# Images will be:
# ghcr.io/cicd/gh-runner:cpp-1.0.0
# ghcr.io/cicd/gh-runner:cpp-latest
```

### Docker Hub

```bash
# Set environment
export REGISTRY=docker.io
export ORG=myorg
export REGISTRY_USERNAME=<username>
export REGISTRY_PASSWORD=<token>

# Build and push
./scripts/build.sh python --push

# Images will be:
# docker.io/myorg/gh-runner:python-latest
```

### Private Registry

```bash
# Set environment
export REGISTRY=myregistry.company.com
export ORG=devops
export REGISTRY_USERNAME=<username>
export REGISTRY_PASSWORD=<password>

# Build and push
./scripts/build.sh full-stack --push --version 2.0.0

# Images will be:
# myregistry.company.com/devops/gh-runner:full-stack-2.0.0
```

## Tagging Strategy

### Automatic Tags

When building with `--push`, the system automatically creates two tags:

1. **Versioned tag**: `gh-runner:<image-type>-<version>`
2. **Latest tag**: `gh-runner:<image-type>-latest`

**Example:**
```bash
./scripts/build.sh cpp --version 1.0.0 --push
# Creates:
# - ghcr.io/cicd/gh-runner:cpp-1.0.0
# - ghcr.io/cicd/gh-runner:cpp-latest
```

### Custom Tags

Override all tags:
```bash
./scripts/build.sh cpp --tag my-custom-tag --push
# Creates:
# - ghcr.io/cicd/gh-runner:my-custom-tag
```

## Caching Strategies

### 1. Registry Cache (Recommended)

Use `--cache-from` to cache layers in registry:

```bash
# First build (pushes cache)
./scripts/build.sh cpp --cache-from --push

# Subsequent builds (uses cache)
./scripts/build.sh cpp --cache-from --push
```

### 2. Local Cache

Use Docker's local cache (default):

```bash
./scripts/build.sh cpp --push
```

### 3. Multi-stage Cache (Bake)

Using bake with registry cache:

```bash
./scripts/build-bake.sh cpp --cache-from --push
```

## Multi-Platform Builds

### Default (amd64 only)
```bash
./scripts/build.sh cpp --push
```

### Multi-arch (amd64 + arm64)
```bash
./scripts/build.sh cpp --platforms linux/amd64,linux/arm64 --push
```

**Note**: ARM64 builds require ARM64 host or QEMU emulation.

## Docker BuildKit Bake

The `docker-bake.hcl` file provides advanced build configuration:

### Customizing Bake File

Edit `docker-bake.hcl` to change:
- Platform support
- Cache configuration
- Tag patterns
- Build arguments

### Using Bake Directly

```bash
# Build with bake
docker buildx bake -f docker/builder/docker-bake.hcl cpp --set *.push=true

# Build specific targets
docker buildx bake -f docker/builder/docker-bake.hcl cpp python --set *.push=true
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Build and Push Images
on:
  push:
    branches: [main]
    tags: ['v*.*.*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and Push
        run: |
          export REGISTRY=ghcr.io
          export ORG=cicd
          export VERSION=${{ github.ref_name }}
          ./docker/builder/scripts/build.sh all --push --cache-from
```

### GitLab CI

```yaml
build-images:
  image: docker:latest
  services:
    - docker:dind
  script:
    - apk add --no-cache bash curl
    - export REGISTRY=registry.gitlab.com
    - export ORG=$CI_PROJECT_NAMESPACE
    - export VERSION=$CI_COMMIT_TAG
    - ./docker/builder/scripts/build.sh all --push
```

## Troubleshooting

### 1. Authentication Errors
```bash
# Check credentials
echo $REGISTRY_PASSWORD | docker login $REGISTRY -u $REGISTRY_USERNAME --password-stdin

# Test access
docker pull alpine
```

### 2. Buildx Not Available
```bash
# Install buildx
curl -L https://github.com/docker/buildx/releases/download/v0.12.5/buildx-v0.12.5.linux-amd64 \
  -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
```

### 3. Platform Not Supported
```bash
# Enable QEMU emulation
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### 4. Cache Not Working
```bash
# Check if cache is available
docker buildx bake --print cache-from

# Clean build with no cache
./scripts/build.sh cpp --no-cache --push
```

### 5. Insufficient Space
```bash
# Clean Docker system
docker system prune -af

# Check disk usage
docker system df
```

## Best Practices

### 1. Versioning
- Use semantic versioning (1.0.0, 1.1.0, 2.0.0)
- Tag releases with git tags
- Update version in .env file

### 2. Registry Management
- Use `--cache-from` for faster builds
- Clean old images regularly
- Use registry-specific cache

### 3. Security
- Never hardcode credentials in Dockerfiles
- Use Docker secrets or environment variables
- Scan images for vulnerabilities

### 4. Build Order
Build in this order to respect dependencies:
1. base
2. language packs (cpp, python, nodejs, go, flutter, flet)
3. composite images (cpp-only, python-only, etc.)
4. full-stack

### 5. Testing
Always test images before pushing:
```bash
# Test locally
docker run --rm gh-runner:cpp-only gcc --version

# Then push
./scripts/build.sh cpp --push
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `REGISTRY` | Container registry URL | ghcr.io |
| `ORG` | Organization name | cicd |
| `VERSION` | Image version tag | latest |
| `REGISTRY_USERNAME` | Registry username | - |
| `REGISTRY_PASSWORD` | Registry password/token | - |
| `PLATFORMS` | Build platforms | linux/amd64 |
| `DRY_RUN` | Show commands only | false |
| `USE_CACHE` | Enable build cache | true |
| `CACHE_FROM_REGISTRY` | Use registry cache | false |
| `PUSH_TO_REGISTRY` | Push after build | false |
| `USE_BUILDX` | Use buildx for multi-platform | true |

## Examples

### Complete Workflow

```bash
# 1. Set up environment
export REGISTRY=ghcr.io
export ORG=cicd
export REGISTRY_USERNAME=<username>
export REGISTRY_PASSWORD=<token>

# 2. Build base image
./scripts/build.sh base --push

# 3. Build language packs
for lang in cpp python nodejs go flutter flet; do
    ./scripts/build.sh $lang --push --cache-from
done

# 4. Build composite images
for composite in cpp-only python-only web flutter-only flet-only full-stack; do
    ./scripts/build.sh $composite --push --cache-from
done

# 5. Verify images
docker images | grep gh-runner
```

### Quick Deploy

```bash
# Build and push everything in one command
./scripts/build.sh all --push --cache-from --version 1.0.0
```

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.

## Support

For issues or questions:
- Check the [README.md](../../README.md)
- Open an issue on GitHub
- Review [CONTRIBUTING.md](../../CONTRIBUTING.md)
