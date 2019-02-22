#!/bin/sh

# Possibly resize root device (partition, filesystem), if underlying device was
# enlarged.

set -e

# if underlying root device is read-only, don't do anything
if [ "$(blockdev --getro /dev/xvda)" -eq "1" ]; then
    echo "xvda is read-only, not resizing" >&2
    exit 0
fi

sysfs_xvda="/sys/class/block/xvda"

# if root filesystem is already using (almost) the whole disk
# 203M for BIOS and /boot data
boot_data_size=$((203 * 2 * 1024))
# rootfs size is calculated on-the-fly. `df` doesn't work because it doesn't
# include fs overhead, and calculating a static size for overhead doesn't work
# because that can change dynamically over the filesystem's lifetime.
# See QubesOS/qubes-core-agent-linux#146 and QubesOS/qubes-core-agent-linux#152
# for more details
xfs_block_count=$(xfs_info /dev/mapper/dmroot | grep -En 's/data.*blocks=([[:digit:]]*).*/\1/p')
xfs_block_size=$(xfs_info /dev/mapper/dmroot | grep -En 's/data.*bsize=([[:digit:]]*).*/\1/p')
rootfs_size=$((xfs_block_count * xfs_block_size / 512))
# 5 MB in 512-byte units for some random extra bits
size_margin=$((5 * 1024 * 2))
if [ "$(cat $sysfs_xvda/size)" -lt \
       $(( rootfs_size + boot_data_size + size_margin )) ]; then
   echo "root filesystem already at $rootfs_size blocks" >&2
   exit 0
fi

# resize needed, do it
/usr/lib/qubes/resize-rootfs
