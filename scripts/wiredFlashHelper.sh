#!/bin/bash
#
# wiredFlashHelper.sh
#
# This script expects a connected device.
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#define paths
TMP_PATH="/data/local/tmp"
ZIMAGE_SRC="$PWD/../Kernel/arch/arm/boot/zImage"
ZIMAGE_DEST="$TMP_PATH/zImage"
REDBEND_SRC="$PWD/../initramfs/sbin/redbend_ua"
REDBEND_DEST="$TMP_PATH/redbend_ua"
KERNELFLASH_SRC="$PWD/kernelFlash"
KERNELFLASH_DEST="$TMP_PATH/kernelFlash"

#define cmds
ADB_KILL="adb kill-server"
ADB_SHELL="adb shell"
ADB_PUSH="adb push"
ADB_STATE="adb get-state"
ADB_KERNEL_FLASH="su -c '/data/local/tmp/kernelFlash -k'"

#error
ERROR="no"

echo
echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
echo "Begin."
echo "*"

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
	#remove previous files
	echo "Removing previous files."
	$ADB_SHELL "rm -f" $ZIMAGE_DEST
	$ADB_SHELL "rm -f" $REDBEND_DEST
	$ADB_SHELL "rm -f" $KERNELFLASH_DEST

	#push new kernel to phone
	echo "Pushing zImage, this may take a minute."
	$ADB_PUSH $ZIMAGE_SRC $ZIMAGE_DEST >/dev/null 2>&1
	#push redbend_ua to phone and set permissions
	echo "Pushing redbend_ua, this may take a minute."
	$ADB_PUSH $REDBEND_SRC $REDBEND_DEST >/dev/null 2>&1
	echo "Setting permissions on redbend_ua (0755)."
	$ADB_SHELL "chmod 0755" $REDBEND_DEST

	#push kernelFlash to phone and set permissions
	echo "Pushing kernelFlash, this may take a minute."
	$ADB_PUSH $KERNELFLASH_SRC $KERNELFLASH_DEST >/dev/null 2>&1
	echo "Setting permissions on kernelFlash (0755)."
	$ADB_SHELL "chmod 0755" $KERNELFLASH_DEST
	#flash kernel with kernelFlash script
	echo "Flashing kernel with kernelFlash -k."
	echo "*"
	$ADB_SHELL $ADB_KERNEL_FLASH
else
	echo "Please connect your phone."
fi

echo "*"
echo "End."
echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
echo

exit

