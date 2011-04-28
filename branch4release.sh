#!/bin/bash
#
# branch4release.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#define version string
CURRENT_VERSION="nubernel-EC05_v0.0.0"
VERSION_STRING="nubernel-EC05_v"

# define vars
NEW_VERSION=
ERROR_MSG=

# functions
SHOW_HELP()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "Usage options for $0:"
	echo "-v : Show verbose output while building zImage (kernel)."
	echo "Example: -v 0.0.1."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	exit 1
}
SHOW_SETTINGS()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "current version  == $VERSION_STRING"
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
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




INCREMENT_VERSION()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin increment version..." && echo ""
	#
	#
	#
	local T2=$(date +%s)
	echo "" && echo "Increment version took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}

TEST()
{
	# checkout new release branch (always from dev)
	git checkout -b release-v${NEW_VERSION} dev

	# update files
	PATTERN="$CURRENT_VERSION"
	REPLACEMENT="${VERSION_STRING}$NEW_VERSION"
	echo "$REPLACEMENT now in ncMultiBuild.sh"
	sed -i "s/$PATTERN/$REPLACEMENT/g" ncMultiBuild.sh
	echo "$REPLACEMENT now in build_kernel.sh"
	sed -i "s/$PATTERN/$REPLACEMENT/g" build_kernel.sh
	echo "$REPLACEMENT now in README"
	sed -i "s/$PATTERN/$REPLACEMENT/g" README

	# update self
	echo "$REPLACEMENT now in prepRelease.sh"
	sed -i "s/$PATTERN/$REPLACEMENT/g" prepRelease.sh

#	PATTERN="Changelog:"
#	REPLACEMENT="Features:\n\nChangelog:"
#	echo "Preforming action on README"
#	sed -i "s/$PATTERN/$REPLACEMENT/g" README

	#git add changes (but not README as that will need updating!)
	git add ncMultiBuild.sh
	git add build_kernel.sh
	#git add README
	#git add branch4release.sh

	# show git branches	
	git branch
}



# main
while getopts  ":v:" flag
do
	case "$flag" in
	v)
		NEW_VERSION="$OPTARG"
		;;
	*)
		ERROR_MSG="Error:: problem with option '$OPTARG'"
		SHOW_ERROR
		SHOW_HELP
		;;
	esac
done

if [ -n "$NEW_VERSION" ] ; then
	TEST
fi

SHOW_COMPLETED

