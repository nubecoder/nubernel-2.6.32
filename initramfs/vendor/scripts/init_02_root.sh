#!/system/bin/sh
#
# init_02_root.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#functions
SEND_LOG()
{
	/system/bin/log -p i -t init:init_scripts "init_02_root : $1"
}

#main
SEND_LOG "Start"

if [ "$1" = "recovery" ]; then
	# do nothing
else
	SEND_LOG "Ensuring su is properly installed"
	SU_PATH=$(busybox which su)
#	SU_CHECK=$(busybox readlink $SU_PATH)
#	if [ ! "$SU_CHECK" = "" ] && [ ! -f "$SU_PATH" ]; then
	if [ ! -f "$SU_PATH" ]; then
		SEND_LOG "  Installing su to /system/bin/su"
		busybox mv -f /vendor/files/su-3.0 /system/bin/su
		busybox chown 0.0 /system/bin/su
		busybox chmod 6755 /system/bin/su
		busybox rm -f /system/xbin/su
		busybox rm -f /system/bin/jk-su
		SEND_LOG "  Symlinking su in /system/xbin/su"
		busybox ln -s /system/bin/su /system/xbin/su
	fi
	#busybox rm -f /vendor/files/su
	SEND_LOG "Ensuring user files are set up properly"
	if [ ! -f "/system/etc/passwd" ]; then
		SEND_LOG "  Setting up /etc/passwd"
		echo "root::0:0:root:/:/sbin/sh" > /system/etc/passwd
		echo "shell::2000:2000:shell:/data/local:/sbin/sh" >> /system/etc/passwd
	fi
	busybox chown root.root /system/etc/passwd
	busybox chmod 0644 /system/etc/passwd
	if [ ! -f "/system/etc/group" ]; then
		SEND_LOG "  Setting up /etc/group"
		echo "root::0:" > /system/etc/group
		echo "shell::2000:" >> /system/etc/group
	fi
	busybox chown root.root /system/etc/group
	busybox chmod 0644 /system/etc/group
	SEND_LOG "Ensuring the Superuser app is installed"
	if [ ! $(busybox find /system/app -iname "superuser.apk") ] &&\
			[ ! $(busybox find /data/app -iname "superuser.apk") ] &&\
			[ ! $(busybox find /data/app -iname "com.noshufou.android.su*") ]; then
		SEND_LOG "  Installing superuser.apk to /data/app/com.noshufou.android.su-1.apk"
		busybox mv -f /vendor/files/superuser.apk /data/app/com.noshufou.android.su-1.apk
		busybox chown system.system /data/app/com.noshufou.android.su-1.apk
		busybox chmod 0644 /data/app/com.noshufou.android.su-1.apk
		SEND_LOG "Ensuring old Superuser app data is removed"
		SU_APK_TEST=$(busybox find /data/data/ -iname "com.noshufou.android.su")
		for SU_DATA_FOLDER in $SU_APK_TEST ; do
			SEND_LOG "  Removing data folder: $SU_DATA_FOLDER"
			busybox rm -rf "$SU_DATA_FOLDER"
		done
		SU_APK_TEST=$(busybox find /data/dalvik-cache/ -iname "*superuser.apk*.dex")
		for SU_APK_FILE in $SU_APK_TEST ; do
			SEND_LOG "  Removing data file: $SU_APK_FILE"
			busybox rm -f "$SU_APK_FILE"
		done
		SU_APK_TEST=$(busybox find /data/dalvik-cache/ -iname "*com.noshufou.android.su*.dex")
		for SU_APK_FILE in $SU_APK_TEST ; do
			SEND_LOG "  Removing data file: $SU_APK_FILE"
			busybox rm -f "$SU_APK_FILE"
		done
	fi
	#busybox rm -f /vendor/files/superuser.apk
fi

SEND_LOG "Sync filesystem"
busybox sync

SEND_LOG "End"

