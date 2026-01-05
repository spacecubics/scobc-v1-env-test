#include <zephyr/kernel.h>
#include <zephyr/shell/shell.h>
#include <zephyr/sys/atomic.h>
#include <zephyr/sys/util.h>
#include "versal_sysmon.h"

#define RPU_TEST_STACK_SZ	2048
#define RPU_TEST_PRIO	 	5

K_THREAD_STACK_DEFINE(log_temp_stack, RPU_TEST_STACK_SZ);
K_THREAD_STACK_DEFINE(stress_stack, RPU_TEST_STACK_SZ);

static struct k_thread log_temp_thread;
static struct k_thread stress_thread;

static atomic_t rpu_test_running = ATOMIC_INIT(0);
static atomic_t rpu_test_stop_req = ATOMIC_INIT(0);
static int count = 0;

static volatile double fp_sink;

static void log_temp(void *p1, void *p2, void *p3)
{
	ARG_UNUSED(p1);
	ARG_UNUSED(p2);
	ARG_UNUSED(p3);

	double temp;
	uint32_t next_ms = k_uptime_get_32() + 1000u;
	uint32_t now;
	int32_t remain;

	atomic_clear(&rpu_test_stop_req);

	while (!atomic_get(&rpu_test_stop_req)) {
		now = k_uptime_get_32();
		remain = (int32_t)(next_ms - now);
		if (remain > 0) {
			k_sleep(K_MSEC(remain));
		}
		next_ms += 1000u;

		if (versal_sysmon_temp_read(&temp) == 0) {
			printk("Temperature: %.2f C (%d)\n", temp, ++count);
		} else {
			printk("Failed to read temperature\n");
		}
	}

	atomic_clear(&rpu_test_running);
}

static void stress(void *p1, void *p2, void *p3)
{
	ARG_UNUSED(p1);
	ARG_UNUSED(p2);
	ARG_UNUSED(p3);

	double a;
	double b;
	double c;
	uint32_t i;

	atomic_clear(&rpu_test_stop_req);

	while (!atomic_get(&rpu_test_stop_req)) {
		a = 1.0000001;
		b = 0.9999999;
		c = 0.1234567;

		/* Heavy FP chunk */
		for (i = 0; i < 100000u; i++) {
			a = a + 1e-9 * (b - a * c);
			b = b + 1e-9 * (a - b);
			c = c + 1e-9 * (a * b - c);

			if ((i & 0x3FFu) == 0u) {
				if (a > 10.0) a -= 10.0; else if (a < -10.0) a += 10.0;
				if (b > 10.0) b -= 10.0; else if (b < -10.0) b += 10.0;
				if (c > 10.0) c -= 10.0; else if (c < -10.0) c += 10.0;
			}
		}
		fp_sink = a + b + c;

		k_sleep(K_MSEC(1));
	}

	atomic_clear(&rpu_test_running);
}

static void apu_start(void)
{
	/* Not implemented */
}

static void apu_stop(void)
{
	/* Not implemented */
}

static int rpu_test_start(void)
{
	if (atomic_cas(&rpu_test_running, 0, 1) == false) {
		return -EALREADY;
	}

	atomic_clear(&rpu_test_stop_req);

	k_thread_create(&log_temp_thread,
		log_temp_stack, K_THREAD_STACK_SIZEOF(log_temp_stack),
		log_temp,
		NULL, NULL, NULL,
		RPU_TEST_PRIO, 0, K_NO_WAIT);

	k_thread_name_set(&log_temp_thread, "log_temp");

	k_thread_create(&stress_thread,
		stress_stack, K_THREAD_STACK_SIZEOF(stress_stack),
		stress,
		NULL, NULL, NULL,
		RPU_TEST_PRIO, 0, K_NO_WAIT);

	k_thread_name_set(&stress_thread, "stress");

	return 0;
}

static int rpu_test_stop(void)
{
	if (atomic_get(&rpu_test_running) == 0) {
		return -EALREADY;
	}

	atomic_set(&rpu_test_stop_req, 1);

	k_thread_join(&log_temp_thread, K_FOREVER);
	k_thread_join(&stress_thread, K_FOREVER);

	return 0;
}

static int cmd_apu_start(const struct shell *shell, size_t argc, char **argv)
{
	ARG_UNUSED(argc);
	ARG_UNUSED(argv);

	apu_start();
	shell_print(shell, "APU started");
	return 0;
}

static int cmd_apu_stop(const struct shell *shell, size_t argc, char **argv)
{
	ARG_UNUSED(argc);
	ARG_UNUSED(argv);

	apu_stop();
	shell_print(shell, "APU stopped");
	return 0;
}

static int cmd_rpu_test_start(const struct shell *shell, size_t argc, char **argv)
{
	ARG_UNUSED(argc);
	ARG_UNUSED(argv);

	int ret = rpu_test_start();

	switch(ret) {
		case 0:
			shell_print(shell, "RPU test started");
			break;
		case -EALREADY:
			shell_warn(shell, "RPU test already running");
			break;
		default:
			shell_error(shell, "Failed to start RPU test: %d", ret);
			return ret;
	}

	return 0;
}

static int cmd_rpu_test_stop(const struct shell *shell, size_t argc, char **argv)
{
	ARG_UNUSED(argc);
	ARG_UNUSED(argv);

	int ret = rpu_test_stop();

	switch(ret) {
		case 0:
			shell_print(shell, "RPU test stopped");
			break;
		case -EALREADY:
			shell_warn(shell, "RPU test not running");
			break;
		default:
			shell_error(shell, "Failed to stop RPU test: %d", ret);
			return ret;
	}

	return 0;
}

SHELL_STATIC_SUBCMD_SET_CREATE(apu_subs,
	SHELL_CMD_ARG(start, NULL, "Start the APU", cmd_apu_start, 1, 0),
	SHELL_CMD_ARG(stop,  NULL, "Stop the APU",  cmd_apu_stop,  1, 0),
	SHELL_SUBCMD_SET_END
);

SHELL_CMD_REGISTER(apu, &apu_subs, "Start/Stop the APU", NULL);

SHELL_STATIC_SUBCMD_SET_CREATE(rpu_test_subs,
	SHELL_CMD_ARG(start, NULL, "Start the RPU test", cmd_rpu_test_start, 1, 0),
	SHELL_CMD_ARG(stop,  NULL, "Stop the RPU test",  cmd_rpu_test_stop,  1, 0),
	SHELL_SUBCMD_SET_END
);

SHELL_CMD_REGISTER(test, &rpu_test_subs, "Start/Stop the RPU test", NULL);

int main(void)
{
	rpu_test_start();
	apu_stop();
	return 0;
}
