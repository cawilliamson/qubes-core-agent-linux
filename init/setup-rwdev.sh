#!/bin/sh

set -e

dev=/dev/xvdb
max_size=1073741824  # check at most 1 GiB

if [ -e "$dev" ] ; then
    # The private /dev/xvdb device is present.

    # check if private.img (xvdb) is empty - all zeros
    private_size=$(( $(blockdev --getsz "$dev") * 512))
    if [ $private_size -gt $max_size ]; then
        private_size=$max_size
    fi
    if cmp --bytes $private_size "$dev" /dev/zero >/dev/null && { blkid -p "$dev" >/dev/null; [ $? -eq 2 ]; }; then
        # the device is empty, create filesystem
        echo "Virgin boot of the VM: creating private.img filesystem on $dev" >&2
        if ! content=$(mkfs.xfs -q "$dev" 2>&1) ; then
            echo "Virgin boot of the VM: creation of private.img on $dev failed:" >&2
            echo "$content" >&2
            echo "Virgin boot of the VM: aborting" >&2
            exit 1
        fi
        if ! content=$(xfs_growfs "$dev" 2>&1) ; then
            echo "Virgin boot of the VM: marking free space on $dev as usable failed:" >&2
            echo "$content" >&2
            echo "Virgin boot of the VM: aborting" >&2
            exit 1
        fi
    fi

    echo "Private device management: checking $dev" >&2
    if content=$(fsck.xfs "$dev" 2>&1) ; then
        echo "Private device management: fsck.xfs of $dev succeeded" >&2
    else
        echo "Private device management: fsck.xfs $dev failed:" >&2
        echo "$content" >&2
    fi
fi
