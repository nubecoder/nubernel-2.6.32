#!/system/bin/sh
#
# init_01_busybox.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#functions
SEND_LOG()
{
	/system/bin/log -p i -t init:init_scripts "init_01_busybox : $1"
}

#main
SEND_LOG "Start"

if /sbin/busybox test "$1" = "recovery"; then
	SEND_LOG "Installing busybox to /sbin"
	/sbin/busybox --install -s /sbin

	SEND_LOG "Sync filesystem"
	sync
else
	SEND_LOG "Setting BB_PATH"
	BB_PATH=/data/local/tmp

	SEND_LOG "Installing temporary busybox"
	/sbin/busybox ln -s /sbin/recovery $BB_PATH/busybox
	$BB_PATH/busybox --install -s $BB_PATH/

	SEND_LOG "Ensuring busybox is properly installed"
	if $BB_PATH/test ! -f "/system/xbin/busybox"; then
		SEND_LOG "  Creating /system/xbin/busybox symlink"
		$BB_PATH/ln -s /sbin/recovery /system/xbin/busybox
	else
		BB_LINK_FOUND=$($BB_PATH/ls -l "/system/xbin/busybox" | $BB_PATH/grep "/sbin/busybox")
		if $BB_PATH/test ! "$BB_LINK_FOUND" = ""; then
			SEND_LOG "  Removing /system/xbin/busybox symlink"
			$BB_PATH/rm -f /system/xbin/busybox
			SEND_LOG "  Creating /system/xbin/busybox symlink"
			$BB_PATH/ln -s /sbin/recovery /system/xbin/busybox
		fi
	fi

	SEND_LOG "Removing /sbin/busybox"
	$BB_PATH/rm -f /sbin/busybox

	SEND_LOG "Installing /system/xbin/busybox"
	/system/xbin/busybox --install -s /system/xbin/

	SEND_LOG "Removing temporary busybox"
	/system/xbin/busybox rm -f /data/local/tmp/*

	SEND_LOG "Sync filesystem"
	/system/xbin/busybox sync

	SEND_LOG "Ensuring busybox DNS is set up properly"
	if [ ! -f "/system/etc/resolv.conf" ]; then
		SEND_LOG "  Setting Busybox DNS"
		echo "nameserver 8.8.8.8" >> /system/etc/resolv.conf
		echo "nameserver 8.8.4.4" >> /system/etc/resolv.conf
	fi
fi

SEND_LOG "End"

