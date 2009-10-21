/*
 * SRF/resource-debug-test.c
 * OMAP3 SRF test file
 *
 * Copyright (C) 2009-2010 Texas Instruments, Inc.
 * Charulatha Varadarajan <charu@ti.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * THIS PACKAGE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 * History:
 *
 * 2009-09-17: Charulatha V         Initial code
 *
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/file.h>
#include <asm/uaccess.h>
#include <linux/mm.h>

MODULE_LICENSE("GPL");

extern void resource_test(void);

int __init resource_test_init(void)
{
        resource_test();
        printk("\nEnd of Test...\n");
        return 0;
}

void __exit resource_test_exit(void)
{
        printk(" \nExiting Module \n");
        printk(" Done \n");
}

module_init(resource_test_init);
module_exit(resource_test_exit);
