#!/bin/sh

taskset 0x2 stress-ng \
    --cpu 1 \
    --cpu-method float64 \
    --metrics-brief > /dev/null 2>&1
