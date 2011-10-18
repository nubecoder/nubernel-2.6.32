#!/system/bin/sh
#
# init_00_mount_rw.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#functions
SEND_LOG()
{
	/system/bin/log -p i -t init:init_scripts "init_00_mount_rw : $1"
}

#main
SEND_LOG "Start"

SEND_LOG "Remount as RW"
/sbin/busybox mount -o remount,rw /
/sbin/busybox mount -o remount,rw /system

SEND_LOG "End"

