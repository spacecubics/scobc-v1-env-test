#!/bin/sh

DEV=${1:-/dev/ttyUL1}
INTERVAL=${2:-0.1}

pass () {
    printf '\033[1;32mRS485:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

exec 3<>"$DEV" || exit 1

i=0

(
  while :
  do
    hex=$(printf '%08X' "$i")
    printf 'PING %s\n' "$hex" >&3
    i=$((i + 1))
    sleep "$INTERVAL"
  done
) &
SENDER_PID=$!

cleanup() {
  kill "$SENDER_PID" >/dev/null 2>&1 || :
}
trap cleanup INT TERM EXIT

while IFS= read -r line <&3
do
  case "$line" in
    PONG\ *)
      payload=${line#PONG }
      pass "$payload"
      ;;
    *)
      ;;
  esac
done
