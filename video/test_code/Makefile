###########################################################################
# (C) Copyright Texas Instruments, 2007. All Rights Reserved.
#
# Name of the file: Makefile
#
# Location of the file:
#
# Brief description of the contents of the file:
#       Makefile for Video Tests
#
# Detailed description of the contents of the file:
# This Makefile is used to compile OneNAND test programs.
#
# Author: 
#
# Created on: 
#
# Change Log:
############################################################################

ifeq ($(SUITE_DIR),)
SUITE_DIR=$(PWD)
endif

DESTDIR := $(SUITE_DIR)/bin
OBJS := utilities install

all: $(OBJS)

utilities:
	make -C utils

install:
	mkdir -p $(DESTDIR)
	make -C utils install
	mkdir -p scripts/test
	mkdir -p scripts/tmp

clean:
	rm -rvf $(DESTDIR)
	make -C utils clean
	rm -rf scripts/log*
	rm -rf scripts/tmp
	rm -rf scripts/test
