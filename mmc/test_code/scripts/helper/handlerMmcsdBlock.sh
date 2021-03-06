#!/bin/sh

# =============================================================================
# Variables
# =============================================================================

LOCAL_OPERATION=$1
LOCAL_PARTITIONS=$2

# =============================================================================
# Functions
# =============================================================================

fstabModifier() {

	LOCAL_MMCSD_PARTITION_NUMBER=$1
	LOCAL_MMCSD_FILESYSTEM_TYPE=$2
	LOCAL_MMCSD_DEVFS_PARTITION=$3
	LOCAL_MMCSD_MOUNTPOINT=$4

	handlerFstab.sh "add" "$LOCAL_MMCSD_PARTITION_NUMBER" "${LOCAL_MMCSD_DEVFS_PARTITION} ${LOCAL_MMCSD_MOUNTPOINT} $LOCAL_MMCSD_FILESYSTEM_TYPE defaults 0 0"
}

xMountFunction() {

	LOCAL_MMCSD_PARTITION_NUMBER=$1
	LOCAL_MMCSD_FILESYSTEM_TYPE=$2
	LOCAL_MMCSD_DEVFS_PARTITION=$3
	LOCAL_MMCSD_MOUNTPOINT=$4

	# Required for POKY as it AUTO MOUNTS ONCE
	# PARTITON GETS CREATED
	mount | grep $LOCAL_MMCSD_DEVFS_PARTITION && umount $LOCAL_MMCSD_DEVFS_PARTITION

	mount -t $LOCAL_MMCSD_FILESYSTEM_TYPE $LOCAL_MMCSD_DEVFS_PARTITION $LOCAL_MMCSD_MOUNTPOINT
	if [ "$?" -ne "0" ]; then
		echo "FATAL: Unknown $LOCAL_MMCSD_FILESYSTEM_TYPE filesystem type"
		handlerError.sh "log" "1" "halt" "handlerMmmcsdBlock"
		exit 1
	fi

	handlerError.sh "log" "$?" "halt" "handlerMmmcsdBlock"
	# Ubuntu has an issue were if any scenario forced to quit will make the ubuntu not boot as fstan entry is present
	# fstabModifier $LOCAL_MMCSD_PARTITION_NUMBER $LOCAL_MMCSD_FILESYSTEM_TYPE $LOCAL_MMCSD_DEVFS_PARTITION $LOCAL_MMCSD_MOUNTPOINT

}

partitionFormatHelper() {

	LOCAL_FORMAT_APPLICATION=$1
	LOCAL_MMCSD_MOUNTPOINT_1=$2
	LOCAL_MMCSD_MOUNTPOINT_2=$3

	eval $LOCAL_FORMAT_APPLICATION
	if [ "$?" -eq "127" ]; then
		echo "FATAL: application $LOCAL_FORMAT_APPLICATION is not available un current filesystem"
		handlerError.sh "log" "1" "halt" "handlerMmmcsdBlock"
		exit 1
	fi

	if [ ! -z $2 ] ; then

		$LOCAL_FORMAT_APPLICATION $MMCSD_DEVFS_PARTITION_1
		xMountFunction "1" $LOCAL_FILESYSTEM_TYPE $MMCSD_DEVFS_PARTITION_1 $LOCAL_MMCSD_MOUNTPOINT_1
			
	fi


	if [ ! -z $3 ] ; then

		$LOCAL_FORMAT_APPLICATION $MMCSD_DEVFS_PARTITION_2
		xMountFunction "2" $LOCAL_FILESYSTEM_TYPE $MMCSD_DEVFS_PARTITION_2 $LOCAL_MMCSD_MOUNTPOINT_2
			
	fi

}

# =============================================================================
# Main
# =============================================================================

