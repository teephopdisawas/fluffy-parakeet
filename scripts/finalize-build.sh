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
    
    # Generate random initial passwords for security
    # Users MUST change these on first login
    RANDOM_PASS=$(head -c 12 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 12)
    echo "root:${RANDOM_PASS}" | chpasswd
    
    # Create nasbox admin user with random password
    adduser -D -g "NASBox Admin" admin
    ADMIN_PASS=$(head -c 12 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 12)
    echo "admin:${ADMIN_PASS}" | chpasswd
    addgroup admin wheel
    addgroup admin docker 2>/dev/null || true
    
    # Save initial credentials to secure file (readable only by root)
    echo "Initial Passwords (CHANGE IMMEDIATELY):" > /root/.initial-credentials
    echo "root: ${RANDOM_PASS}" >> /root/.initial-credentials
    echo "admin: ${ADMIN_PASS}" >> /root/.initial-credentials
    chmod 600 /root/.initial-credentials
    
    # Force password change on first login
    passwd -e root
    passwd -e admin
    
    # Initialize storage directories with secure permissions
    mkdir -p /mnt/storage/{public,documents,media,backups,downloads,timemachine}
    # Public share: group writable, not world writable
    chmod 775 /mnt/storage/public
    chown root:users /mnt/storage/public
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
    echo "Initial credentials saved to /root/.initial-credentials"
    echo "You will be required to change passwords on first login."
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
 
 Initial credentials are in /root/.initial-credentials
 You MUST change your password on first login!

EOF

echo "Build finalization complete"
