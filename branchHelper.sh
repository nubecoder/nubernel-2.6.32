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

# defaults
RELEASE="n"
FEATURE="n"
VERBOSE="n"

# define vars
NEW_VERSION=
FEATURE_NAME=
ERROR_MSG=

# functions
SHOW_HELP()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "Usage options for $0:"
	echo "-f : Checkout a new feature branch."
	echo "     Example: -f overclock"
	echo "-h : Print this help info."
	echo "-r : Checkout a new release branch."
	echo "     Example: -r 0.0.1."
	echo "-v : Verbose mode."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	exit 1
}
SHOW_SETTINGS()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	if [ "$RELEASE" = "y" ]
	then
		echo "Old Version  == $CURRENT_VERSION"
		echo "Vew Version  == ${VERSION_STRING}$NEW_VERSION"
		echo "Verbose Mode == $VERBOSE"
	fi
	if [ "$FEATURE" = "y" ]
	then
		echo "Feature Name == $FEATURE_NAME"
		echo "Verbose Mode == $VERBOSE"
	fi
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
BRANCH_RELEASE()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	# start time
	local T1=$(date +%s)
	echo "Begin release branch..." && echo ""
	# checkout new branch (always from dev)
	local RESULT=$(git checkout -b release-v${NEW_VERSION} dev 2>&1 >/dev/null)
	# check for errors
	local FIND_ERR="error: "
	if [ "$RESULT" != "${RESULT/$FIND_ERR/}" ]
	then
		ERROR_MSG=${RESULT/$FIND_ERR/}
		SHOW_ERROR
		SHOW_COMPLETED
	fi
	# update files
	local PATTERN="$CURRENT_VERSION"
	local REPLACEMENT="${VERSION_STRING}$NEW_VERSION"
	if [ "$VERBOSE" = "y" ]
	then
		sed -i "s/$PATTERN/$REPLACEMENT/g" build_kernel.sh
		sed -i "s/$PATTERN/$REPLACEMENT/g" initramfs/default.prop
		sed -i "s/$PATTERN/$REPLACEMENT/g" Kernel/update/META-INF/com/google/android/updater-script
		sed -i "s/$PATTERN/$REPLACEMENT/g" Kernel/update/META-INF/com/android/metadata
		sed -i "s/$PATTERN/$REPLACEMENT/g" ncBuildHelper.sh
		sed -i "s/$PATTERN/$REPLACEMENT/g" README
		sed -i "s/$PATTERN/$REPLACEMENT/g" $0
	else
		sed -i "s/$PATTERN/$REPLACEMENT/g" build_kernel.sh
		sed -i "s/$PATTERN/$REPLACEMENT/g" initramfs/default.prop >/dev/null 2>&1
		sed -i "s/$PATTERN/$REPLACEMENT/g" Kernel/update/META-INF/com/google/android/updater-script >/dev/null 2>&1
		sed -i "s/$PATTERN/$REPLACEMENT/g" Kernel/update/META-INF/com/android/metadata >/dev/null 2>&1
		sed -i "s/$PATTERN/$REPLACEMENT/g" ncBuildHelper.sh >/dev/null 2>&1
		sed -i "s/$PATTERN/$REPLACEMENT/g" README >/dev/null 2>&1
		sed -i "s/$PATTERN/$REPLACEMENT/g" $0 >/dev/null 2>&1
	fi
	local BRANCH_MSG="Branched to 'release-v${NEW_VERSION}'."
	local PATTERN="Changelog:"
	local REPLACEMENT="Changelog:\n\n"$(date +%m-%d-%Y)":\n$BRANCH_MSG"
	if [ "$VERBOSE" = "y" ]
	then
		sed -i "s/$PATTERN/$REPLACEMENT/g" README
	else
		sed -i "s/$PATTERN/$REPLACEMENT/g" README >/dev/null 2>&1
	fi
	# git add changes
	if [ "$VERBOSE" = "y" ]
	then
		git add build_kernel.sh
		git add initramfs/default.prop
		git add Kernel/update/META-INF/com/google/android/updater-script
		git add Kernel/update/META-INF/com/android/metadata
		git add ncBuildHelper.sh
		git add README
		git add $0
	else
		git add build_kernel.sh >/dev/null 2>&1
		git add initramfs/default.prop >/dev/null 2>&1
		git add Kernel/update/META-INF/com/google/android/updater-script >/dev/null 2>&1
		git add Kernel/update/META-INF/com/android/metadata >/dev/null 2>&1
		git add ncBuildHelper.sh >/dev/null 2>&1
		git add README >/dev/null 2>&1
		git add $0 >/dev/null 2>&1
	fi
	# show some info
	echo "git status -s:"
	git status -s
	echo "git branch:"
	git branch
	# git commit
	echo "Commit:"
	git commit -m "$BRANCH_MSG"
	# end time
	local T2=$(date +%s)
	echo "" && echo "Release branch took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
BRANCH_FEATURE()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	# start time
	local T1=$(date +%s)
	echo "Begin feature branch..." && echo ""
	# checkout new branch (always from dev)
	local RESULT=$(git checkout -b feature-${FEATURE_NAME} dev 2>&1 >/dev/null)
	# check for errors
	local FIND_ERR="error: "
	if [ "$RESULT" != "${RESULT/$FIND_ERR/}" ]
	then
		ERROR_MSG=${RESULT/$FIND_ERR/}
		SHOW_ERROR
		SHOW_COMPLETED
	fi
	# update files
	local BRANCH_MSG="Branched to 'feature-${FEATURE_NAME}'."
	local PATTERN="Changelog:"
	local REPLACEMENT="Changelog:\n\n"$(date +%m-%d-%Y)":\n$BRANCH_MSG"
	if [ "$VERBOSE" = "y" ]
	then
		sed -i "s/$PATTERN/$REPLACEMENT/g" README
	else
		sed -i "s/$PATTERN/$REPLACEMENT/g" README >/dev/null 2>&1
	fi
	# git add changes
	if [ "$VERBOSE" = "y" ]
	then
		git add ncMultiBuild.sh
		git add README
		git add $0
	else
		git add ncMultiBuild.sh >/dev/null 2>&1
		git add README >/dev/null 2>&1
		git add $0 >/dev/null 2>&1
	fi
	# show some info
	echo "git status -s:"
	git status -s
	echo "git branch:"
	git branch
	# git commit
	echo "Commit:"
	git commit -m "$BRANCH_MSG"
	# end time
	local T2=$(date +%s)
	echo "" && echo "Feature branch took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}


# main
while getopts  ":f:hr:v" flag
do
	case "$flag" in
	f)
		FEATURE="y"
		RELEASE="n"
		FEATURE_NAME="$OPTARG"
		;;
	h)
		SHOW_HELP
		;;
	r)
		FEATURE="n"
		RELEASE="y"
		NEW_VERSION="$OPTARG"
		;;
	v)
		VERBOSE="y"
		;;
	*)
		ERROR_MSG="Error:: problem with option '$OPTARG'"
		SHOW_ERROR
		SHOW_HELP
		;;
	esac
done

if [ "$RELEASE" = "y" ]
then
	SHOW_SETTINGS
	BRANCH_RELEASE
fi
if [ "$FEATURE" = "y" ]
then
	SHOW_SETTINGS
	BRANCH_FEATURE
fi

if [ "$RELEASE" = "n" -a "$FEATURE" = "n" ]
then
	SHOW_HELP
fi

SHOW_COMPLETED

