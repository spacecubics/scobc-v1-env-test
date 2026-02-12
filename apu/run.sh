#!/bin/sh

PIDS=""
DATE="$(date +%Y%m%d_%H%M%S)"
MY_ADDR=10.30.0.123
GATEWAY_ADDR=10.30.0.234
CONSOLE_DEV=/dev/ttyAMA0
CYCLE_SEC=180

abort() {
    echo ""
    for pid in $PIDS; do
        kill "$pid" 2>/dev/null
    done
    echo "Tests aborted."
    exit 0
}

trap abort INT TERM

cd "$(dirname "$0")" || exit 1

ALL="$(find tests -name "*.sh" | sed -e 's/\.sh$//' -e 's|^tests/||' | sort | xargs)"

if [ "$#" -eq 0 ]; then
    tests="$ALL"
else
    tests="$(echo $* | xargs -n1 | sort | uniq | xargs)"
fi

echo "Waiting for 10s..."
sleep 10
echo "Test started at $DATE: $(echo "$tests" | xargs)"

for test in $tests; do
    if [ ! -f "tests/${test}.sh" ]; then
        echo "Test not found: ${test}"
        continue
    fi

    "tests/${test}.sh" | tee "$CONSOLE_DEV" &
    PIDS="$! $PIDS"
done

ip addr flush dev end0
ip addr add "$MY_ADDR"/24 dev end0
ip route add default via "$GATEWAY_ADDR" dev end0

while :
do
    for pid in $PIDS
    do
        if ! kill -0 "$pid" 2>/dev/null; then
            PIDS="$(echo "$PIDS" | sed -e "s/\b$pid //")"
        fi
    done

    if [ -z "$PIDS" ]; then
        echo "All tests completed."
        break
    fi

    sleep 1
done &

sleep "$CYCLE_SEC"
reboot
