#!/bin/bash
#
# wifi_kernel_flasher.sh
# For use with adb wireless.
#
#	Usage:
#		Change the IP variable below to match the IP given in adb wireless.
#		Run the script.
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#define variables
IP='192.168.1.187'

#define paths
SRC=`pwd`/Kernel/arch/arm/boot/zImage
DEST=/data/local/tmp/zImage

#define cmds
ADB_KILL='adb kill-server'
ADB_CONNECT='adb connect'
ADB_DISCONNECT='adb disconnect'
ADB_SHELL='adb shell'
ADB_PUSH='adb push'
ADB_STATE='adb get-state'

#error
ERROR='no'

#redbend_ua cmd line usage
REDBEND="redbend_ua restore $DEST /dev/block/bml7"

#kill adb, start, and connect to wireless
echo -e 'Killing adb server.'
$ADB_KILL
echo -e "Connect to $IP."
$ADB_CONNECT $IP

# check for device (taken from the OneClickRoot)
CURSTATE=$($ADB_STATE | tr -d '\r\n[:blank:]')
while [ "$CURSTATE" != device ]; do
	CURSTATE=$($ADB_STATE | tr -d '\r\n[:blank:]')
	echo -e 'Phone is not connected.'
	CURSTATE='device'
	ERROR='yes'
done

if [ "$ERROR" != yes ]; then
	#remove previous kernel and push new one to phone
	echo -e "Removing previous zImage from $DEST."
	$ADB_SHELL 'rm' $DEST
	echo -e 'Pushing file, this may take a minute.'
	$ADB_PUSH $SRC $DEST

	#kick you to the adb shell
	echo -e 'Kicking you to the adb shell.'
	echo -e "usage: \n su\n $REDBEND"
	$ADB_SHELL

	#cleanup adb wireless by disconnecting
	echo -e "Disconnect from $IP."
	$ADB_DISCONNECT $IP
else
	echo -e "Please enable wireless adb and verify the IP matches: $IP."
fi
