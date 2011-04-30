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

if [ ! -f makelogo ]
then
	# build binary
	echo "makelogo binary not found, attempting to build it."
	RESULT=$(g++ -o makelogo makelogo.cpp 2>&1 >/dev/null)
	# check for errors
	FIND_ERR="g++:"
	if [ "$RESULT" != "${RESULT/$FIND_ERR/}" ]
	then
		echo "g++ Error:"${RESULT/$FIND_ERR/}
		exit
	fi
	# check for warnings
	FIND_WARNING="warning:"
	if [ "$RESULT" != "${RESULT/$FIND_WARNING/}" ]
	then
		echo "Warning: "${RESULT/$FIND_WARNING/}
	fi
	echo "makelogo binary built successfully."
fi

# convert header to usable data
echo "Creating boot_logo data file."
./makelogo > boot_logo

# output everything to the file
echo "Creating output file."
echo "const unsigned long LOGO_RGB24[] = {" >$LOGO_FILE
cat boot_logo >>$LOGO_FILE
echo "};" >>$LOGO_FILE
cat charge_logo.h   >>$LOGO_FILE

# done
echo "Scripte complete."

