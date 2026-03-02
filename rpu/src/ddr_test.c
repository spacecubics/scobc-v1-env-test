#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/sys_io.h>
#include <stdint.h>

#define DDR_BASE	(0x00020000u)
#define WORDS		(256u)

void ddr_test(void)
{
	uint32_t expect[WORDS];
	uint32_t got;
	int errors = 0;
	uint32_t i;
	uintptr_t addr;

	for (i = 0; i < WORDS; i++) {
		addr = (uintptr_t)DDR_BASE + (i * 4u);
		expect[i] = 0xA5A50000u ^ i ^ (uint32_t)addr;
		sys_write32(expect[i], addr);
	}

	for (i = 0; i < WORDS; i++) {
		addr = (uintptr_t)DDR_BASE + (i * 4u);
		got = sys_read32(addr);
		if (got != expect[i]) {
			printk("DDR test failed at word %u (addr 0x%08lx): expected 0x%08x, got 0x%08x\n",
				   i, (unsigned long)addr, expect[i], got);
			errors++;
		}
	}

	if (errors == 0) {
		printk("DDR: test passed\n");
	} else {
		printk("DDR: test failed with %d errors\n", errors);
	}
}
