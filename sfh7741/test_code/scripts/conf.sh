#!/bin/sh

# TestSuite General Variables
export SENSOR_POSTFIX=`date "+%Y%m%d-%H%M%S"`
export SENSOR_ROOT=`pwd`

export SENSOR_DIR_BINARIES=${SENSOR_ROOT}/../bin
export SENSOR_DIR_HELPER=${SENSOR_ROOT}/helper
export SENSOR_DIR_TMP=${SENSOR_ROOT}/tmp
export SENSOR_DIR_TEST=${SENSOR_ROOT}/test
export SENSOR_DIR_SCENARIOS="${SENSOR_ROOT}/scenarios"

export SENSOR_FILE_OUTPUT=${SENSOR_ROOT}/output.$SENSOR_POSTFIX
export SENSOR_FILE_LOG=${SENSOR_ROOT}/log.$SENSOR_POSTFIX
export SENSOR_FILE_TMP=${SENSOR_DIR_TMP}/tmp.$SENSOR_POSTFIX
export SENSOR_FILE_CMD=cmd.$SENSOR_POSTFIX

export SENSOR_DURATION=""
export SENSOR_PRETTY_PRT=""
export SENSOR_VERBOSE=""
export SENSOR_SCENARIO_NAMES=""
export SENSOR_STRESS=""

export PATH="${PATH}:${SENSOR_ROOT}:${SENSOR_DIR_BINARIES}:${SENSOR_DIR_HELPER}"

# Utils General Variables
export UTILS_DIR=$SENSOR_ROOT/../../utils/
export UTILS_DIR_BIN=$UTILS_DIR/bin
export UTILS_DIR_HANDLERS=$UTILS_DIR/handlers
export UTILS_DIR_SCRIPTS=$UTILS_DIR/scripts

. $UTILS_DIR/configuration/general.configuration

export PATH="$PATH:$UTILS_DIR_BIN:$UTILS_DIR_HANDLERS:$UTILS_DIR_SCRIPTS"

# General variables
export DMESG_FILE=/var/log/dmesg
export DIGITAL_COMPASS_SYSFS=/sys/devices/platform/i2c_omap.4/i2c-4/4-001e/device0
export DIGITAL_COMPASS_OM=$DIGITAL_COMPASS_SYSFS/operating_mode
export DIGITAL_COMPASS_X_AXIS=$DIGITAL_COMPASS_SYSFS/magn_x_raw
export DIGITAL_COMPASS_Y_AXIS=$DIGITAL_COMPASS_SYSFS/magn_y_raw
export DIGITAL_COMPASS_Z_AXIS=$DIGITAL_COMPASS_SYSFS/magn_z_raw
export DIGITAL_COMPASS_ALL_AXIS=$DIGITAL_COMPASS_SYSFS/magn_*_raw
export DIGITAL_COMPASS_SINGLE_MODE=1
export DIGITAL_COMPASS_MULTI_MODE=0

# Sensor devfs node
TEMP_EVENT=`ls /sys/class/input/ | grep event`
set $TEMP_EVENT

for i in $TEMP_EVENT
do
	cat /sys/class/input/$i/device/name | grep "sfh7741"
	IS_THIS_OUR_DRIVER=`echo $?`
	if [ "$IS_THIS_OUR_DRIVER" -eq "0" ]
	then
		export DEVFS_SENSOR=/dev/input/$i
		echo "Proximity node is " $DEVFS_SENSOR
	fi
done

# Hardcode primary controller for now
#export DEVFS_SENSOR=/dev/input/event3
export DEVFS_TEMP=/sys/class/hwmon/hwmon0/device/temp1_input
export DEVFS_BMP085_TEMP=/sys/class/i2c-adapter/i2c-4/4-0077/temp0_input
export DEVFS_BMP085_PRESS=/sys/class/i2c-adapter/i2c-4/4-0077/pressure0_input
if [ ! -e "$DEVFS_SENSOR" ]
then
	echo "FATAL: Proximity node cannot be found -> $DEVFS_SENSOR"
fi

# End of file
