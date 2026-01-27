#!/bin/sh

IF=${1:-can0}
TX_ID=200
RX_ID=100

echo "PC starts CAN pong test on $IF (RX=$RX_ID -> TX=$TX_ID)"

candump "$IF,$RX_ID:7FF" | while IFS= read -r line
do
    bytes=$(printf '%s\n' "$line" | sed -n 's/.*] //p')
    [ -n "$bytes" ] || continue

    payload=$(printf '%s\n' "$bytes" | tr ' ' '.')

    cansend "$IF" "${TX_ID}#${payload}"
done
