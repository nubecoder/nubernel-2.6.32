#!/bin/bash
#
# ncMultiBuild.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

# define envvars
TARGET="nubernel"
KBUILD_BUILD_VERSION="nubernel-EC05_v0.0.0"
CROSS_COMPILE="/home/nubecoder/android/kernel_dev/toolchains/arm-2011.03-41/bin/arm-none-linux-gnueabi-"

# define defaults
BUILD_KERNEL=n
CLEAN=n
DEFCONFIG=n
DISTCLEAN=n
PRODUCE_TAR=n
PRODUCE_ZIP=n
VERBOSE=n
WIFI_FLASH=n

# define vars
MKZIP='7z -mx9 -mmt=1 a "$OUTFILE" .'
THREADS=$(expr 1 + $(grep processor /proc/cpuinfo | wc -l))
VERSION=$(date +%m-%d-%Y)
ERROR_MSG=
TIME_START=
TIME_END=

# define outfile path
OUTFILE_PATH="$PWD/$TARGET-$VERSION"

# exports
export KBUILD_BUILD_VERSION

# functions
SHOW_HELP()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "Usage options for $0:"
	echo "-b : Build zImage (kernel)."
	echo "-c : Run 'make clean'."
	echo "-C : Run 'make distclean'."
	echo "-d : Use specified config."
	echo "     For example, use -d myconfig to 'make myconfig_defconfig'."
	echo "-h : Print this help info."
	echo "-j : Number of threads (auto detected by default)."
	echo "     For example, use -j4 to make with 4 threads."
	echo "-t : Produce tar file suitable for flashing with Odin."
	echo "-v : Show verbose output while building zImage (kernel)."
	echo "-w : Wifi Flash, for use with adb wireless."
	echo "-z : Produce zip file suitable for flashing via Recovery."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	exit 1
}
SHOW_SETTINGS()
{
	TIME_START=$(date +%s)
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "build version  == $KBUILD_BUILD_VERSION"
	echo "cross compile  == $CROSS_COMPILE"
	echo "outfile path   == $OUTFILE_PATH"
	echo "make clean     == $CLEAN"
	echo "make distclean == $DISTCLEAN"
	echo "use defconfig  == $DEFCONFIG"
	echo "build target   == $TARGET"
	echo "make threads   == $THREADS"
	echo "verbose output == $VERBOSE"
	echo "build kernel   == $BUILD_KERNEL"
	echo "create tar     == $PRODUCE_TAR"
	echo "create zip     == $PRODUCE_ZIP"
	echo "wifi flash     == $WIFI_FLASH"
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
NOTIFY_COMPLETED()
{
	aplay notify.wav >/dev/null 2>&1
}
SHOW_COMPLETED()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "Script completed."
	TIME_END=$(date +%s)
	echo "" && echo "Total time: $(($TIME_END - $TIME_START)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	NOTIFY_COMPLETED
	exit
}
SHOW_ERROR()
{
	if [ -n "$ERROR_MSG" ] ; then
		echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
		echo "$ERROR_MSG"
	fi
}
REMOVE_DOTCONFIG()
{
	rm -f Kernel/.config
}
MAKE_CLEAN()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin make clean..." && echo ""
	pushd Kernel > /dev/null
		nice make V=1 -j"$THREADS" ARCH=arm clean 2>&1 >make.clean.out
	popd > /dev/null
	local T2=$(date +%s)
	echo "" && echo "make clean took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
MAKE_DISTCLEAN()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin make distclean..." && echo ""
	pushd Kernel > /dev/null
		nice make V=1 -j"$THREADS" ARCH=arm distclean 2>&1 >make.distclean.out
	popd > /dev/null
	local T2=$(date +%s)
	echo "" && echo "make distclean took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
MAKE_DEFCONFIG()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin make ${TARGET}_defconfig..." && echo ""
	pushd Kernel > /dev/null
		nice make V=1 -j"$THREADS" ARCH=arm ${TARGET}_defconfig 2>&1 >make.defconfig.out
	popd > /dev/null
	local T2=$(date +%s)
	echo "" && echo "make ${TARGET}_defconfig took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
BUILD_ZIMAGE()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin building zImage..." && echo ""
	pushd Kernel > /dev/null
	if [ "$VERBOSE" = "y" ] ;
		then
			nice make V=1 -j"$THREADS" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" 2>&1 | tee make.out
		else
			nice make -j"$THREADS" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" 2>&1 | tee make.out
	fi
	popd > /dev/null
	local T2=$(date +%s)
	echo "" && echo "building zImage took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
CREATE_TAR()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin $TARGET-$VERSION.tar creation..." && echo ""
	pushd Kernel > /dev/null
		tar c -C arch/arm/boot zImage >"$OUTFILE_PATH.tar"
	popd > /dev/null
	local T2=$(date +%s)
	echo "" && echo "$TARGET-$VERSION.tar creation took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
CREATE_ZIP()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin $TARGET-$VERSION.zip creation..." && echo ""
	pushd Kernel > /dev/null
		rm -fr "$TARGET-$VERSION.zip"
		rm -f update/zImage
		cp arch/arm/boot/zImage update
		OUTFILE="$OUTFILE_PATH.zip"
		pushd update > /dev/null
			eval "$MKZIP" > /dev/null 
		popd > /dev/null
	popd > /dev/null
	local T2=$(date +%s)
	echo "" && echo "$TARGET-$VERSION.zip creation took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}
WIFI_FLASH_SCRIPT()
{
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	local T1=$(date +%s)
	echo "Begin Wifi kernel flash helper script..." && echo ""
	pushd scripts > /dev/null
			sh wifiFlashHelper.sh
	popd > /dev/null
	local T2=$(date +%s)
	echo "" && echo "Wifi kernel flash took $(($T2 - $T1)) seconds."
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	echo "*"
}

# main
while getopts  ":bcCd:hj:tvwz" flag
do
	case "$flag" in
	b)
		BUILD_KERNEL=y
		;;
	c)
		CLEAN=y
		;;
	C)
		DISTCLEAN=y
		;;
	d)
		DEFCONFIG=y
		TARGET="$OPTARG"
		;;
	h)
		SHOW_HELP
		;;
	j)
		THREADS=$OPTARG
		;;
	t)
		PRODUCE_TAR=y
		;;
	v)
		VERBOSE=y
		;;
	w)
		WIFI_FLASH=y
		;;
	z)
		PRODUCE_ZIP=y
		;;
	*)
		ERROR_MSG="Error:: problem with option '$OPTARG'"
		SHOW_ERROR
		SHOW_HELP
		;;
	esac
done

# show current settings
SHOW_SETTINGS

# force MAKE_DEFCONFIG below
REMOVE_DOTCONFIG

if [ "$CLEAN" = "y" ] ; then
	MAKE_CLEAN
fi
if [ "$DISTCLEAN" = "y" ] ; then
	MAKE_DISTCLEAN
fi
if [ "$DEFCONFIG" = "y" -o ! -f "Kernel/.config" ] ; then
	MAKE_DEFCONFIG
fi
if [ "$BUILD_KERNEL" = "y" ] ; then
	BUILD_ZIMAGE
fi
if [ "$PRODUCE_TAR" = y ] ; then
	CREATE_TAR
fi
if [ "$PRODUCE_ZIP" = y ] ; then
	CREATE_ZIP
fi
if [ "$WIFI_FLASH" = y ] ; then
	WIFI_FLASH_SCRIPT
fi

# show completed message
SHOW_COMPLETED

