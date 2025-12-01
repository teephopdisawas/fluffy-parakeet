#!/bin/bash
# NASBox ISO Creator
# Creates a bootable ISO image

set -e

BUILD_DIR=${1:-"build"}
ISO_OUTPUT=${2:-"output/nasbox.iso"}

echo "Creating NASBox ISO image..."

# Create ISO structure
ISO_DIR="$BUILD_DIR/iso"
mkdir -p "$ISO_DIR"/{boot/isolinux,EFI/BOOT,live}

# Copy bootloader files
cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/boot/isolinux/" 2>/dev/null || \
cp /usr/share/syslinux/isolinux.bin "$ISO_DIR/boot/isolinux/" 2>/dev/null || \
echo "Note: isolinux.bin not found (install syslinux)"

cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$ISO_DIR/boot/isolinux/" 2>/dev/null || \
cp /usr/share/syslinux/ldlinux.c32 "$ISO_DIR/boot/isolinux/" 2>/dev/null || true

# Create ISOLINUX configuration
cat > "$ISO_DIR/boot/isolinux/isolinux.cfg" << 'EOF'
DEFAULT nasbox
TIMEOUT 50
PROMPT 1

UI menu.c32
MENU TITLE NASBox Boot Menu

LABEL nasbox
    MENU LABEL ^Start NASBox
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs
    APPEND root=/dev/ram0 init=/sbin/init quiet

LABEL nasbox_debug
    MENU LABEL ^Debug Mode
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs
    APPEND root=/dev/ram0 init=/sbin/init debug

LABEL install
    MENU LABEL ^Install NASBox
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs
    APPEND root=/dev/ram0 init=/sbin/init nasbox_install=1

LABEL memtest
    MENU LABEL ^Memory Test
    LINUX /boot/memtest
EOF

# Copy kernel and initramfs (if built)
if [ -f "$BUILD_DIR/vmlinuz" ]; then
    cp "$BUILD_DIR/vmlinuz" "$ISO_DIR/boot/"
fi

if [ -f "$BUILD_DIR/initramfs" ]; then
    cp "$BUILD_DIR/initramfs" "$ISO_DIR/boot/"
fi

# Create squashfs from rootfs
if [ -d "$BUILD_DIR/rootfs" ]; then
    echo "Creating squashfs filesystem..."
    mksquashfs "$BUILD_DIR/rootfs" "$ISO_DIR/live/filesystem.squashfs" \
        -comp xz -Xbcj x86 -b 1M -no-recovery 2>/dev/null || \
    mksquashfs "$BUILD_DIR/rootfs" "$ISO_DIR/live/filesystem.squashfs" \
        -comp gzip 2>/dev/null || \
    echo "Note: mksquashfs failed (install squashfs-tools)"
fi

# Create the ISO
echo "Building ISO..."
mkdir -p "$(dirname "$ISO_OUTPUT")"

xorriso -as mkisofs \
    -o "$ISO_OUTPUT" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin 2>/dev/null || \
xorriso -as mkisofs \
    -o "$ISO_OUTPUT" \
    -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin 2>/dev/null || \
xorriso -as mkisofs \
    -o "$ISO_OUTPUT" \
    -c boot/isolinux/boot.cat \
    -b boot/isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    "$ISO_DIR" 2>/dev/null || \
genisoimage \
    -o "$ISO_OUTPUT" \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -J -R \
    "$ISO_DIR" 2>/dev/null || \
echo "Note: ISO creation requires xorriso or genisoimage"

if [ -f "$ISO_OUTPUT" ]; then
    echo "ISO created: $ISO_OUTPUT"
    echo "Size: $(du -h "$ISO_OUTPUT" | cut -f1)"
else
    echo "ISO creation skipped (missing tools)"
fi
