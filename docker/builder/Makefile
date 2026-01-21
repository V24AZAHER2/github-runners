# docker/builder/Makefile
# Makefile for building and pushing Docker images

# Configuration
REGISTRY ?= ghcr.io
ORG ?= cicd
VERSION ?= latest
PLATFORMS ?= linux/amd64,linux/arm64
DRY_RUN ?= false
PUSH ?= false
CACHE_FROM ?= false

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m # No Color

# Helper functions
info = @echo -e "$(BLUE)[$(1)]$(NC) $(2)"
success = @echo -e "$(GREEN)[$(1)]$(NC) $(2)"
error = @echo -e "$(RED)[$(1)]$(NC) $(2)"

# Export environment
export REGISTRY
export ORG
export VERSION
export PLATFORMS
export DRY_RUN
export PUSH_TO_REGISTRY := $(PUSH)
export CACHE_FROM_REGISTRY := $(CACHE_FROM)

# Build targets
.PHONY: all base cpp python nodejs go flutter flet cpp-only python-only web flutter-only flet-only full-stack builder

all: base cpp python nodejs go flutter flet cpp-only python-only web flutter-only flet-only full-stack builder
	$(call success,ALL,Build completed)

base:
	$(call info,BUILD,base)
	./scripts/build.sh base --push --cache-from

cpp:
	$(call info,BUILD,cpp)
	./scripts/build.sh cpp --push --cache-from

python:
	$(call info,BUILD,python)
	./scripts/build.sh python --push --cache-from

nodejs:
	$(call info,BUILD,nodejs)
	./scripts/build.sh nodejs --push --cache-from

go:
	$(call info,BUILD,go)
	./scripts/build.sh go --push --cache-from

flutter:
	$(call info,BUILD,flutter)
	./scripts/build.sh flutter --push --cache-from

flet:
	$(call info,BUILD,flet)
	./scripts/build.sh flet --push --cache-from

cpp-only:
	$(call info,BUILD,cpp-only)
	./scripts/build.sh cpp-only --push --cache-from

python-only:
	$(call info,BUILD,python-only)
	./scripts/build.sh python-only --push --cache-from

web:
	$(call info,BUILD,web)
	./scripts/build.sh web --push --cache-from

flutter-only:
	$(call info,BUILD,flutter-only)
	./scripts/build.sh flutter-only --push --cache-from

flet-only:
	$(call info,BUILD,flet-only)
	./scripts/build.sh flet-only --push --cache-from

full-stack:
	$(call info,BUILD,full-stack)
	./scripts/build.sh full-stack --push --cache-from

builder:
	$(call info,BUILD,builder)
	./scripts/build.sh builder --push --cache-from

# Build without push
.PHONY: build-all build-base build-cpp build-python build-nodejs

build-all: build-base build-cpp build-python build-nodejs build-go build-flutter build-flet build-cpp-only build-python-only build-web build-flutter-only build-flet-only build-full-stack build-builder
	$(call success,BUILD-ALL,Completed)

build-base:
	$(call info,BUILD-ONLY,base)
	./scripts/build.sh base

build-cpp:
	$(call info,BUILD-ONLY,cpp)
	./scripts/build.sh cpp

build-python:
	$(call info,BUILD-ONLY,python)
	./scripts/build.sh python

build-nodejs:
	$(call info,BUILD-ONLY,nodejs)
	./scripts/build.sh nodejs

build-go:
	$(call info,BUILD-ONLY,go)
	./scripts/build.sh go

build-flutter:
	$(call info,BUILD-ONLY,flutter)
	./scripts/build.sh flutter

build-flet:
	$(call info,BUILD-ONLY,flet)
	./scripts/build.sh flet

build-cpp-only:
	$(call info,BUILD-ONLY,cpp-only)
	./scripts/build.sh cpp-only

build-python-only:
	$(call info,BUILD-ONLY,python-only)
	./scripts/build.sh python-only

build-web:
	$(call info,BUILD-ONLY,web)
	./scripts/build.sh web

build-flutter-only:
	$(call info,BUILD-ONLY,flutter-only)
	./scripts/build.sh flutter-only

