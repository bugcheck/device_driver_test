#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/irq.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/version.h>
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 27) && LINUX_VERSION_CODE <= KERNEL_VERSION(2, 6, 31))
 #include <mach/dmtimer.h>
#elif LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 32)
 #include <plat/dmtimer.h>
#else
 #include <asm/arch/dmtimer.h>
#endif
#include <linux/clk.h>
#include <linux/types.h>
#include <linux/delay.h>
#include <linux/io.h>
#include <linux/sched.h>
#include <linux/kthread.h>

MODULE_DESCRIPTION("GP Timer Request and Reserve Test Module");
MODULE_LICENSE("GPL");

/*Pointer to timer struct*/
static struct omap_dm_timer *timer_ptr;

/*The IRQ # for the current gp timer*/
static int32_t timer_irq;

/* Delay in Sec's between two timer value query */
static uint delay = 1;
static uint iterations = 1;
module_param(delay, int, S_IRUGO|S_IWUSR);
module_param(iterations, int, S_IRUGO|S_IWUSR);

static void  gptimer_keepreading_counter(void *info)
{
	int i;
	unsigned int timer_count;
	for (i = 0 ; i < iterations ; i++) {
		timer_count = omap_dm_timer_read_counter(timer_ptr);
		printk(KERN_INFO "Timer count before delay: %u\n", timer_count);

		ssleep(delay);

		timer_count = omap_dm_timer_read_counter(timer_ptr);
		printk(KERN_INFO "Timer count after delay: %u\n", timer_count);
	}
}

static int __init gptimer_request_init(void)
{
	struct clk *gt_fclk;
	uint32_t gt_rate;
	unsigned int timer_count;
	struct task_struct *p1, *p2;
	int x;

	printk(KERN_INFO "Starting the Timer test\n");
	/*Requesting for any available timer*/
	timer_ptr = omap_dm_timer_request();

	if (timer_ptr == NULL) {
		/*Timers are not available*/
		printk(KERN_ERR "GPtimers are not available\n");
		return -1;
	}

	/*Set the clock source to 32Khz Clock*/
	printk(KERN_INFO "Using OMAP_TIMER_SRC_32_KHZ source\n");
	omap_dm_timer_set_source(timer_ptr, OMAP_TIMER_SRC_32_KHZ);

	/*Figure out what IRQ our timer triggers*/
	timer_irq = omap_dm_timer_get_irq(timer_ptr);

	/*Get clock rate in Hz*/
	gt_fclk = omap_dm_timer_get_fclk(timer_ptr);
	gt_rate = clk_get_rate(gt_fclk);

	/*Start the timer!*/
	omap_dm_timer_start(timer_ptr);

	printk(KERN_INFO "GP Timer initialized and started (%lu Hz, IRQ %d)\n",
		(long unsigned)gt_rate, timer_irq);

	/* Kernel threadsfor SMP test */
	p1 = kthread_create(gptimer_keepreading_counter, NULL , "timertest/0");
	p2 = kthread_create(gptimer_keepreading_counter, NULL , "timertest/1");
	kthread_bind(p1, 0);
	kthread_bind(p2, 1);
	x = wake_up_process(p1);
	x = wake_up_process(p2);

	return 0;
}

static void __exit gptimer_request_exit(void)
{
	/*Stop the timer*/
	omap_dm_timer_stop(timer_ptr);

	/*Release the timer*/
	omap_dm_timer_free(timer_ptr);

	printk(KERN_INFO "GP Timer finalized and stoped\n");
}

module_init(gptimer_request_init);
module_exit(gptimer_request_exit);
