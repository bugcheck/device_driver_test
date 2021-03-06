#!/bin/sh

VIDEO_PIPELINE=$1
SETIMG_PARAMETERS=$2
STREAMING_PARAMETERS=$3
SETCROP_PARAMETERS=$4
SETWIN_PARAMETERS=$5
LOOP_COUNT=$6

RESULT=0

# Usage: setimg <vid> <fmt> <width> <height>
$TESTBIN/setimg $VIDEO_PIPELINE $SETIMG_PARAMETERS

if [ ! -z "$SETCROP_PARAMETERS" ]; then
	# Usage: setcrop <vid> <left> <top> <width> <height>
	$TESTBIN/setcrop $VIDEO_PIPELINE $SETCROP_PARAMETERS
	RESULT=`command_tracking.sh $RESULT $?`
fi

if [ ! -z "$SETWIN_PARAMETERS" ]; then
	# Usage: setwin <vid> <left> <top> <width> <height>
	$TESTBIN/setwin $VIDEO_PIPELINE $SETWIN_PARAMETERS
	RESULT=`command_tracking.sh $RESULT $?`
fi

# Usage: streaming_repeat <video_device> <inputfile> [<n_sleep>]
#		[<n_bufcount>] [<loop_count>]

$TESTBIN/streaming_repeat $VIDEO_PIPELINE $STREAMING_PARAMETERS 0 2 $LOOP_COUNT
RESULT=`command_tracking.sh $RESULT $?`

if [ -z "$STRESS" ]; then
	stress_message.sh
fi

exit $RESULT
