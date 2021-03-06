#!/bin/sh

# TestSuite General Variables
export OSKERNEL_POSTFIX=`date "+%Y%m%d-%H%M%S"`
export OSKERNEL_ROOT=`pwd`

export OSKERNEL_DIR_BINARIES=${OSKERNEL_ROOT}/../bin
export OSKERNEL_DIR_HELPER=${OSKERNEL_ROOT}/helper
export OSKERNEL_DIR_TMP=${OSKERNEL_ROOT}/tmp
export OSKERNEL_DIR_TEST=${OSKERNEL_ROOT}/test
export OSKERNEL_DIR_SCENARIOS="${OSKERNEL_ROOT}/scenarios"

export OSKERNEL_FILE_OUTPUT=${OSKERNEL_ROOT}/output.$OSKERNEL_POSTFIX
export OSKERNEL_FILE_LOG=${OSKERNEL_ROOT}/log.$OSKERNEL_POSTFIX
export OSKERNEL_FILE_TMP=${OSKERNEL_DIR_TMP}/tmp.$OSKERNEL_POSTFIX
export OSKERNEL_FILE_CMD=cmd.$OSKERNEL_POSTFIX

export OSKERNEL_DURATION=""
export OSKERNEL_PRETTY_PRT=""
export OSKERNEL_VERBOSE=""
export OSKERNEL_SCENARIO_NAMES=""
export OSKERNEL_STRESS=""

export PATH="${OSKERNEL_ROOT}:${OSKERNEL_DIR_BINARIES}:${OSKERNEL_DIR_HELPER}:${PATH}"

# Utils General Variables
export UTILS_DIR=$OSKERNEL_ROOT/../../utils/
export UTILS_DIR_BIN=$UTILS_DIR/bin
export UTILS_DIR_HANDLERS=$UTILS_DIR/handlers
export UTILS_DIR_SCRIPTS=$UTILS_DIR/scripts

. $UTILS_DIR/configuration/general.configuration

export PATH="$PATH:$UTILS_DIR_BIN:$UTILS_DIR_HANDLERS:$UTILS_DIR_SCRIPTS"

# OSKernel General Variables
export OSKERNEL_PROCFS_CPUINFO=/proc/cpuinfo

# Remove all existing references for handlerError.sh
handlerError.sh "clean"

# End of file
