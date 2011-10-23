#!/system/bin/sh
#
# init_98_clean.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#functions
SEND_LOG()
{
	/system/bin/log -p i -t init:init_scripts "init_98_clean : $1"
}

#main
SEND_LOG "Start"

if [ "$1" = "recovery" ]; then
	SEND_LOG "Remove unneccessary files in /sbin"
	for FILE in keytimer
	do
		SEND_LOG "  rm -f /sbin/$FILE"
		busybox rm -f /sbin/$FILE
	done

	SEND_LOG "Remove unneccessary files in /"
	for FILE in fota.rc init.rc init.rc.sdcard lpm.rc recovery.rc; do
		SEND_LOG "rm -f /$FILE"
		busybox rm -f /$FILE
	done

	SEND_LOG "Remove unneccessary folders in /"
	for FOLDER in res/sbin res/etc; do
		SEND_LOG " rm -rf $FOLDER"
		busybox rm -rf /$FOLDER
	done
else
	SEND_LOG "Remove unneccessary files in /sbin"
	for FILE in bash
	do
		SEND_LOG "  rm -f /sbin/$FILE"
		busybox rm -f /sbin/$FILE
	done

	SEND_LOG "Remove unneccessary files in /"
	for FILE in fota.rc init.rc init.rc.sdcard init.smdkc110.rc lpm.rc recovery.rc init init.log init.sh initlog.sh; do
		SEND_LOG "rm -f /$FILE"
		busybox rm -f /$FILE
	done

	SEND_LOG "Remove unneccessary folders in /"
	for FOLDER in res; do
		SEND_LOG "rm -rf /$FOLDER"
		busybox rm -rf /$FOLDER
	done
fi

SEND_LOG "Remove unneccessary folders in /vendor/files/"
for FILE in su-3.0 superuser.apk ; do
	SEND_LOG "rm -f /vendor/files/$FILE"
	busybox rm -f /vendor/files/$FILE
done

SEND_LOG "Sync filesystem"
busybox sync

SEND_LOG "End"

