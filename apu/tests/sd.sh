#!/bin/sh

DEV=/dev/mmcblk0
MNT=mnt/sd

PASS_COUNT=0
ERROR_COUNT=0

pass () {
    printf '\033[1;32mSD:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31mSD: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
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

    dd if=/dev/urandom of=/tmp/sdtest.bin bs=1M count=50 2>/dev/null

    if ! cp /tmp/sdtest.bin "$MNT/sdtest.bin" 2>/dev/null; then
        error "Failed to write to device"
        umount "$MNT" > /dev/null 2>&1
        sleep 1
        continue
    fi

    if ! cmp /tmp/sdtest.bin "$MNT/sdtest.bin" > /dev/null 2>&1; then
        error "Data verification failed"
        umount "$MNT" > /dev/null 2>&1
        sleep 1
        continue
    fi

    rm /tmp/sdtest.bin
    umount "$MNT" > /dev/null 2>&1
    pass "Test successful"
done
