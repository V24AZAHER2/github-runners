# docker/builder/Dockerfile.builder
# Docker Image Builder - Builds Docker images for GitHub Actions runners
# Uses Docker-in-Docker or buildx for building and pushing images

ARG DOCKER_VERSION=25.0.3
ARG BUILDKIT_VERSION=0.12.5

# Use Docker official SDK for building
FROM docker:${DOCKER_VERSION} AS docker-base

# Install build dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    yq \
    git \
    make \
    gettext \
    && rm -rf /var/cache/apk/*

# Install Docker Buildx plugin
RUN curl -L https://github.com/docker/buildx/releases/download/v${BUILDKIT_VERSION}/buildx-v${BUILDKIT_VERSION}.linux-amd64 \
    -o /usr/local/lib/docker/cli-plugins/docker-buildx && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

# Create build user
RUN addgroup -g 1001 build && \
    adduser -u 1001 -G build -s /bin/sh -D build

WORKDIR /workspace
USER build

# Copy build scripts
COPY --chown=build:build scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Build context
FROM docker-base AS builder

# Metadata
LABEL org.opencontainers.image.source="https://github.com/cicd/github-runner" \
      org.opencontainers.image.description="Docker image builder for GitHub Actions runners" \
      org.opencontainers.image.vendor="CI/CD Team" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.base.name="docker:${DOCKER_VERSION}"

# Default command shows usage
CMD ["/usr/local/bin/build.sh", "--help"]
