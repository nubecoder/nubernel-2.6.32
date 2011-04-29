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

# define vars
NEW_VERSION=
FEATURE_NAME=
ERROR_MSG=

# functions
SHOW_HELP()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "Usage options for $0:"
	echo "-f : Set the feature name and checkout new feature branch."
	echo "     Example: -f overclock"
	echo "-h : Print this help info."
	echo "-v : Set the version and checkout new release branch."
	echo "     Example: -v 0.0.1."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	exit 1
}
SHOW_SETTINGS()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"

	if [ "$RELEASE" = "y" ]
	then
		echo "current version == $CURRENT_VERSION"
		echo "new version     == ${VERSION_STRING}$NEW_VERSION"
	fi

	if [ "$FEATURE" = "y" ]
	then
		echo "feature name    == $FEATURE_NAME"
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
	local T1=$(date +%s)
	echo "Begin release branch..." && echo ""

	# checkout new release branch (always from dev)
	git checkout -b release-v${NEW_VERSION} dev

	# update files
	PATTERN="$CURRENT_VERSION"
	REPLACEMENT="${VERSION_STRING}$NEW_VERSION"
	sed -i "s/$PATTERN/$REPLACEMENT/g" ncMultiBuild.sh
	sed -i "s/$PATTERN/$REPLACEMENT/g" README
	sed -i "s/$PATTERN/$REPLACEMENT/g" $0
	PATTERN="Changelog:"
	REPLACEMENT="Changelog:\n\n"$(date +%d-%m-%Y)":\nCreated 'release-v${NEW_VERSION}' branch."
	sed -i "s/$PATTERN/$REPLACEMENT/g" README

	#git add changes
	git add ncMultiBuild.sh
	git add README
	git add $0

	# show some info
	git status -s
	git branch

	# git commit
	git commit -m '"Created release-v'${NEW_VERSION}' branch."'

	local T2=$(date +%s)
	echo "" && echo "Release branch took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
BRANCH_FEATURE()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin feature branch..." && echo ""

	# checkout new feature branch (always from dev)
	git checkout -b feature-${FEATURE_NAME} dev

	# update files
	PATTERN="Changelog:"
	REPLACEMENT="Changelog:\n\n"$(date +%d-%m-%Y)":\nCreated 'feature-${FEATURE_NAME}' branch."
	sed -i "s/$PATTERN/$REPLACEMENT/g" README

	#git add changes
	git add ncMultiBuild.sh
	git add README
	git add $0

	# show some info
	git status -s
	git branch

	# git commit
	git commit -m '"Created feature-'${FEATURE_NAME}' branch."'

	local T2=$(date +%s)
	echo "" && echo "Feature branch took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}


# main
while getopts  ":f:hv:" flag
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
	v)
		FEATURE="n"
		RELEASE="y"
		NEW_VERSION="$OPTARG"
		;;
	*)
		ERROR_MSG="Error:: problem with option '$OPTARG'"
		SHOW_ERROR
		SHOW_HELP
		;;
	esac
done

SHOW_SETTINGS

if [ "$RELEASE" = "y" ]
then
	BRANCH_RELEASE
fi
if [ "$FEATURE" = "y" ]
then
	BRANCH_FEATURE
fi

SHOW_COMPLETED

