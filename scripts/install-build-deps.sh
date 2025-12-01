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
            qemu-system-x86 \
            qemu-utils \
            shellcheck \
            python3 \
            python3-pip
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
            qemu-kvm \
            qemu-img \
            ShellCheck \
            python3 \
            python3-pip
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
            qemu-system-x86_64 \
            qemu-img \
            shellcheck \
            python3 \
            py3-pip
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
        ;;
    
    *)
        echo "Unsupported OS: $OS"
        echo "Please manually install: wget, curl, git, squashfs-tools, xorriso, qemu"
        exit 1
        ;;
esac

echo ""
echo "Build dependencies installed successfully!"
echo "You can now run 'make build' to build NASBox"
