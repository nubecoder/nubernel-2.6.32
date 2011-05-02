#!/bin/bash
#
# createBootLogo.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

# defines
LOGO_PATH="$PWD/../Kernel/drivers/video/samsung"
LOGO_FILE="$LOGO_PATH/logo_rgb24_wvga_portrait_nubecoder.h"
ERROR_MSG=

# functions
SHOW_COMPLETED()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "Script completed."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	exit
}
SHOW_ERROR()
{
	if [ -n "$ERROR_MSG" ] ; then
		echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
		echo "$ERROR_MSG"
	fi
}

BUILD_MAKELOGO()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	# start time
	local T1=$(date +%s)
	echo "Begin build makelogo..." && echo ""
	# remove old files
	rm -f makelogo
	# build binary
	local RESULT=$(g++ -o makelogo makelogo.cpp 2>&1 >/dev/null)
	# check for errors
	local FIND_ERR_1="g++: "
	if [ "$RESULT" != "${RESULT/$FIND_ERR_1/}" ]
	then
		ERROR_MSG="g++ Error: "${RESULT/$FIND_ERR_1/}
		SHOW_ERROR
		SHOW_COMPLETED
	fi
	local FIND_ERR_2="fatal error: "
	if [ "$RESULT" != "${RESULT/$FIND_ERR_2/}" ]
	then
		ERROR_MSG="Fatal Error: "${RESULT/$FIND_ERR_2/}
		SHOW_ERROR
		SHOW_COMPLETED
	fi
	# check for warnings
	local FIND_WARNING="warning: "
	if [ "$RESULT" != "${RESULT/$FIND_WARNING/}" ]
	then
		#ERROR_MSG="Warning: "${RESULT/$FIND_WARNING/}
		echo "Warning: "${RESULT/$FIND_WARNING/}
		SHOW_ERROR
	fi
	# end time
	local T2=$(date +%s)
	echo "" && echo "Build makelogo took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
CREATE_LOGO()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	# start time
	local T1=$(date +%s)
	echo "Begin bootlogo creation..." && echo ""
	# remove old files
	rm -f boot_logo.h
	rm -f $LOGO_FILE
	# convert header to usable data
	./makelogo > boot_logo.h
	# output to file
	cat boot_logo.h >>$LOGO_FILE
	cat charge_logo.h   >>$LOGO_FILE
	# end time
	local T2=$(date +%s)
	echo "" && echo "bootlogo creation took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}

# main
BUILD_MAKELOGO

CREATE_LOGO

SHOW_COMPLETED

