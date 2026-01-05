#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/sys_io.h>
#include <stdint.h>

#define SYSMON_BASE	0xF1270000u

/* Offsets in PMC_SYSMON_CSR */
#define REG_DEVICE_TEMP		0x1030u   /* instantaneous device temp (Q8.7 °C) */
#define REG_DEVICE_TEMP_MAX	0x1F90u   /* max temp since cleared (Q8.7 °C) */

static double q8_7_to_celsius_d(uint16_t raw_q8_7)
{
    int16_t s = (int16_t)raw_q8_7;
    return (double)s / 128.0;
}

int versal_sysmon_temp_read(double *temp)
{
	uint32_t v;
	uint16_t raw;

	v = sys_read32(SYSMON_BASE + REG_DEVICE_TEMP_MAX);
	raw = (uint16_t)(v & 0xFFFFu);

	/* DEVICE_TEMP_MAX reset value is 0x8000 (treat as invalid / not updated) */
	if (raw == 0x8000u) {
		return -EAGAIN;
	}

	v = sys_read32(SYSMON_BASE + REG_DEVICE_TEMP);
	raw = (uint16_t)(v & 0xFFFFu);

	if (raw == 0x8000u) {
		return -EAGAIN;
	}

	*temp = q8_7_to_celsius_d(raw);

	return 0;
}
