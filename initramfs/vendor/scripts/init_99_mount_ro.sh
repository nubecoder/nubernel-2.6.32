#!/system/bin/sh
#
# init_99_mount_ro.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#functions
SEND_LOG()
{
	/system/bin/log -p i -t init:init_scripts "init_99_mount_ro : $1"
}

#main
SEND_LOG "Start"

if [ "$1" = "recovery" ]; then
	# do nothing
else
	SEND_LOG "Remount ro"
	# Remount as RO
	busybox mount -o remount,ro /
	busybox mount -o remount,ro /system
fi

SEND_LOG "End"

