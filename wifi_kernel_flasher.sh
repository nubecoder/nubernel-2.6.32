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
IP="192.168.1.187"

#define paths
ZIMAGE_SRC="$PWD/Kernel/arch/arm/boot/zImage"
ZIMAGE_DEST="/data/local/tmp/zImage"

REDBEND_SRC="$PWD/initramfs/sbin/bmlwrite"
REDBEND_DEST="/data/local/tmp/bmlwrite"

BMLWRITE_SRC="$PWD/initramfs/sbin/bmlwrite"
BMLWRITE_DEST="/data/local/tmp/bmlwrite"

DST_PATH="/data/local/tmp/"

#define cmds
ADB_KILL="adb kill-server"
ADB_CONNECT="adb connect"
ADB_DISCONNECT="adb disconnect"
ADB_SHELL="adb shell"
ADB_PUSH="adb push"
ADB_STATE="adb get-state"

#error
ERROR="no"

#redbend_ua cmd line usage
REDBEND_CMD="redbend_ua restore zImage /dev/block/bml7"
BMLWRITE_CMD="bmlwrite zImage /dev/block/bml7"

#kill adb, start, and connect to wireless
echo "Killing adb server."
$ADB_KILL
echo "Connect to $IP."
$ADB_CONNECT $IP > /dev/null

# check for device (taken from the OneClickRoot: http://forum.xda-developers.com/showthread.php?t=897612)
CURSTATE=$($ADB_STATE | tr -d '\r\n[:blank:]')
while [ "$CURSTATE" != device ];
do
	CURSTATE=$($ADB_STATE | tr -d '\r\n[:blank:]')
	echo "Phone is not connected."
	CURSTATE="device"
	ERROR="yes"
done

if [ "$ERROR" != "yes" ];
then
	#remove previous kernel and push new one to phone
	echo "Removing previous zImage from $ZIMAGE_DEST."
	$ADB_SHELL "rm" $ZIMAGE_DEST
	echo "Pushing zImage, this may take a minute."
	$ADB_PUSH $ZIMAGE_SRC $ZIMAGE_DEST

	#push redbend_ua to phone	and set permissions
	echo "Pushing redbend_ua, this may take a minute."
	$ADB_PUSH $REDBEND_SRC $REDBEND_DEST
	echo "Setting permissions on redbend_ua (0755)."
	$ADB_SHELL "chmod 0755" $REDBEND_DEST

	#push bmlwrite to phone	and set permissions
	echo "Pushing bmlwrite, this may take a minute."
	$ADB_PUSH $BMLWRITE_SRC $BMLWRITE_DEST
	echo "Setting permissions on bmlwrite (0755)."
	$ADB_SHELL "chmod 0755" $BMLWRITE_DEST

	#kick you to the adb shell
	echo "Kicking you to the adb shell."
	echo -e "usage: \n cd $DST_PATH \n su \n $BMLWRITE_CMD \n or \n $REDBEND_CMD"
	$ADB_SHELL

	#cleanup adb wireless by disconnecting
	echo "Disconnect from $IP."
	$ADB_DISCONNECT $IP
else
	echo "Please enable wireless adb and verify the IP matches: $IP."
fi
