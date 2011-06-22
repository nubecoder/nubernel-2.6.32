#!/system/bin/sh
#
# cpu_thres_table.sh
#
#
# nubecoder 2011
# www.nubecoder.com

#define variables
THRES_TABLE_PATH="/sys/devices/system/cpu/cpu0/cpufreq/cpu_thres_table"

#functions
SHOW_TABLE_INFO()
{
	local TABLE_INFO=$(cat $THRES_TABLE_PATH)
	echo
}

if [ "" = $1 ]
then
	SHOW_TABLE_INFO
fi

