# Docker Integration Guide

NASBox includes full Docker and Docker Compose support out of the box.

## Overview

Docker allows you to run applications in isolated containers, providing:
- Easy application deployment
- Consistent environments
- Resource isolation
- Simple updates and rollbacks

## Quick Start

### Check Docker Status

```bash
# Via CLI
docker version
docker info

# Via GUI
# Navigate to Docker page in web interface
```

### Run Your First Container

```bash
# Hello World
docker run hello-world

# Interactive Ubuntu
docker run -it ubuntu bash
```

## Pre-installed Apps

NASBox includes Docker Compose configurations for popular NAS applications.

### Installing Apps via GUI

1. Navigate to **Docker** → **App Store**
2. Click **Install** on desired app
3. Configure app settings
4. Click **Deploy**

### Installing Apps via CLI

```bash
# List available apps
nasbox-docker apps

# Install Portainer
nasbox-docker install management

# Install Jellyfin
nasbox-docker install media

# Check status
nasbox-docker status
```

## Available Applications

### Management
| App | Description | Port |
|-----|-------------|------|
| Portainer | Docker management UI | 9000 |

### Media
| App | Description | Port |
|-----|-------------|------|
| Plex | Media server | 32400 |
| Jellyfin | Free media server | 8096 |
| Emby | Media server | 8920 |

### Cloud
| App | Description | Port |
|-----|-------------|------|
| Nextcloud | Personal cloud | 8081 |
| Seafile | File sync | 8082 |

### Downloads
| App | Description | Port |
|-----|-------------|------|
| Transmission | BitTorrent | 9091 |
| qBittorrent | BitTorrent | 8090 |
| SABnzbd | Usenet | 8088 |

### Home Automation
| App | Description | Port |
|-----|-------------|------|
| Home Assistant | Home automation | 8123 |

### Network
| App | Description | Port |
|-----|-------------|------|
| Pi-hole | Ad blocker | 8082 |

## Docker Compose

### Custom Compose Files

Place custom compose files in `/etc/nasbox/docker/custom/`:

```yaml
# /etc/nasbox/docker/custom/my-app.yml
version: '3.8'
services:
  my-app:
    image: myimage:latest
    ports:
      - "8888:80"
    volumes:
      - /mnt/storage/my-app:/data
```

Deploy:
```bash
docker-compose -f /etc/nasbox/docker/custom/my-app.yml up -d
```

## Storage Volumes

### Best Practices

1. **Mount storage from NAS pool**:
   ```yaml
   volumes:
     - /mnt/storage/app-data:/data
   ```

2. **Use named volumes for config**:
   ```yaml
   volumes:
     - app_config:/config
   ```

3. **Set proper permissions**:
   ```yaml
   environment:
     - PUID=1000
     - PGID=1000
   ```

## Resource Management

### Limit Container Resources

```yaml
services:
  my-app:
    image: myimage
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

### Monitor Resource Usage

```bash
# CLI
docker stats

# GUI
# Navigate to Docker → Containers → select container
```

## Networking

### Default Network

Containers are connected to `nasbox-network` by default.

### Access Host Services

Use `host.docker.internal` to access services on the host.

### Expose to LAN

Ports mapped in docker-compose are accessible on the LAN.

## Updates

### Update Containers

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

### Automatic Updates

Configure Watchtower for automatic updates:

```bash
nasbox-docker install watchtower
```

## Troubleshooting

### Container Won't Start

```bash
# View logs
docker logs container_name

# Check status
docker inspect container_name
```

### Storage Issues

```bash
# Check disk space
df -h /var/lib/docker

# Clean unused resources
docker system prune
```

### Network Issues

```bash
# Check networks
docker network ls

# Inspect network
docker network inspect nasbox-network
```
