#!/bin/sh

DEV=/dev/mtd0
ERASED_BIN=/tmp/erased.bin
NOR_BANK_START=0x3FC0000
NOR_BANK_SIZE=0x40000

PASS_COUNT=0
ERROR_COUNT=0

pass () {
    printf '\033[1;32mNOR Flash:\033[0m %s (%d)\n' "$1" "$((++PASS_COUNT))"
}

error () {
    printf '\033[1;31mNOR Flash: %s (%d)\033[0m\n' "$1" "$((++ERROR_COUNT))"
}

get_chip_num () {
    case "$1" in
        lpd)
            LABEL="versal_gpio"
            ;;
        pmc)
            LABEL="pmc_gpio"
            ;;
        pl)
            LABEL="\.gpio"
            ;;
        *)
            return 1
            ;;
    esac

    gpiodetect | grep "$LABEL" | awk '{print $1}' | sed 's/gpiochip//g'
}

switch_nor_bank () {
    BANK="$1"

    case "$BANK" in
        1)
            GPIO_VALUE=0
            ;;
        2)
            GPIO_VALUE=1
            ;;
        *)
            return 1
            ;;
    esac

    # In libgpiod2, gpioset does not exit on SIGKILL immediately,
    # so we need to kill -9 and wait
    gpioset -c "$(get_chip_num pmc)" 50="$GPIO_VALUE" 2> /dev/null &
    PID=$!
    sleep 0.1

    kill -9 "$PID" > /dev/null 2>&1
    wait "$PID" > /dev/null 2>&1
}

# Prepare erased pattern
dd if=/dev/zero bs=16 count=1 2> /dev/null | tr '\000' '\377' > "$ERASED_BIN"

# Prepare test data for each bank
for bank in 1 2
do
    echo "SPI NOR Flash $bank" > "/tmp/nor${bank}.bin"
done

while :
do
    if [ ! -e "$DEV" ]; then
        error "Device $DEV not found"
        sleep 1
        continue
    fi

    for bank in 1 2
    do
        # Select bank
        switch_nor_bank "$bank"
        SIZE=$(wc -c "$ERASED_BIN" | awk '{print $1}')

        # Erase and verify
        mtd_debug erase "$DEV" "$NOR_BANK_START" "$NOR_BANK_SIZE" > /dev/null 2>&1
        mtd_debug read "$DEV" "$NOR_BANK_START" "$SIZE" "/tmp/nor_readback${bank}.bin" > /dev/null 2>&1
        sync

        if ! cmp "$ERASED_BIN" "/tmp/nor_readback${bank}.bin" > /dev/null 2>&1; then
            error "Erase verification failed on NOR bank $bank"
            continue
        fi
    done

    for bank in 1 2
    do
        # Select bank
        switch_nor_bank "$bank"
        SIZE=$(wc -c "/tmp/nor${bank}.bin" | awk '{print $1}')

        # Write and verify
        mtd_debug write "$DEV" "$NOR_BANK_START" "$SIZE" "/tmp/nor${bank}.bin" > /dev/null 2>&1
        sync
        mtd_debug read "$DEV" "$NOR_BANK_START" "$SIZE" "/tmp/nor_readback${bank}.bin" > /dev/null 2>&1
        sync

        if ! cmp "/tmp/nor${bank}.bin" "/tmp/nor_readback${bank}.bin" > /dev/null 2>&1; then
            error "Data mismatch on NOR bank $bank"
            continue
        fi

        pass "Test successful on NOR bank $bank"
    done
done
