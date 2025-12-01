#!/bin/bash
# Install build dependencies for NASBox
# Run this on your development machine before building

set -e

echo "Installing NASBox build dependencies..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS=$(uname -s)
fi

# Detect host architecture
HOST_ARCH=$(uname -m)
echo "Host architecture: $HOST_ARCH"

case $OS in
    ubuntu|debian)
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            wget \
            curl \
            git \
            debootstrap \
            squashfs-tools \
            genisoimage \
            xorriso \
            isolinux \
            syslinux-utils \
            mtools \
            dosfstools \
            shellcheck \
            python3 \
            python3-pip
        
        # QEMU for testing (architecture-specific)
        if [ "$HOST_ARCH" = "x86_64" ]; then
            sudo apt-get install -y qemu-system-x86 qemu-system-arm qemu-utils
            # ARM64 cross-compilation toolchain
            sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
        elif [ "$HOST_ARCH" = "aarch64" ]; then
            sudo apt-get install -y qemu-system-arm qemu-system-x86 qemu-utils
            # x86_64 cross-compilation toolchain
            sudo apt-get install -y gcc-x86-64-linux-gnu g++-x86-64-linux-gnu
        fi
        
        # GRUB for EFI boot images (both architectures)
        sudo apt-get install -y grub-efi-amd64-bin grub-efi-arm64-bin 2>/dev/null || true
        ;;
    
    fedora|rhel|centos)
        sudo dnf install -y \
            @development-tools \
            wget \
            curl \
            git \
            debootstrap \
            squashfs-tools \
            genisoimage \
            xorriso \
            syslinux \
            mtools \
            dosfstools \
            ShellCheck \
            python3 \
            python3-pip
        
        # QEMU and cross-compilation
        if [ "$HOST_ARCH" = "x86_64" ]; then
            sudo dnf install -y qemu-kvm qemu-system-aarch64 qemu-img
            sudo dnf install -y gcc-aarch64-linux-gnu
        elif [ "$HOST_ARCH" = "aarch64" ]; then
            sudo dnf install -y qemu-system-x86 qemu-kvm qemu-img
            sudo dnf install -y gcc-x86_64-linux-gnu
        fi
        ;;
    
    arch)
        sudo pacman -Sy --noconfirm \
            base-devel \
            wget \
            curl \
            git \
            debootstrap \
            squashfs-tools \
            cdrtools \
            xorriso \
            syslinux \
            mtools \
            dosfstools \
            qemu-full \
            shellcheck \
            python \
            python-pip
        
        # ARM cross-compilation on Arch
        if [ "$HOST_ARCH" = "x86_64" ]; then
            sudo pacman -Sy --noconfirm aarch64-linux-gnu-gcc 2>/dev/null || true
        fi
        ;;
    
    alpine)
        sudo apk add --no-cache \
            build-base \
            wget \
            curl \
            git \
            squashfs-tools \
            xorriso \
            syslinux \
            mtools \
            dosfstools \
            shellcheck \
            python3 \
            py3-pip
        
        # QEMU (architecture-specific)
        if [ "$HOST_ARCH" = "x86_64" ]; then
            sudo apk add --no-cache qemu-system-x86_64 qemu-system-aarch64 qemu-img
        elif [ "$HOST_ARCH" = "aarch64" ]; then
            sudo apk add --no-cache qemu-system-aarch64 qemu-system-x86_64 qemu-img
        fi
        ;;
    
    Darwin)
        # macOS
        if ! command -v brew &> /dev/null; then
            echo "Please install Homebrew first: https://brew.sh"
            exit 1
        fi
        brew install \
            wget \
            curl \
            git \
            squashfs \
            xorriso \
            mtools \
            dosfstools \
            qemu \
            shellcheck \
            python3
        
        # Cross-compilation toolchains on macOS
        if [ "$HOST_ARCH" = "arm64" ]; then
            echo "Note: For x86_64 cross-compilation on Apple Silicon, use Docker or Rosetta"
        else
            echo "Note: For ARM64 cross-compilation on Intel Mac, use Docker"
        fi
        ;;
    
    *)
        echo "Unsupported OS: $OS"
        echo "Please manually install: wget, curl, git, squashfs-tools, xorriso, qemu"
        exit 1
        ;;
esac

echo ""
echo "Build dependencies installed successfully!"
echo ""
echo "Supported architectures:"
echo "  - x86_64 (Intel/AMD 64-bit)"
echo "  - aarch64 (ARM 64-bit)"
echo ""
echo "Build commands:"
echo "  make build              # Build for current architecture ($HOST_ARCH)"
echo "  make build ARCH=x86_64  # Build for x86_64"
echo "  make build ARCH=aarch64 # Build for ARM64"
