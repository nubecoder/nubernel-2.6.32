#!/bin/bash

# Defaults
BUILD_KERNEL=y
CLEAN=n
CROSS_COMPILE="$PWD/../toolchains/android-toolchain-4.4.3/bin/arm-linux-androideabi-"
DEFCONFIG=n
MKZIP='7z -mx9 -mmt=1 a "$OUTFILE" .'
PRODUCE_TAR=n
PRODUCE_ZIP=n
TARGET="nubernel"
THREADS=$(expr 1 + $(grep processor /proc/cpuinfo | wc -l))
VERSION=$(date +%m%d%Y)

SHOW_HELP()
{
	echo
	echo "Usage options for build_kernel.sh:"
	echo "-c : Run 'make clean'."
	echo "-d : Use specified config."
	echo "     For example, use -d myconfig to 'make myconfig_defconfig'."
	echo "-h : Print this help."
	echo "-j : Use a specified number of threads to build (auto detected by default)."
	echo "     For example, use -j4 to make with 4 threads."
	echo "-t : Produce tar file suitable for flashing with Odin."
	echo "-z : Produce zip file suitable for flashing via Recovery."
	echo
	exit 1
}

# Get values from Args
set -- $(getopt cd:hj:tz "$@")
while [ $# -gt 0 ]
do
	case "$1" in
	(-c) CLEAN=y;;
	(-d) DEFCONFIG=y; TARGET="$2"; shift;;
	(-h) SHOW_HELP;;
	(-j) THREADS=$2; shift;;
	(-t) PRODUCE_TAR=y;;
	(-z) PRODUCE_ZIP=y;;
	(--) shift; break;;
	(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
	(*) break;;
	esac
	shift
done

echo "make clean     == "$CLEAN
echo "use defconfig  == "$DEFCONFIG
echo "build target   == "$TARGET
echo "make threads   == "$THREADS
echo "build kernel   == "$BUILD_KERNEL
echo "create tar     == "$PRODUCE_TAR
echo "create zip     == "$PRODUCE_ZIP

if [ "$CLEAN" = "y" ] ; then
	echo "Cleaning source directory." && echo ""
	make -j"$THREADS" ARCH=arm clean 2>&1 | tee make.clean.out
fi

if [ "$DEFCONFIG" = "y" -o ! -f ".config" ] ; then
	echo "Using default configuration for $TARGET." && echo ""
	make -j"$THREADS" ARCH=arm ${TARGET}_defconfig 2>&1 | tee make.defconfig.out
fi

if [ "$BUILD_KERNEL" = "y" ] ; then
	T1=$(date +%s)
	echo "Beginning zImage compilation..." && echo ""
	make -j"$THREADS" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" 2>&1 | tee make.out
	T2=$(date +%s)
	echo "" && echo "Compilation took $(($T2 - $T1)) seconds." && echo ""
fi

if [ "$PRODUCE_TAR" = y ] ; then
	echo "Generating $TARGET-$VERSION.tar for flashing with Odin." && echo ""
	tar c -C arch/arm/boot zImage >"$TARGET-$VERSION.tar"
fi

if [ "$PRODUCE_ZIP" = y ] ; then
	echo "Generating $TARGET-$VERSION.zip for flashing as update.zip." && echo ""
	rm -fr "$TARGET-$VERSION.zip"
	rm -f update/zImage
	cp arch/arm/boot/zImage update
	OUTFILE="$PWD/$TARGET-$VERSION.zip"
	pushd update
	eval "$MKZIP" >/dev/null 2>&1
	popd
fi

