#!/bin/sh

DEV=${1:-/dev/ttyUSB4}

echo "PC listen on $DEV and reply pong"

exec 3<>"$DEV" || exit 1

while IFS= read -r line <&3
do
  case "$line" in
    PING\ *)
      payload=${line#PING }
      printf 'PONG %s\n' "$payload" >&3
      ;;
    *)
      ;;
  esac
done
