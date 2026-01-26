#!/bin/sh

TEMP_DEV=/sys/class/hwmon/hwmon0/temp1_input

PASS_COUNT=0
ERROR_COUNT=0

pass () {
    printf '\033[1;32mI2C:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31mI2C: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
}

while :
do
    if [ -e $TEMP_DEV ]; then
        TEMP=$(cat $TEMP_DEV)
        TEMP_C=$((TEMP / 1000))
        pass "Temperature: ${TEMP_C} °C"
    else
        err "TMP175 is unavailable"
    fi
    sleep 1
done