build-flet-only:
	$(call info,BUILD-ONLY,flet-only)
	./scripts/build.sh flet-only

build-full-stack:
	$(call info,BUILD-ONLY,full-stack)
	./scripts/build.sh full-stack

build-builder:
	$(call info,BUILD-ONLY,builder)
	./scripts/build.sh builder

# Push targets
.PHONY: push push-all push-base push-cpp push-python

push:
	$(call info,PUSH,All images)
	./scripts/push-all.sh

push-all:
	$(call info,PUSH-ALL,All built images)
	./scripts/push-all.sh

push-base:
	$(call info,PUSH,base)
	./scripts/build.sh base --push

push-cpp:
	$(call info,PUSH,cpp)
	./scripts/build.sh cpp --push

push-python:
	$(call info,PUSH,python)
	./scripts/build.sh python --push

# Buildx targets (multi-platform)
.PHONY: bake-all bake-base bake-cpp

bake-all:
	$(call info,BAKE-ALL,All targets)
	./scripts/build-bake.sh all --push

bake-base:
	$(call info,BAKE,base)
	./scripts/build-bake.sh base --push

bake-cpp:
	$(call info,BAKE,cpp)
	./scripts/build-bake.sh cpp --push

# Dry run targets
.PHONY: dry-run dry-run-all

dry-run:
	$(call info,DRY-RUN,All images)
	./scripts/build.sh all --dry-run

dry-run-all:
	$(call info,DRY-RUN-ALL,All targets)
	./scripts/build-bake.sh all --dry-run

# Clean targets
.PHONY: clean clean-all clean-cache

clean:
	$(call info,CLEAN,Build artifacts)
	rm -f built-images.txt *.log

clean-all:
	$(call info,CLEAN-ALL,All build artifacts)
	rm -f built-images.txt *.log
	rm -rf .cache

clean-cache:
	$(call info,CLEAN-CACHE,Docker build cache)
	docker buildx prune -f

# Test targets
.PHONY: test test-all test-version

test:
	$(call info,TEST,Base image)
	./scripts/build.sh base --dry-run

test-all:
	$(call info,TEST-ALL,All images)
	./scripts/build.sh all --dry-run

test-version:
	$(call info,TEST-VERSION,Versioning)
	@echo "Registry: $(REGISTRY)"
	@echo "Org: $(ORG)"
	@echo "Version: $(VERSION)"
	@echo "Platforms: $(PLATFORMS)"

# Utility targets
.PHONY: help info login

help:
	@echo "Available targets:"
	@echo "  make all               Build and push all images"
	@echo "  make build-all         Build all images (no push)"
	@echo "  make push-all          Push all built images"
	@echo "  make <target>          Build specific target"
	@echo "  make bake-all          Build with bake (multi-platform)"
	@echo "  make dry-run           Show build commands"
	@echo "  make clean             Clean build artifacts"
	@echo "  make test              Test build system"
	@echo "  make help              Show this help"
	@echo ""
	@echo "Available targets: base, cpp, python, nodejs, go, flutter, flet,"
	@echo "                  cpp-only, python-only, web, flutter-only, flet-only, full-stack, builder"

info:
	$(call info,CONFIG,Registry: $(REGISTRY)/$(ORG))
	$(call info,CONFIG,Version: $(VERSION))
	$(call info,CONFIG,Platforms: $(PLATFORMS))
	$(call info,CONFIG,Dry Run: $(DRY_RUN))
	$(call info,CONFIG,Push: $(PUSH))

login:
	$(call info,LOGIN,Registry: $(REGISTRY))
	@echo "Enter registry username: "
	@read -r REGISTRY_USERNAME; \
	echo "Enter registry password/token: "; \
	read -r -s REGISTRY_PASSWORD; \
	export REGISTRY_USERNAME; \
	export REGISTRY_PASSWORD; \
	docker login $(REGISTRY) -u $$REGISTRY_USERNAME -p $$REGISTRY_PASSWORD

# Help target (default)
.DEFAULT_GOAL := help