if [ "$LOCAL_OPERATION" = "create" ]; then

	LOCAL_FILESYSTEM_TYPE=$3

	if [ "$LOCAL_FILESYSTEM_TYPE" = "" ]; then
		handlerError.sh "log" "1" "halt" "handlerMmmcsdBlock"
		exit 1
	fi

	if [ ! -z $4 ] ; then
		MMCSD_MOUNTPOINT_1=$4
		echo "$MMCSD_MOUNTPOINT_1" > $MMCSD_MOUNTPOINT_1_LOG
		MMCSD_MOUNTPOINT_2=$5
		echo "$MMCSD_MOUNTPOINT_2" > $MMCSD_MOUNTPOINT_2_LOG
	fi

	handlerFstab.sh "save"

	handlerMmcsdSetup.sh "create" $LOCAL_PARTITIONS

	if [ "$LOCAL_PARTITIONS" = "1" ]; then

		mount | grep $MMCSD_DEVFS_PARTITION_1 && umount $MMCSD_DEVFS_PARTITION_1

		test -d $MMCSD_MOUNTPOINT_1 || mkdir -p $MMCSD_MOUNTPOINT_1

		if [ "$LOCAL_FILESYSTEM_TYPE" = "ext2" ]; then

			partitionFormatHelper $MMCSD_DIR_BINARIES/mke2fs $MMCSD_MOUNTPOINT_1

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "ext3" ]; then

			partitionFormatHelper mkfs.ext3 $MMCSD_MOUNTPOINT_1

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "ext4" ]; then

			partitionFormatHelper mkfs.ext4 $MMCSD_MOUNTPOINT_1

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "dos" ]; then

			export LOCAL_FILESYSTEM_TYPE=msdos
			partitionFormatHelper $MMCSD_DIR_BINARIES/mkdosfs $MMCSD_MOUNTPOINT_1

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "vfat" ]; then

			partitionFormatHelper mkfs.vfat $MMCSD_MOUNTPOINT_1

		fi


	elif [ "$LOCAL_PARTITIONS" = "2" ]; then


		mount | grep $MMCSD_DEVFS_PARTITION_1 && umount $MMCSD_DEVFS_PARTITION_1
		mount | grep $MMCSD_DEVFS_PARTITION_2 && umount $MMCSD_DEVFS_PARTITION_2

		test -d $MMCSD_MOUNTPOINT_1 || mkdir -p $MMCSD_MOUNTPOINT_1
		test -d $MMCSD_MOUNTPOINT_2 || mkdir -p $MMCSD_MOUNTPOINT_2

		if [ "$LOCAL_FILESYSTEM_TYPE" = "ext2" ]; then

			partitionFormatHelper mkfs.ext2 $MMCSD_MOUNTPOINT_1 $MMCSD_MOUNTPOINT_2

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "ext3" ]; then

			partitionFormatHelper mkfs.ext3 $MMCSD_MOUNTPOINT_1 $MMCSD_MOUNTPOINT_2

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "ext4" ]; then

			partitionFormatHelper mkfs.ext4 $MMCSD_MOUNTPOINT_1 $MMCSD_MOUNTPOINT_2

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "dos" ]; then

			export LOCAL_FILESYSTEM_TYPE=msdos
			partitionFormatHelper $MMCSD_DIR_BINARIES/mkdosfs $MMCSD_MOUNTPOINT_1 $MMCSD_MOUNTPOINT_2

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "vfat" ]; then

			partitionFormatHelper mkfs.vfat $MMCSD_MOUNTPOINT_1 $MMCSD_MOUNTPOINT_2

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "dos-ext2" ]; then

			export LOCAL_FILESYSTEM_TYPE=msdos
			partitionFormatHelper $MMCSD_DIR_BINARIES/mkdosfs $MMCSD_MOUNTPOINT_1
			export LOCAL_FILESYSTEM_TYPE=ext2
			partitionFormatHelper $MMCSD_DIR_BINARIES/mke2fs "" $MMCSD_MOUNTPOINT_2

		elif [ "$LOCAL_FILESYSTEM_TYPE" = "mixed" ]; then

			export LOCAL_FILESYSTEM_TYPE=ext2
			partitionFormatHelper $MMCSD_DIR_BINARIES/mke2fs $MMCSD_MOUNTPOINT_1
			export LOCAL_FILESYSTEM_TYPE=msdos
			partitionFormatHelper $MMCSD_DIR_BINARIES/mkdosfs "" $MMCSD_MOUNTPOINT_2

		fi

	fi

elif [ "$LOCAL_OPERATION" = "remove" ]; then

	if [ ! -z $4 ] ; then

		MMCSD_MOUNTPOINT_1=`cat $MMCSD_MOUNTPOINT_1_LOG`
		MMCSD_MOUNTPOINT_2=`cat $MMCSD_MOUNTPOINT_2_LOG`

	fi

	if [ "$LOCAL_PARTITIONS" = "1" ]; then

		sync && umount $MMCSD_MOUNTPOINT_1

	elif [ "$LOCAL_PARTITIONS" = "2" ]; then

		sync && umount $MMCSD_MOUNTPOINT_1
		sync && umount $MMCSD_MOUNTPOINT_2

	fi

	test -d $MMCSD_MOUNTPOINT_1 && rm -rf $MMCSD_MOUNTPOINT_1
	test -d $MMCSD_MOUNTPOINT_2 && rm -rf $MMCSD_MOUNTPOINT_2

	$MMCSD_DIR_HELPER/handlerMmcsdSetup.sh "remove" $LOCAL_PARTITIONS

	handlerFstab.sh "restore"


