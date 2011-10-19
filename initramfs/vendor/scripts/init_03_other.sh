#!/system/bin/sh
#
# init_03_other
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#functions
SEND_LOG()
{
	/system/bin/log -p i -t init:init_scripts "init_03_other : $1"
}

#main
SEND_LOG "Start"

if [ "$1" = "recovery" ]; then
	SEND_LOG "Moving recovery assets to /sbin"
	busybox mv -f /res/sbin/* /sbin/

	SEND_LOG "Moving recovery.fstab to /etc"
	busybox mkdir /etc
	busybox mv -f /res/etc/recovery.fstab /etc/recovery.fstab
else
	SEND_LOG "Ensuring bash is installed"
	if [ ! -f "/system/bin/bash" ]; then
		SEND_LOG "  Installing Bash to /system/bin/"
		busybox mv -f /sbin/bash /system/bin/bash
	fi
	busybox chmod 0755 /system/bin/bash
	#busybox rm -f /sbin/bash

	SEND_LOG "Checking for bash as default shell"
	BASH_FOUND=$(busybox ls -l "/system/bin/sh" | busybox grep "/system/bin/bash")
	if [ ! "$BASH_FOUND" = "" ] && [ -f "/system/bin/bash" ]; then
		SEND_LOG "  Allowing bash as default shell"
		busybox rm -f /bin/sh
		busybox rm -f /sbin/sh
		busybox ln -s /bin/sh /system/bin/sh
		busybox ln -s /sbin/sh /system/bin/sh
	fi

	SEND_LOG "Preventing certain malware apps (DroidDream)"
	. > /system/bin/profile
	busybox chmod 0400 /system/bin/profile

	SEND_LOG "Ensuring KB timer_delay is set up properly"
	if [ ! -f "/data/local/timer_delay" ]; then
		SEND_LOG "  Setting KB timer_delay to 5"
		echo 5 > /data/local/timer_delay
	fi
	busybox cat /data/local/timer_delay > /sys/devices/platform/s3c-keypad/timer_delay
fi

SEND_LOG "Sync filesystem"
busybox sync

SEND_LOG "End"

