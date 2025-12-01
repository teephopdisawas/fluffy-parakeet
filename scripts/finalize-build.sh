#!/bin/bash
# NASBox Build Finalization Script
# Prepares the build for packaging

set -e

BUILD_DIR=${1:-"build"}

echo "Finalizing NASBox build..."

ROOTFS="$BUILD_DIR/rootfs"

# Set permissions
chmod 755 "$ROOTFS/etc/init.d/"* 2>/dev/null || true
chmod 755 "$ROOTFS/usr/local/bin/"* 2>/dev/null || true

# Create version info
echo "1.0.0" > "$ROOTFS/etc/nasbox-version"
date -u +"%Y-%m-%d %H:%M:%S UTC" > "$ROOTFS/etc/nasbox-build-date"

# Create first-boot script
cat > "$ROOTFS/etc/local.d/nasbox-firstboot.start" << 'EOF'
#!/bin/sh
# NASBox First Boot Configuration

FIRSTBOOT_FLAG="/var/lib/nasbox/.firstboot-done"

if [ ! -f "$FIRSTBOOT_FLAG" ]; then
    echo "NASBox: Running first boot configuration..."
    
    # Generate SSH host keys
    ssh-keygen -A
    
    # Set default passwords (user should change these)
    echo "root:nasbox" | chpasswd
    
    # Create nasbox admin user
    adduser -D -g "NASBox Admin" admin
    echo "admin:admin" | chpasswd
    addgroup admin wheel
    addgroup admin docker 2>/dev/null || true
    
    # Initialize storage directories
    mkdir -p /mnt/storage/{public,documents,media,backups,downloads,timemachine}
    chmod 777 /mnt/storage/public
    chmod 755 /mnt/storage/media
    
    # Enable default services
    rc-update add docker default
    rc-update add samba default
    rc-update add nfs default
    rc-update add nginx default
    rc-update add nasbox-api default
    
    # Mark first boot complete
    mkdir -p /var/lib/nasbox
    touch "$FIRSTBOOT_FLAG"
    
    echo "NASBox: First boot configuration complete!"
    echo "Access the web GUI at http://$(hostname -I | awk '{print $1}'):8080"
fi
EOF
chmod +x "$ROOTFS/etc/local.d/nasbox-firstboot.start"

# Create welcome message
cat > "$ROOTFS/etc/motd" << 'EOF'

  _   _    _    ____  ____            
 | \ | |  / \  / ___|| __ )  _____  __
 |  \| | / _ \ \___ \|  _ \ / _ \ \/ /
 | |\  |/ ___ \ ___) | |_) | (_) >  < 
 |_| \_/_/   \_\____/|____/ \___/_/\_\
                                      
 Lightweight NAS Linux Distribution
 
 Web GUI: http://nasbox.local:8080
 Default credentials: admin / admin
 
 Please change your password after first login!

EOF

echo "Build finalization complete"
