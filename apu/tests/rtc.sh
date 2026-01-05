#!/bin/sh

RTC_PATH="/sys/class/rtc/rtc0/since_epoch"

PASS_COUNT=0
ERROR_COUNT=0

pass () {
    printf '\033[1;32mRTC:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31mRTC: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
}

while :
do
    hwclock -w

    EPOCH_SYS="$(date +%s)"
    EPOCH_RTC="$(cat "$RTC_PATH" 2>/dev/null)"

    DIFF=$(( EPOCH_RTC - EPOCH_SYS ))
    if [ "$DIFF" -ge -2 ] && [ "$DIFF" -le 2 ]; then
        pass "RTC is synchronized with system time"
    else
        error "RTC is out of sync by $DIFF seconds"
    fi

    sleep 10
done
