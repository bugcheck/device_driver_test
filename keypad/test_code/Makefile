###############################################################################
# (C) Copyright Texas Instruments - All Rights Reserved
#
# Name of the file: Makefile
#
# Top Makefile for Keypad Test Suite
###############################################################################
OBJS := utilities install

all:$(OBJS)

utilities:
	make -C utils

install:
	mkdir -p scripts/test
	mkdir -p scripts/tmp
	mkdir -p bin/
	make -C utils install

clean:
	make -C utils clean
	rm -rf scripts/log*
	rm -rf scripts/tmp
	rm -rf scripts/test
	rm -rf bin/
