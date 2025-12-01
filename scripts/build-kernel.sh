#!/bin/bash
# NASBox Kernel Builder
# Compiles an optimized kernel for NAS workloads

set -e

BUILD_DIR=${1:-"build"}
KERNEL_VERSION=${2:-"6.6.0"}
ARCH=${3:-"x86_64"}

# Normalize architecture names and set kernel arch
case "$ARCH" in
    x86_64|amd64)
        ARCH="x86_64"
        KERNEL_ARCH="x86"
        KERNEL_IMAGE="arch/x86/boot/bzImage"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        KERNEL_ARCH="arm64"
        KERNEL_IMAGE="arch/arm64/boot/Image"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        echo "Supported architectures: x86_64, aarch64"
        exit 1
        ;;
esac

echo "Building kernel $KERNEL_VERSION for $ARCH..."
echo "Note: This requires a full kernel build environment"

KERNEL_DIR="$BUILD_DIR/kernel"
mkdir -p "$KERNEL_DIR"

# Check if kernel source is needed
KERNEL_SOURCE="linux-$KERNEL_VERSION.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_SOURCE"

# Select appropriate kernel config
if [ -f "base-system/kernel/config-$ARCH" ]; then
    KERNEL_CONFIG="base-system/kernel/config-$ARCH"
else
    KERNEL_CONFIG="base-system/kernel/config"
fi

echo "Kernel configuration is at $KERNEL_CONFIG"
echo ""
echo "To build kernel manually:"
echo "1. Download kernel source:"
echo "   wget $KERNEL_URL"
echo ""
echo "2. Extract and configure:"
echo "   tar xf $KERNEL_SOURCE"
echo "   cd linux-$KERNEL_VERSION"
echo "   cp ../$KERNEL_CONFIG .config"
echo ""
echo "3. Build kernel:"
if [ "$ARCH" = "aarch64" ]; then
    echo "   # For cross-compilation from x86_64:"
    echo "   ARCH=$KERNEL_ARCH CROSS_COMPILE=aarch64-linux-gnu- make -j\$(nproc)"
    echo "   # For native build on ARM:"
    echo "   make -j\$(nproc)"
else
    echo "   make -j\$(nproc)"
fi
echo "   make modules_install INSTALL_MOD_PATH=$BUILD_DIR/rootfs"
echo ""
echo "4. Install kernel:"
echo "   cp $KERNEL_IMAGE $BUILD_DIR/vmlinuz"
echo ""

# For development, create placeholder
touch "$BUILD_DIR/vmlinuz.placeholder"
echo "Kernel placeholder created. Full kernel build requires Linux build environment."
