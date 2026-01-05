#!/bin/sh

PASS_COUNT=0
ERROR_COUNT=0
MY_ADDR=10.30.0.123
SERVER_ADDR=10.30.0.234
GATEWAY_ADDR=10.30.0.234

pass () {
    printf '\033[1;32mEthernet:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31mEthernet: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
}

ip addr flush dev end0
ip addr add "$MY_ADDR"/24 dev end0
ip route add default via "$GATEWAY_ADDR" dev end0

while :
do
    if ! wget "$SERVER_ADDR" -O /dev/null -q --timeout=5; then
        error "Cannot reach gateway"
        continue
    fi

    pass "Test successful"
    sleep 1
done
