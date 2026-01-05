#!/bin/sh

BOOT_MODE="$1"
TCL="./tcl/boot/${BOOT_MODE}.tcl"
LIST="$(ls ./tcl/boot/*.tcl | xargs -n 1 basename | sed 's/\.tcl//' | xargs)"

if [ ! -f "$TCL" ]; then
    echo "Error: Unsupported BOOT_MODE '$BOOT_MODE'"
    echo "Supported boot modes: $LIST"
    exit 1
fi

xsdb "$TCL"