elif [ "$LOCAL_OPERATION" = "remount" ]; then
	LOCAL_FILESYSTEM_TYPE=$3

	if [ "$LOCAL_PARTITIONS" -ge "1" ]; then

		MNT_INFO=$(mount | awk -v mnt=$MMCSD_DEVFS_PARTITION_1 '{ if ($1 == mnt) print $3 }')
		if [ "$MNT_INFO" != "" ]; then
			umount $MNT_INFO
		fi

		test -d $MMCSD_MOUNTPOINT_1 || mkdir -p $MMCSD_MOUNTPOINT_1
		xMountFunction "1" $LOCAL_FILESYSTEM_TYPE $MMCSD_DEVFS_PARTITION_1 $MMCSD_MOUNTPOINT_1
		
		handlerError.sh "log" "$?" "halt" "handlerMmmcsdBlock"
	fi
	
	if [ "$LOCAL_PARTITIONS" = "2" ]; then
		MNT_INFO=$(mount | awk -v mnt=$MMCSD_DEVFS_PARTITION_2 '{ if ($1 == mnt) print $3 }')
		if [ "$MNT_INFO" != "" ]; then
			umount $MNT_INFO
		fi
		
		test -d $MMCSD_MOUNTPOINT_2 || mkdir -p $MMCSD_MOUNTPOINT_2
		xMountFunction "1" $LOCAL_FILESYSTEM_TYPE $MMCSD_DEVFS_PARTITION_2 $MMCSD_MOUNTPOINT_2

	fi

elif [ "$LOCAL_OPERATION" = "fs-test" ]; then

	if [ "$LOCAL_PARTITIONS" = "2" ]; then
		export MMCSD_MOUNTPOINT_1=$MMCSD_MOUNTPOINT_2
	fi
	
	handlerTmpfs.sh "create" "250" $MMCSD_TMPFS_MOUNTPOINT

	handlerCmd.sh "run" "dd if=/dev/urandom of=$MMCSD_TMPFS_MOUNTPOINT/1k.txt bs=1024 count=1"
	handlerCmd.sh "run" "dd if=/dev/urandom of=$MMCSD_TMPFS_MOUNTPOINT/50k.txt bs=1024 count=50"
	handlerCmd.sh "run" "dd if=/dev/urandom of=$MMCSD_TMPFS_MOUNTPOINT/75k.txt bs=1024 count=75"
	handlerCmd.sh "run" "dd if=/dev/urandom of=$MMCSD_TMPFS_MOUNTPOINT/99k.txt bs=1024 count=99"
	handlerCmd.sh "run" "dd if=/dev/urandom of=$MMCSD_TMPFS_MOUNTPOINT/2k.txt bs=1024 count=2"

	handlerCmd.sh "run" "cp $MMCSD_TMPFS_MOUNTPOINT/1k.txt $MMCSD_MOUNTPOINT_1"
	handlerCmd.sh "run" "cp $MMCSD_TMPFS_MOUNTPOINT/50k.txt $MMCSD_MOUNTPOINT_1"
	handlerCmd.sh "run" "cp $MMCSD_TMPFS_MOUNTPOINT/75k.txt $MMCSD_MOUNTPOINT_1"
	handlerCmd.sh "run" "cp $MMCSD_TMPFS_MOUNTPOINT/99k.txt $MMCSD_MOUNTPOINT_1"
	handlerCmd.sh "run" "cp $MMCSD_TMPFS_MOUNTPOINT/2k.txt $MMCSD_MOUNTPOINT_1"

	sync

	handlerCmd.sh "run" "cmp $MMCSD_TMPFS_MOUNTPOINT/1k.txt $MMCSD_MOUNTPOINT_1/1k.txt"
	handlerCmd.sh "run" "cmp $MMCSD_TMPFS_MOUNTPOINT/50k.txt $MMCSD_MOUNTPOINT_1/50k.txt"
	handlerCmd.sh "run" "cmp $MMCSD_TMPFS_MOUNTPOINT/75k.txt $MMCSD_MOUNTPOINT_1/75k.txt"
	handlerCmd.sh "run" "cmp $MMCSD_TMPFS_MOUNTPOINT/99k.txt $MMCSD_MOUNTPOINT_1/99k.txt"
	handlerCmd.sh "run" "cmp $MMCSD_TMPFS_MOUNTPOINT/2k.txt $MMCSD_MOUNTPOINT_1/2k.txt"

	handlerTmpfs.sh "remove" $MMCSD_TMPFS_MOUNTPOINT
	
