#!/bin/sh

# =============================================================================
# Variables
# =============================================================================
LOCAL_DRIVER=$1

if [ "$LOCAL_DRIVER" = "musb" ]; then
	echo "USB Suspend/Resume test USB1"	
	for i in /sys/bus/usb/devices/usb1/1-1/1-1.*; do
		echo " path of USB device $i"
		USB_PORTNO=`ls $i | grep :`
		echo " usb port no $USB_PORTNO"
		echo " usb path $i/$USB_PORTNO/"
		dmesg -c
		echo "Unbind the device"		
		echo $USB_PORTNO > $i/$USB_PORTNO/driver/unbind && sleep 10
		cat /proc/bus/usb/devices
		echo "USB Suspend"
		dmesg -c		
		echo auto > $i/power/control
		cat $i/power/control
		dmesg | grep auto-suspend && sleep 5
		dmesg -c
		echo "USB Resume"
		echo on > $i/power/control
		dmesg | grep auto-resume
	done
fi

if [ "$LOCAL_DRIVER" = "ehci" ]; then
	dmesg -c
	echo "USB Suspend/Resume test USB2"
	USB_NO=`grep -s Lev=01 /proc/bus/usb/devices | grep -s Bus=02`
	echo " USB no $USB_NO"
	USB_BUS=2
	if ["$USB_NO" = ""]; then
		USB_BUS=3
	fi
	echo " USB Bus $USB_BUS"	
	for i in /sys/bus/usb/devices/usb$USB_BUS/$USB_BUS-1/$USB_BUS-1.*; do
		echo " path of USB device $i"
		USB_PORTNO=`ls $i | grep :`
		echo " usb port no $USB_PORTNO"
		echo " usb path $i/$USB_PORTNO/"
		dmesg -c
		echo "Unbind the device"		
		echo $USB_PORTNO > $i/$USB_PORTNO/driver/unbind && sleep 10
		cat /proc/bus/usb/devices
		echo "USB Suspend"
		dmesg -c		
		echo auto > $i/power/control
		cat $i/power/control
		dmesg | grep auto-suspend && sleep 5
		dmesg -c
		echo "USB Resume"
		echo on > $i/power/control
		dmesg | grep auto-resume
	done
fi


if [ "$LOCAL_DRIVER" = "ohci" ]; then
	echo "USB Suspend/Resume test USB3"	
	USB_NO=`grep -s Lev=01 /proc/bus/usb/devices | grep -s Bus=02`
	echo " USB no $USB_NO"
	USB_BUS=2
	if ["$USB_NO" = ""]; then
		USB_BUS=3
	fi
	echo " USB Bus $USB_BUS"	
	for i in /sys/bus/usb/devices/usb$USB_BUS/$USB_BUS-2/$USB_BUS-2.*; do
		echo " path of USB device $i"
		USB_PORTNO=`ls $i | grep :`
		echo " usb port no $USB_PORTNO"
		echo " usb path $i/$USB_PORTNO/"
		dmesg -c
		echo "Unbind the device"		
		echo $USB_PORTNO > $i/$USB_PORTNO/driver/unbind && sleep 10
		cat /proc/bus/usb/devices
		echo "USB Suspend"
		dmesg -c		
		echo auto > $i/power/control
		cat $i/power/control
		dmesg | grep auto-suspend && sleep 5
		dmesg -c
		echo "USB Resume"
		echo on > $i/power/control
		dmesg | grep auto-resume
	done
fi





	
