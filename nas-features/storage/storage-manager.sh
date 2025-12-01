#!/bin/bash
# NASBox Storage Management Module
# Handles disk pools, RAID, and ZFS/Btrfs management

set -e

# Configuration
STORAGE_CONFIG="/etc/nasbox/storage.conf"
MOUNT_BASE="/mnt/storage"
LOG_FILE="/var/log/nasbox/storage.log"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# List all available disks
list_disks() {
    log "Listing available disks"
    lsblk -d -o NAME,SIZE,TYPE,MODEL,SERIAL | grep -E "disk"
}

# Get disk health via SMART
get_disk_health() {
    local disk=$1
    if command -v smartctl &> /dev/null; then
        smartctl -H "/dev/$disk" 2>/dev/null | grep -i "health\|status"
    else
        echo "smartctl not installed"
    fi
}

# Get disk temperature
get_disk_temp() {
    local disk=$1
    if command -v smartctl &> /dev/null; then
        smartctl -A "/dev/$disk" 2>/dev/null | grep -i temperature | head -1
    fi
}

# Create ZFS pool
create_zfs_pool() {
    local pool_name=$1
    local raid_level=$2
    shift 2
    local disks=("$@")
    
    log "Creating ZFS pool: $pool_name with $raid_level"
    
    case $raid_level in
        "mirror")
            zpool create -f "$pool_name" mirror "${disks[@]}"
            ;;
        "raidz")
            zpool create -f "$pool_name" raidz "${disks[@]}"
            ;;
        "raidz2")
            zpool create -f "$pool_name" raidz2 "${disks[@]}"
            ;;
        *)
            zpool create -f "$pool_name" "${disks[@]}"
            ;;
    esac
    
    # Enable compression by default
    zfs set compression=lz4 "$pool_name"
    # Set mount point
    zfs set mountpoint="${MOUNT_BASE}/${pool_name}" "$pool_name"
    
    log "ZFS pool $pool_name created successfully"
}

# Create BTRFS pool
create_btrfs_pool() {
    local pool_name=$1
    local raid_level=$2
    shift 2
    local disks=("$@")
    
    log "Creating BTRFS pool: $pool_name with $raid_level"
    
    mkfs.btrfs -L "$pool_name" -d "$raid_level" -m "$raid_level" "${disks[@]}"
    
    mkdir -p "${MOUNT_BASE}/${pool_name}"
    mount -t btrfs -o compress=zstd LABEL="$pool_name" "${MOUNT_BASE}/${pool_name}"
    
    # Add to fstab
    echo "LABEL=$pool_name ${MOUNT_BASE}/${pool_name} btrfs defaults,compress=zstd 0 0" >> /etc/fstab
    
    log "BTRFS pool $pool_name created successfully"
}

# Create mdadm RAID array
create_mdraid() {
    local pool_name=$1
    local raid_level=$2
    shift 2
    local disks=("$@")
    local device="/dev/md/${pool_name}"
    
    log "Creating mdadm RAID: $pool_name with level $raid_level"
    
    mdadm --create "$device" --level="$raid_level" --raid-devices=${#disks[@]} "${disks[@]}"
    
    # Wait for array to sync
    mdadm --wait "$device" || true
    
    # Create filesystem
    mkfs.ext4 -L "$pool_name" "$device"
    
    mkdir -p "${MOUNT_BASE}/${pool_name}"
    mount "$device" "${MOUNT_BASE}/${pool_name}"
    
    # Save mdadm configuration
    mdadm --detail --scan >> /etc/mdadm/mdadm.conf
    
    # Add to fstab
    echo "$device ${MOUNT_BASE}/${pool_name} ext4 defaults 0 0" >> /etc/fstab
    
    log "mdadm RAID $pool_name created successfully"
}

# Get pool status
get_pool_status() {
    local pool_name=$1
    
    echo "=== Pool Status: $pool_name ==="
    
    # Check ZFS
    if zpool list "$pool_name" &>/dev/null; then
        zpool status "$pool_name"
        zfs list "$pool_name"
        return
    fi
    
    # Check BTRFS
    if btrfs filesystem show -m "${MOUNT_BASE}/${pool_name}" &>/dev/null; then
        btrfs filesystem show -m "${MOUNT_BASE}/${pool_name}"
        btrfs filesystem df "${MOUNT_BASE}/${pool_name}"
        return
    fi
    
    # Check mdadm
    if mdadm --detail "/dev/md/${pool_name}" &>/dev/null; then
        mdadm --detail "/dev/md/${pool_name}"
        return
    fi
    
    echo "Pool not found"
}

# Create snapshot (ZFS/BTRFS)
create_snapshot() {
    local pool_name=$1
    local snapshot_name=${2:-$(date +%Y%m%d_%H%M%S)}
    
    log "Creating snapshot: ${pool_name}@${snapshot_name}"
    
    # ZFS snapshot
    if zfs list "$pool_name" &>/dev/null; then
        zfs snapshot "${pool_name}@${snapshot_name}"
        log "ZFS snapshot created: ${pool_name}@${snapshot_name}"
        return
    fi
    
    # BTRFS snapshot
    if [ -d "${MOUNT_BASE}/${pool_name}" ]; then
        local snap_dir="${MOUNT_BASE}/${pool_name}/.snapshots"
        mkdir -p "$snap_dir"
        btrfs subvolume snapshot -r "${MOUNT_BASE}/${pool_name}" "${snap_dir}/${snapshot_name}"
        log "BTRFS snapshot created: ${snap_dir}/${snapshot_name}"
        return
    fi
    
    log "ERROR: Cannot create snapshot for $pool_name"
}

# Start SMART monitoring
start_smart_monitoring() {
    log "Starting SMART monitoring"
    
    # Create smartd configuration
    cat > /etc/smartd.conf << EOF
# NASBox SMART Configuration
# Monitor all disks
DEVICESCAN -a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,45,55 -m root -M exec /usr/local/bin/nasbox-smart-alert
EOF
    
    # Start smartd
    rc-service smartd restart || systemctl restart smartd
}

# Main function
main() {
    case $1 in
        "list-disks")
            list_disks
            ;;
        "disk-health")
            get_disk_health "$2"
            ;;
        "disk-temp")
            get_disk_temp "$2"
            ;;
        "create-zfs")
            shift
            create_zfs_pool "$@"
            ;;
        "create-btrfs")
            shift
            create_btrfs_pool "$@"
            ;;
        "create-mdraid")
            shift
            create_mdraid "$@"
            ;;
        "status")
            get_pool_status "$2"
            ;;
        "snapshot")
            create_snapshot "$2" "$3"
            ;;
        "smart-monitor")
            start_smart_monitoring
            ;;
        *)
            echo "NASBox Storage Management"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  list-disks              List all available disks"
            echo "  disk-health <disk>      Get SMART health for disk"
            echo "  disk-temp <disk>        Get disk temperature"
            echo "  create-zfs <name> <level> <disks...>   Create ZFS pool"
            echo "  create-btrfs <name> <level> <disks...> Create BTRFS pool"
            echo "  create-mdraid <name> <level> <disks...> Create mdadm RAID"
            echo "  status <pool>           Get pool status"
            echo "  snapshot <pool> [name]  Create snapshot"
            echo "  smart-monitor           Start SMART monitoring"
            ;;
    esac
}

main "$@"
