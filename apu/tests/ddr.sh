#!/bin/sh

taskset 0x2 stress-ng \
    --cache 2 \
    --cache-size 512M \
    --vm 1 \
    --vm-bytes 512M \
    --vm-method rand-sum \
    --metrics-brief > /dev/null 2>&1
