#/* ================================================================================
#             Texas Instruments OMAP(TM) Platform Software
#  (c) Copyright Texas Instruments, Incorporated.  All Rights Reserved.
#
#  Use of this software is controlled by the terms and conditions found
#  in the license agreement under which this software has been supplied.
# ================================================================================ */

SUBDIRS = watchdog_apps

all: $(SUBDIRS)

install:
	make -C watchdog install

watchdog_apps:
	make -C watchdog

clean:
	make -C watchdog clean
