#!/bin/sh

# =============================================================================
# Variables
# =============================================================================

LOCAL_COMMAND=$1

# =============================================================================
# Functions
# =============================================================================

# None

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

LOCAL_SYSFS_ENTRY_NAME=$2
test -f $LOCAL_SYSFS_ENTRY_NAME
if [ $? != 0 ]; then
	handlerError.sh "log" "1" "halt" "handlerSysFs.sh"
	exit 1
fi

if [ "$LOCAL_COMMAND" = "set" ]; then

	LOCAL_SYSFS_ENTRY_VALUE=$3

	echo $LOCAL_SYSFS_ENTRY_NAME > $HSF_SYSFS_ENTRY_NAME
	echo $LOCAL_SYSFS_ENTRY_VALUE > $LOCAL_SYSFS_ENTRY_NAME

elif [ "$LOCAL_COMMAND" = "get" ]; then

	cat $LOCAL_SYSFS_ENTRY_NAME

elif [ "$LOCAL_COMMAND" = "compare" ] || [ "$LOCAL_COMMAND" = "verify" ]; then

	LOCAL_SYSFS_ENTRY_VALUE=$3

	LOCAL_SYSFS_ENTRY_CURRENT=`cat $LOCAL_SYSFS_ENTRY_NAME`

	echo "[ handlerSysFs ] Desired Value: $LOCAL_SYSFS_ENTRY_VALUE" \
				"| Current Value: $LOCAL_SYSFS_ENTRY_CURRENT"

	if [ "$LOCAL_SYSFS_ENTRY_VALUE" = "$LOCAL_SYSFS_ENTRY_CURRENT" ]; then
		echo "[ handlerSysFs ] PASS: comparison succeeded"
		exit 0
	else
		echo "[ handlerSysFs ] FAIL: comparison failed" 1>&2
		if [ "$LOCAL_COMMAND" = "compare" ]; then
			handlerError.sh "log" "1" "halt" "handlerSysFs.sh"
		fi
		exit 1
	fi

fi

# End of file
