#!/bin/sh

# =============================================================================
# Variables
# =============================================================================

LOCAL_OPERATION=$1

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

handlerSysFs.sh "verify" $SYSFS_CPU_ONLINE  "0-1"
if [ $? -eq 0 ]; then
	LOCAL_MULTICORE=1
else
	echo -e "\n\nINFO: Only CPU 0 is online, will set up affinity automatically\n\n"
fi

if [ "$LOCAL_OPERATION" = "switch" ]; then

	LOCAL_COMMAND_LINE=$2
	LOCAL_COMMAND_REPEATABILITY=$3
	LOCAL_COMMAND_WAIT=$4

	$LOCAL_COMMAND_LINE &
	LOCAL_COMMAND_PID=`echo $!`

	count=1
	LOCAL_PROCESSOR=1

	while [ $count -le $LOCAL_COMMAND_REPEATABILITY ]
	do

		echo -e "\nInfo: PID $LOCAL_COMMAND_PID | Processor $LOCAL_PROCESSOR | Count $count of $LOCAL_COMMAND_REPEATABILITY"
		if [ ! -d "/proc/$LOCAL_COMMAND_PID" ]
		then
			break
		fi

		rem=$(( $count % 2 ))
		if [ $rem -eq 1 ]
		then
			if [ $LOCAL_MULTICORE ]; then
				LOCAL_PROCESSOR=2
			fi
		fi

		taskset -p $LOCAL_PROCESSOR $LOCAL_COMMAND_PID
		if [ $? -ne 0 ]
		then
			echo -e "Error: Could not set cpu affinity for processor $LOCAL_PROCESSOR!"
			exit 1
		fi

		count=`expr $count + 1`
		sleep $LOCAL_COMMAND_WAIT

	done

	echo -e "\nInfo: Command > $LOCAL_COMMAND_LINE\n"
	echo -e "Info: Waiting for it to finish..."

	wait

	echo -e "Info: Done!\n"

elif [ "$LOCAL_OPERATION" = "clean" ]; then

	test -f $HCA_LIST_CMDS_TOTALS && rm $HCA_LIST_CMDS_TOTALS
	test -f $HCA_LIST_CMDS_PASSED && rm $HCA_LIST_CMDS_PASSED
	test -f $HCA_LIST_PIDS_TOTALS && rm $HCA_LIST_PIDS_TOTALS

	touch $HCA_LIST_CMDS_TOTALS
	touch $HCA_LIST_CMDS_PASSED
	touch $HCA_LIST_PIDS_TOTALS

	touch $HCA_LIST_CMDS_FAILED
	test -f $HCA_LIST_CMDS_FAILED && rm $HCA_LIST_CMDS_FAILED

elif [ "$LOCAL_OPERATION" = "assign" ]; then

	LOCAL_COMMAND_LINE=$2
	LOCAL_COMMAND_PROCESSOR_MASK=$3

	if [ $LOCAL_MULTICORE ]; then
		echo "$LOCAL_COMMAND_LINE:$LOCAL_COMMAND_PROCESSOR_MASK" >> $HCA_LIST_CMDS_TOTALS
	else
		echo "$LOCAL_COMMAND_LINE:1" >> $HCA_LIST_CMDS_TOTALS
	fi

elif [ "$LOCAL_OPERATION" = "random" ]; then

	LOCAL_COMMAND_LINE=$2
	LOCAL_COMMAND_PROCESSOR=0

	if [ $LOCAL_MULTICORE ]; then
		while [  $LOCAL_COMMAND_PROCESSOR -eq 0 ]; do
			LOCAL_NUMBER=`dd if=/dev/urandom count=1 2> /dev/null | cksum | cut -f1 -d" "`
			LOCAL_COMMAND_PROCESSOR=`echo "$LOCAL_NUMBER%4" | bc`
		done
	else
		LOCAL_COMMAND_PROCESSOR=1
	fi

	echo "$LOCAL_COMMAND_LINE:$LOCAL_COMMAND_PROCESSOR" >> $HCA_LIST_CMDS_TOTALS

elif [ "$LOCAL_OPERATION" = "execute" ]; then

	LOCAL_WITH_RANDOM_DELAY=$2

	LOCAL_INSTANCE=0
	while read LOCAL_LINE
	do

		LOCAL_COMMAND_INSTANCE=`expr $LOCAL_INSTANCE + 1`
		LOCAL_COMMAND_LINE=`echo $LOCAL_LINE | cut -d: -f1`
		LOCAL_COMMAND_PROCESSOR=`echo $LOCAL_LINE | cut -d: -f2`
		LOCAL_COMMAND_DELAY="0"

		if [ "$LOCAL_WITH_RANDOM_DELAY" = "withrandomdelay" ]
		then

			LOCAL_COMMAND_DELAY_TEMP=`dd if=/dev/urandom count=1 2> /dev/null | cksum | cut -f1 -d" "`
			LOCAL_COMMAND_DELAY=`echo "$LOCAL_COMMAND_DELAY_TEMP%5" | bc`

		fi

		handlerCpuAffinityExecutor.sh "$LOCAL_COMMAND_INSTANCE" "$LOCAL_COMMAND_LINE" "$LOCAL_COMMAND_PROCESSOR" "$LOCAL_COMMAND_DELAY" &

	done < $HCA_LIST_CMDS_TOTALS

	wait

	echo -e "\nInfo: Passed! > Instance | PID | Command\n"
	cat $HCA_LIST_CMDS_PASSED
	echo

	if [ -f $HCA_LIST_CMDS_FAILED ]
	then
		echo -e "\nInfo: Failed! > Instance | PID | Command\n"
		cat $HCA_LIST_CMDS_FAILED
		echo
		exit 1
	fi
fi

# End of file
