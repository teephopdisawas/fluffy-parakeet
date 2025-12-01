# Storage Management Guide

NASBox supports multiple filesystems and RAID configurations for reliable data storage.

## Supported Filesystems

| Filesystem | Best For | Features |
|------------|----------|----------|
| **ZFS** | Enterprise, critical data | Snapshots, compression, dedup, checksums |
| **Btrfs** | Home users, flexibility | Snapshots, compression, easy expansion |
| **ext4** | Simplicity | Mature, stable, good performance |
| **XFS** | Large files, media | High performance, scalable |

## RAID Levels

### Software RAID (mdadm)

| Level | Min Disks | Capacity | Fault Tolerance |
|-------|-----------|----------|-----------------|
| RAID 0 | 2 | 100% | None |
| RAID 1 | 2 | 50% | 1 disk |
| RAID 5 | 3 | N-1 disks | 1 disk |
| RAID 6 | 4 | N-2 disks | 2 disks |
| RAID 10 | 4 | 50% | 1 disk per mirror |

### ZFS RAID Levels

| Level | Min Disks | Description |
|-------|-----------|-------------|
| Stripe | 1 | No redundancy |
| Mirror | 2 | Like RAID 1 |
| RAIDZ1 | 3 | Like RAID 5 |
| RAIDZ2 | 4 | Like RAID 6 |
| RAIDZ3 | 5 | Triple parity |

## Creating Storage Pools

### Via Web GUI

1. Navigate to **Storage** → **Create Pool**
2. Select disks
3. Choose RAID level
4. Configure options
5. Click **Create**

### Via CLI

#### ZFS Pool

```bash
# Mirror (RAID 1)
nasbox-storage create-zfs mypool mirror /dev/sda /dev/sdb

# RAIDZ1 (RAID 5)
nasbox-storage create-zfs mypool raidz /dev/sda /dev/sdb /dev/sdc

# RAIDZ2 (RAID 6)
nasbox-storage create-zfs mypool raidz2 /dev/sda /dev/sdb /dev/sdc /dev/sdd
```

#### Btrfs Pool

```bash
# RAID 1
nasbox-storage create-btrfs mypool raid1 /dev/sda /dev/sdb

# RAID 5
nasbox-storage create-btrfs mypool raid5 /dev/sda /dev/sdb /dev/sdc
```

#### mdadm RAID

```bash
# RAID 5
nasbox-storage create-mdraid mypool 5 /dev/sda /dev/sdb /dev/sdc
```

## Pool Management

### Check Pool Status

```bash
# All pools
nasbox-storage status all

# Specific pool
nasbox-storage status mypool
```

### Expand Pool

#### ZFS

```bash
# Add another mirror pair
zpool add mypool mirror /dev/sdc /dev/sdd

# Replace disk with larger one
zpool replace mypool /dev/sda /dev/sde
```

#### Btrfs

```bash
# Add disk
btrfs device add /dev/sdc /mnt/storage/mypool

# Rebalance
btrfs balance start /mnt/storage/mypool
```

## Snapshots

### Create Snapshot

```bash
# ZFS
nasbox-storage snapshot mypool

# With name
nasbox-storage snapshot mypool "before-upgrade"
```

### List Snapshots

```bash
# ZFS
zfs list -t snapshot

# Btrfs
btrfs subvolume list -s /mnt/storage/mypool
```

### Restore Snapshot

```bash
# ZFS
zfs rollback mypool@snapshot-name

# Btrfs
btrfs subvolume snapshot /mnt/storage/mypool/.snapshots/name /mnt/storage/mypool
```

### Automatic Snapshots

Configure in GUI: **Storage** → **Snapshots** → **Schedule**

Or via config:
```bash
# /etc/nasbox/snapshot.conf
[mypool]
schedule = daily
keep = 7
```

## Disk Health Monitoring

### SMART Status

```bash
# Check all disks
nasbox-storage disk-health all

# Specific disk
nasbox-storage disk-health sda

# Temperature
nasbox-storage disk-temp sda
```

### Enable Monitoring

```bash
nasbox-storage smart-monitor
```

### Alert Configuration

Edit `/etc/nasbox/storage.conf`:
```ini
[alerts]
email = admin@example.com
temperature_warning = 45
temperature_critical = 55
```

## Scrubbing

Scrub verifies data integrity and repairs corruption.

### Manual Scrub

```bash
# ZFS
zpool scrub mypool

# Check progress
zpool status mypool
```

### Scheduled Scrub

By default, ZFS pools are scrubbed monthly. Configure in:
- GUI: **Storage** → **Maintenance**
- Config: `/etc/nasbox/storage.conf`

## Troubleshooting

### Degraded RAID

```bash
# Check status
zpool status mypool

# Replace failed disk
zpool replace mypool /dev/failed /dev/new
```

### Disk Failure

1. Identify failed disk
2. Order replacement
3. Replace disk
4. Resilver/rebuild RAID

### Performance Issues

```bash
# Check I/O stats
iostat -x 1

# ZFS cache stats
arcstat
```

## Best Practices

1. **Regular backups** - RAID is not a backup!
2. **Use ECC RAM** - Especially with ZFS
3. **Monitor disk health** - Enable SMART monitoring
4. **Schedule scrubs** - Monthly recommended
5. **Keep spares** - For quick replacements
6. **Test restores** - Verify your backups work
