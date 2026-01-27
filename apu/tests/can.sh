#!/bin/sh

IF=${1:-can0}
INTERVAL=${2:-0.1}

TX_ID=100
RX_ID=200

i=0
PASS_COUNT=0

pass () {
    printf '\033[1;32mCAN:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

(
  while :
  do
    hex=$(printf '%08X' "$i")
    b1=$(printf '%s' "$hex" | cut -c1-2)
    b2=$(printf '%s' "$hex" | cut -c3-4)
    b3=$(printf '%s' "$hex" | cut -c5-6)
    b4=$(printf '%s' "$hex" | cut -c7-8)
    payload="${b1}.${b2}.${b3}.${b4}"

    cansend "$IF" "${TX_ID}#${payload}" >/dev/null 2>&1 || :
    i=$((i + 1))

    sleep "$INTERVAL"
  done
) &
SENDER_PID=$!

cleanup() {
  kill "$SENDER_PID" >/dev/null 2>&1 || :
}
trap cleanup INT TERM EXIT

ip link set can0 down
ip link set can0 up type can bitrate 1000000

candump "$IF,$RX_ID:7FF" | while IFS= read -r line
do
    bytes=$(printf '%s\n' "$line" | sed -n 's/.*] //p')
    [ -n "$bytes" ] || continue

    pass "$bytes"
done
