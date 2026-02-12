#!/bin/sh

VIDEO_DEV="/dev/video0"
VIDEO_OUT="/tmp/frame.praa"

PASS_COUNT=0
ERROR_COUNT=0

pass () {
    printf '\033[1;32mCAM:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31mCAM: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
}

while :
do
    rm -f "$VIDEO_OUT"
    v4l2-ctl -d "$VIDEO_DEV" --stream-mmap=6 --stream-count=1 --stream-to=/tmp/frame.praa > /dev/null 2>&1

    if [ -f "$VIDEO_OUT" ]; then
        pass "Frame captured successfully"
    else
        error "Failed to capture frame"
    fi

    sleep 1
done
