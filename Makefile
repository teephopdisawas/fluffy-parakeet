# NASBox Build System
# Lightweight Linux Distribution for NAS

.PHONY: all build clean iso rootfs kernel docker-setup gui install test help setup-dirs

# Configuration
DISTRO_NAME := NASBox
VERSION := 1.0.0

# Architecture detection - supports x86_64 and aarch64 (ARM64)
# Can be overridden with: make ARCH=aarch64
HOST_ARCH := $(shell uname -m)
ifeq ($(HOST_ARCH),arm64)
    # macOS reports arm64, convert to aarch64
    HOST_ARCH := aarch64
endif
ARCH ?= $(HOST_ARCH)

# Validate architecture
SUPPORTED_ARCHS := x86_64 aarch64
ifeq ($(filter $(ARCH),$(SUPPORTED_ARCHS)),)
    $(error Unsupported architecture: $(ARCH). Supported: $(SUPPORTED_ARCHS))
endif

BUILD_DIR := build
OUTPUT_DIR := output
ROOTFS_DIR := $(BUILD_DIR)/rootfs
ISO_NAME := nasbox-$(VERSION)-$(ARCH).iso

# Alpine Linux base version
ALPINE_VERSION := 3.19
ALPINE_MIRROR := https://dl-cdn.alpinelinux.org/alpine

# Kernel version
KERNEL_VERSION := 6.6.0

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m

all: build

help:
	@echo "$(GREEN)NASBox Build System$(NC)"
	@echo ""
	@echo "Usage: make [target] [ARCH=x86_64|aarch64]"
	@echo ""
	@echo "Targets:"
	@echo "  build        - Build complete NASBox distribution"
	@echo "  rootfs       - Build root filesystem"
	@echo "  kernel       - Build optimized kernel"
	@echo "  docker-setup - Configure Docker integration"
	@echo "  gui          - Build lightweight GUI"
	@echo "  iso          - Create bootable ISO image"
	@echo "  install      - Install to target device"
	@echo "  test         - Run build tests"
	@echo "  clean        - Clean build artifacts"
	@echo ""
	@echo "Architecture:"
	@echo "  Default: $(HOST_ARCH)"
	@echo "  Supported: $(SUPPORTED_ARCHS)"
	@echo "  Override:  make build ARCH=aarch64"
	@echo ""

# Create build directories
.PHONY: setup-dirs
setup-dirs:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p $(ROOTFS_DIR)

# Build root filesystem
rootfs: setup-dirs
	@echo "$(GREEN)Building root filesystem for $(ARCH)...$(NC)"
	@./scripts/build-rootfs.sh $(ROOTFS_DIR) $(ALPINE_VERSION) $(ARCH)
	@echo "$(GREEN)Root filesystem built successfully$(NC)"

# Build optimized kernel
kernel: setup-dirs
	@echo "$(GREEN)Building kernel $(KERNEL_VERSION) for $(ARCH)...$(NC)"
	@./scripts/build-kernel.sh $(BUILD_DIR) $(KERNEL_VERSION) $(ARCH)
	@echo "$(GREEN)Kernel built successfully$(NC)"

# Setup Docker integration
docker-setup: rootfs
	@echo "$(GREEN)Setting up Docker integration...$(NC)"
	@./scripts/setup-docker.sh $(ROOTFS_DIR)
	@echo "$(GREEN)Docker integration configured$(NC)"

# Build lightweight GUI
gui: rootfs
	@echo "$(GREEN)Building lightweight GUI...$(NC)"
	@./scripts/build-gui.sh $(ROOTFS_DIR)
	@echo "$(GREEN)GUI built successfully$(NC)"

# Complete build
build: rootfs kernel docker-setup gui
	@echo "$(GREEN)Finalizing build...$(NC)"
	@./scripts/finalize-build.sh $(BUILD_DIR)
	@echo "$(GREEN)Build completed successfully!$(NC)"
	@echo "Output directory: $(OUTPUT_DIR)"

# Create ISO image
iso: build
	@echo "$(GREEN)Creating ISO image for $(ARCH)...$(NC)"
	@./scripts/create-iso.sh $(BUILD_DIR) $(OUTPUT_DIR)/$(ISO_NAME) $(ARCH)
	@echo "$(GREEN)ISO created: $(OUTPUT_DIR)/$(ISO_NAME)$(NC)"

# Install to target
install: build
	@echo "$(YELLOW)Starting installation wizard...$(NC)"
	@./scripts/install.sh

# Run tests
test:
	@echo "$(GREEN)Running build tests...$(NC)"
	@./scripts/run-tests.sh
	@echo "$(GREEN)All tests passed$(NC)"

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(OUTPUT_DIR)
	@echo "$(GREEN)Clean complete$(NC)"

# Development targets
dev-gui:
	@echo "$(GREEN)Starting GUI development server...$(NC)"
	@cd gui && python3 -m http.server 8080

lint:
	@echo "$(GREEN)Running linters...$(NC)"
	@shellcheck scripts/*.sh 2>/dev/null || true
	@echo "$(GREEN)Linting complete$(NC)"
