#!/bin/sh

DEV=/dev/mmcblk1
MNT=mnt/emmc

PASS_COUNT=0
ERROR_COUNT=0

pass () {
    printf '\033[1;32meMMC:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31meMMC: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
}

mkdir -p "$MNT"

while :
do
    if [ ! -e "$DEV" ]; then
        error "Device $DEV not found"
        sleep 1
        continue
    fi

    if ! mount "${DEV}p2" "$MNT" 2>/dev/null; then
        error "Failed to mount $DEV"
        sleep 1
        continue
    fi

    dd if=/dev/urandom of=/tmp/emmctest.bin bs=1M count=50 2>/dev/null

    if ! cp /tmp/emmctest.bin "$MNT/emmctest.bin" 2>/dev/null; then
        error "Failed to write to device"
        umount "$MNT" > /dev/null 2>&1
        sleep 1
        continue
    fi

    if ! cmp /tmp/emmctest.bin "$MNT/emmctest.bin" > /dev/null 2>&1; then
        error "Data verification failed"
        umount "$MNT" > /dev/null 2>&1
        sleep 1
        continue
    fi

    rm /tmp/emmctest.bin
    umount "$MNT" > /dev/null 2>&1
    pass "Test successful"
done
