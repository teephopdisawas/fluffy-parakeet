# NASBox - Lightweight Linux Distribution for NAS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Compatible](https://img.shields.io/badge/Docker-Compatible-blue.svg)](https://www.docker.com/)

## Overview

NASBox is a lightweight, purpose-built Linux distribution designed specifically for Network Attached Storage (NAS) devices. It combines minimal resource usage with powerful features, Docker compatibility, and a custom lightweight GUI for easy management.

## Key Features

### 🐳 Docker Integration
- Full Docker and Docker Compose support
- Pre-configured container management
- Easy app deployment through containers
- Container resource monitoring and limits

### 💾 Storage Management
- ZFS, Btrfs, ext4, and XFS support
- Software RAID (mdadm) support
- LVM (Logical Volume Management)
- SMART disk monitoring
- Automatic disk health alerts
- Snapshot and backup capabilities

### 🌐 Network Features
- SMB/CIFS (Samba) file sharing
- NFS support
- AFP (Apple Filing Protocol) support
- WebDAV server
- FTP/SFTP server
- iSCSI target support

### 🖥️ Lightweight GUI
- Custom web-based management interface
- Low memory footprint (<50MB RAM for GUI)
- Responsive design for mobile access
- Dark/Light theme support
- Real-time system monitoring dashboard

### 🔒 Security
- Automatic security updates
- Firewall management (iptables/nftables)
- SSL/TLS encryption for all services
- User and group management
- Access control lists (ACL)

### ⚡ Performance
- Optimized kernel for NAS workloads
- Minimal base system (~200MB installed)
- Fast boot time (<15 seconds)
- Low idle memory usage (<100MB RAM)

## System Requirements

### Minimum
- 64-bit x86 processor (x86_64)
- 512MB RAM
- 2GB storage for OS
- 1+ storage drives for data

### Recommended
- 64-bit multi-core processor
- 2GB+ RAM (4GB+ for Docker workloads)
- 8GB+ storage for OS (SSD preferred)
- Multiple storage drives for RAID

## Quick Start

### Building from Source

```bash
# Clone the repository
git clone https://github.com/teephopdisawas/fluffy-parakeet.git
cd fluffy-parakeet

# Install build dependencies
./scripts/install-build-deps.sh

# Build the distribution
make build

# Create ISO image
make iso
```

### Installation

1. Boot from the NASBox ISO/USB
2. Follow the guided installation wizard
3. Configure storage pools
4. Access the web GUI at `http://<nas-ip>:8080`

## Project Structure

```
fluffy-parakeet/
├── base-system/          # Core system components
│   ├── kernel/           # Kernel configuration
│   ├── init/             # Init system (OpenRC-based)
│   └── rootfs/           # Root filesystem structure
├── docker-support/       # Docker integration
├── gui/                  # Lightweight web GUI
│   ├── components/       # UI components
│   ├── themes/           # Dark/Light themes
│   └── assets/           # Static assets
├── nas-features/         # NAS-specific features
│   ├── storage/          # Storage management
│   ├── networking/       # Network services
│   └── services/         # System services
├── build-tools/          # Build system scripts
├── config/               # Default configurations
├── docs/                 # Documentation
└── scripts/              # Utility scripts
```

## Architecture

NASBox is built on these core principles:

1. **Minimal Base**: Built on a minimal musl libc base (Alpine Linux derivative)
2. **Containerized Apps**: Non-essential services run in Docker containers
3. **Modular Design**: Enable only the features you need
4. **Security First**: Secure defaults with easy hardening options

## Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [Docker Setup](docs/docker.md)
- [Storage Management](docs/storage.md)
- [Network Services](docs/networking.md)
- [GUI Customization](docs/gui.md)
- [API Reference](docs/api.md)

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Alpine Linux project for the minimal base
- Docker team for containerization
- Open source NAS community
