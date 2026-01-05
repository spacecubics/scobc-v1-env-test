#!/bin/sh

MY_ADDR=10.30.0.123
GATEWAY_ADDR=10.30.0.234

ip addr flush dev end0
ip addr add "$MY_ADDR"/24 dev end0
ip route add default via "$GATEWAY_ADDR" dev end0