elif [ "$LOCAL_OPERATION" = "mmc_test" ]; then

	#assume mmc card present and mmc_test note present 
	mmc_node=`ls /sys/bus/mmc/drivers/mmcblk | grep mmc$SLOT`
	if [ $mmc_node ]; then		
		echo $mmc_node > /sys/bus/mmc/drivers/mmcblk/unbind
		echo $mmc_node > /sys/bus/mmc/drivers/mmc_test/bind
	fi

	mmc_node=`ls /sys/bus/mmc/drivers/mmc_test | grep mmc$SLOT*`
	if  [ $mmc_node = "" ]; then
		exit 1
	fi
	
	mmc_node=/sys/bus/mmc/drivers/mmc_test/$mmc_node
	if [ -e $mmc_node/test ]; then
		#testcase 11 to 14 : dma unalligned buffer not supported by OMAP
		#testcase 19 to 22 : only for highmem test
		for i in 1 2 3 4 5 6 7 8 9 10 15 16 17 18
		do
			echo $i > $mmc_node/test
		done

		#highmem test only
		if [ "$2" = "highmem" ]; then
			for i in 19 20 21 22
			do
				echo $i > $mmc_node/test
			done
		fi
	fi

elif [ "$LOCAL_OPERATION" = "throughput" ]; then
	
	#usage: handlerMmcsdBlock.sh "throughput" "write" "sync"
	TOTAL=1000

	if [ ! -z $3 ] ; then
		#3rd parameter is not appicable for raw mode
		if [ $3 = "sync" ]; then
			handlerCmd.sh "run" "umount $MMCSD_MOUNTPOINT_1"
			handlerCmd.sh "run" "mount -o sync $MMCSD_DEVFS_PARTITION_1 $MMCSD_MOUNTPOINT_1"
		elif [ $3 = "async" ]; then
			handlerCmd.sh "run" "umount $MMCSD_MOUNTPOINT_1"
			handlerCmd.sh "run" "mount -o async $MMCSD_DEVFS_PARTITION_1 $MMCSD_MOUNTPOINT_1"
		fi
	fi

	#$(date +%S%N) - and you will get nanoseconds precision
	START=$(date +%s)
	if [ $2 = "write" ]; then
		handlerCmd.sh "run" "dd if=/dev/zero of=$MMCSD_MOUNTPOINT_1/$MMCSD_FILE_SIZE_BIG bs=1M count=$TOTAL && sync"
	elif [ $2 = "read" ]; then
		handlerCmd.sh "run" "dd if=$MMCSD_MOUNTPOINT_1/$MMCSD_FILE_SIZE_BIG of=/dev/null bs=1M count=$TOTAL && sync"
	elif [ $2 = "raw-write" ]; then
		handlerCmd.sh "run" "dd if=/dev/zero of=$MMCSD_DEVFS_ENTRY bs=1M count=$TOTAL && sync"
	elif [ $2 = "raw-read" ]; then
		handlerCmd.sh "run" "dd if=$MMCSD_DEVFS_ENTRY of=/dev/null bs=1M count=$TOTAL && sync"
	fi
	END=$(date +%s)
	DIFF=$(( $END - $START ))

	MNT_INFO=$(mount | awk -v mnt=$MMCSD_DEVFS_PARTITION_1 '{ if ($1 == mnt) print $5 }')
	echo Result:$1: $MNT_INFO: $3 : $2 $TOTAL-MBytes in $DIFF seconds : `echo "scale=4; $TOTAL / $DIFF" | bc` MBps

elif [ "$LOCAL_OPERATION" = "check-card-version" ]; then
	#for loop required to support multiple catd in a slot
	for file in $(find /sys/class/mmc_host/mmc$SLOT -type f -name csd); do
		#echo $file
		csd=`cat $file`
		echo CSD=$csd
		csd=`echo $csd | tr '[a-z]' '[A-Z]' `
		#csd in MSB format sting
		csd=`echo $csd | cut -c0`
		csd=`expr $csd`
		csd=`echo "obase=2; $csd" | bc`
		len=`expr length $csd`
		if ($length > 2) ; then
			len=`expr 4 - $len`
			len=`expr 2 - $len`
			csd=`expr substr $csd 1 $len` 
			csd=`echo "ibase=2;obase=A;$csd" | bc`
		else
			csd=0
		fi

		for file in $(find /sys/class/mmc_host/mmc$SLOT -type f -name type); do
			#echo $file
			card=`cat $file`
			if [ $card == "MMC" ] ; then
			case $csd in
			 "0") echo "MMC : Version 1.0-1.2" ;;
			 "1") echo "MMC : Version 1.4 - 2.2" ;;
			 "2") echo "MMC : Version 3.1 - 3.2 - 3.31 - 4.0 - 4.1 - 4.2 - 4.3" ;;
			 "3") echo "MMC : Version 4.4" ;;
			 *)  echo "MMC: Wrong MMC card" ;; 
			esac

			else

			case $csd in
			 "0") echo "SD : Specification Ver 1.01-1.10 OR Ver 2.00/Standard Capacity" ;;
			 "1") echo "SD : Specification Ver 2.00/High Capacity" ;;
			 *)  echo "SD : Wrong SD card" ;; 
			esac
			fi

		done
	done
fi

# End of file
