#!/bin/sh

DEV=/dev/sda
MNT=mnt/usb

PASS_COUNT=0
ERROR_COUNT=0

pass () {
    printf '\033[1;32mUSB:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31mUSB: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
}

mkdir -p "$MNT"

while :
do
    if [ ! -e "$DEV" ]; then
        error "Device $DEV not found"
        sleep 1
        continue
    fi

    printf "o\nn\np\n1\n\n\nw\n" | fdisk "$DEV" >/dev/null 2>&1
    mkfs.vfat -F 32 "${DEV}1" >/dev/null 2>&1
    sync

    if ! mount "${DEV}1" "$MNT" 2>/dev/null; then
        error "Failed to mount $DEV"
        sleep 1
        continue
    fi

    dd if=/dev/urandom of=/tmp/usbtest.bin bs=1M count=128 2>/dev/null

    if ! cp /tmp/usbtest.bin "$MNT/usbtest.bin" 2>/dev/null; then
        error "Failed to write to device"
        umount "$MNT"
        sleep 1
        continue
    fi

    if ! cmp /tmp/usbtest.bin "$MNT/usbtest.bin" > /dev/null 2>&1; then
        error "Data verification failed"
        umount "$MNT"
        sleep 1
        continue
    fi

    rm /tmp/usbtest.bin
    umount "$MNT"
    pass "Test successful"
done
