#!/bin/bash
# NASBox Root Filesystem Builder
# Creates the minimal base system from Alpine Linux

set -e

ROOTFS_DIR=${1:-"build/rootfs"}
ALPINE_VERSION=${2:-"3.19"}
ARCH=${3:-"x86_64"}
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"

# Normalize architecture names
case "$ARCH" in
    x86_64|amd64)
        ARCH="x86_64"
        ALPINE_ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ALPINE_ARCH="aarch64"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        echo "Supported architectures: x86_64, aarch64"
        exit 1
        ;;
esac

echo "Building NASBox root filesystem..."
echo "Target: $ROOTFS_DIR"
echo "Alpine Version: $ALPINE_VERSION"
echo "Architecture: $ARCH"

# Create directory structure efficiently using brace expansion
# Base directories: bin, sbin, proc, sys, dev, tmp, usr, home, root
# Config directories: etc/{nasbox,docker,samba,init.d}
# Data directories: var/{log/nasbox,lib/docker,run}, mnt/storage
mkdir -p "$ROOTFS_DIR"/{bin,sbin,etc/{nasbox,docker,samba,init.d},proc,sys,dev,tmp,var/{log/nasbox,lib/docker,run},usr,home,root,mnt/storage}

# Download Alpine minirootfs
MINIROOTFS="alpine-minirootfs-${ALPINE_VERSION}.0-${ALPINE_ARCH}.tar.gz"
if [ ! -f "/tmp/$MINIROOTFS" ]; then
    echo "Downloading Alpine minirootfs..."
    # Use curl with resume capability and connection reuse for efficiency
    if command -v curl &> /dev/null; then
        curl -fsSL --retry 3 --retry-delay 2 -C - -o "/tmp/${MINIROOTFS}" \
            "${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${MINIROOTFS}" 2>/dev/null || {
            echo "Note: Could not download Alpine minirootfs (network error or offline)"
            echo "Creating minimal structure instead..."
        }
    else
        wget -q --tries=3 --continue "${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${MINIROOTFS}" -O "/tmp/${MINIROOTFS}" || {
            echo "Note: Could not download Alpine minirootfs (network error or offline)"
            echo "Creating minimal structure instead..."
        }
    fi
fi

# Extract if downloaded
if [ -f "/tmp/$MINIROOTFS" ]; then
    tar -xzf "/tmp/$MINIROOTFS" -C "$ROOTFS_DIR"
fi

# Configure Alpine repositories
cat > "$ROOTFS_DIR/etc/apk/repositories" << EOF
${ALPINE_MIRROR}/v${ALPINE_VERSION}/main
${ALPINE_MIRROR}/v${ALPINE_VERSION}/community
EOF

# Create NASBox identification
cat > "$ROOTFS_DIR/etc/nasbox-release" << EOF
NAME="NASBox"
VERSION="1.0.0"
ID=nasbox
VERSION_ID=1.0.0
PRETTY_NAME="NASBox 1.0.0 ($ARCH)"
HOME_URL="https://github.com/teephopdisawas/fluffy-parakeet"
ARCH="$ARCH"
EOF

# Create /etc/os-release symlink
ln -sf nasbox-release "$ROOTFS_DIR/etc/os-release"

# Configure hostname
echo "nasbox" > "$ROOTFS_DIR/etc/hostname"

# Configure hosts
cat > "$ROOTFS_DIR/etc/hosts" << EOF
127.0.0.1   localhost nasbox
::1         localhost nasbox
EOF

# Create default network configuration
cat > "$ROOTFS_DIR/etc/network/interfaces" << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Create NASBox default configuration
cat > "$ROOTFS_DIR/etc/nasbox/nasbox.conf" << EOF
# NASBox Configuration
# Version 1.0.0

[general]
hostname = nasbox
timezone = UTC
language = en_US.UTF-8

[network]
auto_discovery = true
mdns_enabled = true

[storage]
default_pool = main
smart_monitoring = true
snapshot_schedule = daily

[services]
samba = enabled
nfs = enabled
docker = enabled
ssh = enabled
gui = enabled

[gui]
port = 8080
ssl = true
theme = dark

[security]
firewall = enabled
auto_updates = true
fail2ban = enabled
EOF

# Install package list for chroot installation
cat > "$ROOTFS_DIR/etc/nasbox/packages.list" << EOF
# Base system
busybox
musl
openrc
alpine-baselayout

# Networking
dhcpcd
openssh
avahi
dbus

# Storage
e2fsprogs
xfsprogs
btrfs-progs
zfs
mdadm
lvm2
smartmontools
hdparm

# File sharing
samba
nfs-utils

# Docker
docker
docker-compose

# Utilities
bash
curl
wget
jq
htop
nano
vim
less
rsync
tar
gzip

# GUI dependencies
python3
py3-pip
nginx
EOF

echo "Root filesystem structure created at $ROOTFS_DIR"
