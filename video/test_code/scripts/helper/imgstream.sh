#!/bin/sh

VIDEO_PIPELINE=$1
SETIMG_PARAMETERS=$2
STREAMING_PARAMETERS=$3
SETCROP_PARAMETERS=$4
SETWIN_PARAMETERS=$5
TIME_PARAMETER=$6
PIXFORMAT_PARAM=$7

RESULT=0

# Usage: setimg <vid> <fmt> <width> <height>
$TESTBIN/setimg $VIDEO_PIPELINE $SETIMG_PARAMETERS $PIXFORMAT_PARAM

if [ ! -z "$SETCROP_PARAMETERS" ]; then
	# Usage: setcrop <vid> <left> <top> <width> <height>
	$TESTBIN/setcrop $VIDEO_PIPELINE $SETCROP_PARAMETERS
	RESULT=`command_tracking.sh $RESULT $?`
fi

if [ ! -z "$SETWIN_PARAMETERS" ]; then
	# Usage: setwin <vid> <left> <top> <width> <height>
	$TESTBIN/setwin $VIDEO_PIPELINE $SETWIN_PARAMETERS $PIXFORMAT_PARAM
	RESULT=`command_tracking.sh $RESULT $?`
fi


# Usage: streaming <vid> <inputfile> [<n>]
if [ ! -z "$TIME_PARAMETER" ]; then
	$TESTBIN/streaming $VIDEO_PIPELINE $STREAMING_PARAMETERS $TIME_PARAMETER
	RESULT=`command_tracking.sh $RESULT $?`
else
        $TESTBIN/streaming $VIDEO_PIPELINE $STREAMING_PARAMETERS 0
        RESULT=`command_tracking.sh $RESULT $?`
fi

if [ -z "$STRESS" ]; then
	stress_message.sh
fi

exit $RESULT
