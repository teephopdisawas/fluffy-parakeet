# NASBox Installation Guide

## Overview

This guide will walk you through installing NASBox on your NAS hardware.

## Prerequisites

- 64-bit x86 processor (x86_64/AMD64)
- Minimum 512MB RAM (2GB+ recommended)
- Boot drive: 2GB minimum (8GB+ SSD recommended)
- One or more data drives for storage
- Network connection

## Installation Methods

### Method 1: USB Boot Installation

1. **Download the ISO**
   ```bash
   wget https://github.com/teephopdisawas/fluffy-parakeet/releases/latest/download/nasbox.iso
   ```

2. **Create bootable USB**
   ```bash
   # Linux/macOS
   sudo dd if=nasbox.iso of=/dev/sdX bs=4M status=progress
   
   # Or use tools like:
   # - Rufus (Windows)
   # - balenaEtcher (all platforms)
   ```

3. **Boot from USB**
   - Insert USB drive into your NAS
   - Enter BIOS/UEFI (usually F2, F12, or Del)
   - Select USB as boot device
   - Save and restart

4. **Run installer**
   - Select "Install NASBox" from boot menu
   - Follow the guided installation wizard

### Method 2: Network Boot (PXE)

For multiple NAS deployments, PXE installation is supported.

1. Configure your DHCP server with PXE options
2. Set up TFTP server with NASBox boot files
3. Boot NAS from network

### Method 3: Virtual Machine

For testing or development:

```bash
# Create VM with QEMU
qemu-system-x86_64 \
    -m 2G \
    -smp 2 \
    -cdrom nasbox.iso \
    -hda nasbox-disk.qcow2 \
    -boot d \
    -net nic -net user,hostfwd=tcp::8080-:8080
```

## Installation Wizard

### Step 1: Language & Timezone

Select your preferred language and timezone.

### Step 2: Network Configuration

- **DHCP (Recommended)**: Automatic IP configuration
- **Static IP**: Manual configuration
  - IP Address: e.g., 192.168.1.100
  - Subnet Mask: e.g., 255.255.255.0
  - Gateway: e.g., 192.168.1.1
  - DNS: e.g., 1.1.1.1, 8.8.8.8

### Step 3: Disk Selection

- Select the boot drive (SSD recommended)
- **WARNING**: The boot drive will be erased!
- Do NOT select data drives for boot installation

### Step 4: Storage Configuration

Configure your data storage:

| RAID Level | Minimum Disks | Description |
|------------|---------------|-------------|
| Single | 1 | No redundancy |
| Mirror | 2 | Full copy on each disk |
| RAID-Z1 | 3 | Single parity (lose 1 disk) |
| RAID-Z2 | 4 | Double parity (lose 2 disks) |

### Step 5: User Setup

Create your admin account:
- Username
- Password (must be secure!)

### Step 6: Confirmation

Review settings and confirm installation.

## Post-Installation

### First Login

1. Access web GUI: `http://<nas-ip>:8080`
2. Login with your admin credentials
3. Complete initial setup wizard

### Recommended First Steps

1. **Change default passwords** - Essential for security
2. **Configure network shares** - Set up SMB/NFS shares
3. **Enable services** - Docker, FTP, etc.
4. **Set up backups** - Snapshot schedules
5. **Update system** - Check for updates

### SSH Access

```bash
ssh admin@nasbox.local
# or
ssh admin@<nas-ip>
```

## Troubleshooting

### Boot Issues

- Verify BIOS settings (UEFI/Legacy mode)
- Check USB drive integrity
- Try different USB port

### Network Issues

- Verify cable connection
- Check DHCP server
- Try static IP configuration

### Installation Fails

- Check minimum requirements
- Verify drive health
- Review installation logs: `/var/log/nasbox/install.log`

## Support

- GitHub Issues: https://github.com/teephopdisawas/fluffy-parakeet/issues
- Documentation: https://github.com/teephopdisawas/fluffy-parakeet/wiki
