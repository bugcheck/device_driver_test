#!/bin/sh

NAME=$1
TAG=$2
PLACE=$3
COMMAND=$4
VARIABLE=$5
COMMAND2=$6
VARIABLE2=$7
COMMAND3=$8
VARIABLE3=$9
status=0

print()
{
  msg=$1
  echo $msg
}

print ""
print "----------------------- Test Case Scenario $NAME -----------------------"

for i in $McBSP_INTERFACES
do

  print ""
  print "----- McBSP Interface $i"
  print "----- Parameter \"$TAG\""
  print "----- Available values .: $VARIABLE :."

  for j in $VARIABLE
  do
	for k in $VARIABLE2
	do
		for l in $VARIABLE3
		do
			print ""
			print "Testing McBSP Interface $i with $COMMAND$j"
#			sleep $MESSAGE_DELAY
#			INSERTED=`lsmod | grep omap_mcbsp_test | cut -d ' ' -f1`
#			if [ $INSERTED == $MODNAME ]
#			then
#			print "Module was already inserted. Removing it..."
#			rmmod $MODNAME
#			fi
#			if [ "$COMMAND" == "" ]
#			then
#				insmod -f $McBSP_MODULE test_mcbsp_id=$i
#				TEMP=$j
#			else
#				insmod -f $McBSP_MODULE $COMMAND$j test_mcbsp_id=$i
#				TEMP=`cat /proc/driver/mcbsp_test/status | grep "$TAG" | sed -e "s/ */ /g" | cut -d ' ' -f$PLACE`
#			fi
			if [$COMMAND = ""]
			then
				j=""
			fi 
			insmod $McBSP_MODULE $COMMAND$j $COMMAND2$k $COMMAND3$l test_mcbsp_id=$i
			if [ "$?" = "1" ]
			then
				exit 1
			fi	
			TEMP=`cat /proc/driver/mcbsp_test/status | grep "$TAG" | awk '{print $6}'`
			TRANSFER=`cat /proc/driver/mcbsp_test/status | grep "Number of transfers" | awk '{print $5}'`
			print "Starting Transmission : \"echo start > /proc/driver/mcbsp_test/transmission\""
			sleep $MESSAGE_DELAY
			echo 'start' > /proc/driver/mcbsp_test/transmission
			sleep $DELAY
			TX=`cat /proc/driver/mcbsp_test/status | grep "No. of buffers transmitted" | awk '{print $6}'`
			RX=`cat /proc/driver/mcbsp_test/status | grep "No. of buffers received" | awk '{print $6}'`
			print "$TEMP $j $TX $RX $TRANSFER"
			if [ "$TEMP" -ne "$j" ] || [ "$TX" -ne "$TRANSFER" ] || [ "$RX" -ne "$TRANSFER" ]
			then
				print "Tx Value = $TX | $RX = Rx Value"
				print "Failed Tranmission on McBSP Interface $i using $COMMAND$j"
				print "FAIL"
				sleep $MESSAGE_DELAY
				rmmod $MODNAME
				status=1
			else
				print "Tx Value = $TX | $RX = Rx Value"
				print "Succesful Tranmission on McBSP Interface $i using $COMMAND$j"
				print "PASS"
				sleep $MESSAGE_DELAY
				rmmod $MODNAME
			fi
		done
	done
  done
done


if [ "$status" -eq 1 ] ; then
 exit 1
else
  exit 0
fi
