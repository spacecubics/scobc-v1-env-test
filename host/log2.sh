#!/bin/sh

DATE="$(date +%Y%m%d)"
LOG_DIR="log/${DATE}/2"

cd $(dirname "$0") || exit 1

case "$1" in
    apu)
        LOG_NAME=apu
        TTY_DEVICE=/dev/ttyUSB5
        ;;

    rpu)
        LOG_NAME=rpu
        TTY_DEVICE=/dev/ttyUSB6
        ;;

    igloo2)
        LOG_NAME=igloo2
        TTY_DEVICE=/dev/ttyUSB7
        ;;

    *)
        echo "Usage: $0 {apu|rpu|igloo2}"
        exit 1
        ;;
esac

mkdir -p "$LOG_DIR"

tio -t -L --log-append --log-file "${LOG_DIR}/${LOG_NAME}.log" "$TTY_DEVICE"
