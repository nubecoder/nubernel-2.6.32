#!/bin/bash
#define variables
IP="192.168.1.168"

#define paths
LOG_PATH="kmsg.log"

#define cmds
ADB_KILL="adb kill-server"
ADB_CONNECT="adb connect"
ADB_DISCONNECT="adb disconnect"
ADB_SHELL="adb shell"
ADB_STATE="adb get-state"

if [ -n "$1" ]; then
	if [ "$1" == "-d" ]; then
		rm $LOG_PATH
		exit
	else
		if [ "$1" == "-o" ]; then
			gedit $LOG_PATH
			exit
		else
			ADB_KMSG="su -c 'cat /proc/kmsg | grep "$1"'"
		fi
	fi
else
	ADB_KMSG="su -c 'cat /proc/kmsg'"
fi

#error
ERROR="no"

#kill adb, start, and connect to wireless
echo "Killing adb server."
$ADB_KILL
echo "Connect to $IP."
$ADB_CONNECT $IP >/dev/null

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
	$ADB_SHELL $ADB_KMSG | tee $LOG_PATH
else
	echo "Please enable wireless adb and verify the IP matches: $IP."
fi

