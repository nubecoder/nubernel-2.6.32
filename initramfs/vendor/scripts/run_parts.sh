#!/system/bin/sh
#
# run_parts.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

export PATH=/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin:/data/local/tmp
export LD_LIBRARY_PATH=/vendor/lib:/system/lib:/system/lib/egl

#functions
SEND_LOG()
{
	/system/bin/log -p i -t init:init_scripts "run_parts : $1"
}

#main
SEND_LOG "Start"

for x in /system/etc/init.d/*; do
	SEND_LOG "Running: $x"
	/system/bin/logwrapper "$x"
done

SEND_LOG "End"

