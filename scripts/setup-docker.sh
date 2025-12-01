#!/bin/bash
# NASBox Docker Setup Script
# Configures Docker for NAS workloads

set -e

ROOTFS_DIR=${1:-"build/rootfs"}

echo "Setting up Docker integration..."

# Create Docker directories
mkdir -p "$ROOTFS_DIR/etc/docker"
mkdir -p "$ROOTFS_DIR/var/lib/docker"
mkdir -p "$ROOTFS_DIR/usr/local/bin"

# Copy Docker daemon configuration
cp docker-support/daemon.json "$ROOTFS_DIR/etc/docker/"

# Copy Docker service script
cp docker-support/docker-service "$ROOTFS_DIR/etc/init.d/docker"
chmod +x "$ROOTFS_DIR/etc/init.d/docker"

# Copy Docker Compose file for pre-installed apps
mkdir -p "$ROOTFS_DIR/etc/nasbox/docker"
cp docker-support/docker-compose.yml "$ROOTFS_DIR/etc/nasbox/docker/"

# Create Docker management wrapper
cat > "$ROOTFS_DIR/usr/local/bin/nasbox-docker" << 'EOF'
#!/bin/bash
# NASBox Docker Management Wrapper

COMPOSE_DIR="/etc/nasbox/docker"

case $1 in
    "apps")
        echo "Available Docker Apps:"
        echo "  - portainer (Docker Management UI)"
        echo "  - nextcloud (Personal Cloud)"
        echo "  - plex (Media Server)"
        echo "  - jellyfin (Free Media Server)"
        echo "  - transmission (BitTorrent)"
        echo "  - homeassistant (Home Automation)"
        echo "  - pihole (Ad Blocker)"
        ;;
    "install")
        app=$2
        echo "Installing $app..."
        cd "$COMPOSE_DIR" && docker-compose --profile "$app" up -d
        ;;
    "remove")
        app=$2
        echo "Removing $app..."
        cd "$COMPOSE_DIR" && docker-compose --profile "$app" down
        ;;
    "status")
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    *)
        echo "NASBox Docker Management"
        echo ""
        echo "Usage: nasbox-docker <command>"
        echo ""
        echo "Commands:"
        echo "  apps          List available apps"
        echo "  install <app> Install an app"
        echo "  remove <app>  Remove an app"
        echo "  status        Show running containers"
        ;;
esac
EOF
chmod +x "$ROOTFS_DIR/usr/local/bin/nasbox-docker"

# Enable Docker at boot
mkdir -p "$ROOTFS_DIR/etc/runlevels/default"
ln -sf /etc/init.d/docker "$ROOTFS_DIR/etc/runlevels/default/docker" 2>/dev/null || true

echo "Docker integration setup complete"
