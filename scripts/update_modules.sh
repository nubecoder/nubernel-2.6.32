#!/bin/bash
#
# update_modules.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#define base paths
SRC_BASE="$PWD/Kernel/drivers"
DST_BASE="$PWD/initramfs/lib/modules"
CC_STRIP="$PWD/toolchains/android-toolchain-4.4.3/bin/arm-linux-androideabi-strip"

#copy modules
echo "Copying modules to $DST_BASE/*"

cp "$SRC_BASE/net/tun.ko" "$DST_BASE/tun.ko"
cp "$SRC_BASE/bluetooth/bthid/bthid.ko" "$DST_BASE/bthid.ko"
cp "$SRC_BASE/net/wireless/bcm4329/victory/dhd.ko" "$DST_BASE/dhd.ko"
cp "$SRC_BASE/net/wireless/wimax/cmc7xx_sdio.ko" "$DST_BASE/cmc7xx_sdio.ko"
cp "$SRC_BASE/net/wireless/wimaxgpio/wimax_gpio.ko" "$DST_BASE/wimax_gpio.ko"
cp "$SRC_BASE/onedram/dpram_recovery/dpram_recovery.ko" "$DST_BASE/dpram_recovery.ko"
#cp "$SRC_BASE/onedram/victory/dpram.ko" "$DST_BASE/dpram.ko"
cp "$SRC_BASE/onedram_svn/victory/modemctl/modemctl.ko" "$DST_BASE/modemctl.ko"
cp "$SRC_BASE/onedram_svn/victory/onedram/onedram.ko" "$DST_BASE/onedram.ko"
cp "$SRC_BASE/onedram_svn/victory/svnet/svnet.ko" "$DST_BASE/svnet.ko"
cp "$SRC_BASE/samsung/fm_si4709/Si4709_driver.ko" "$DST_BASE/Si4709_driver.ko"
cp "$SRC_BASE/samsung/vibetonz/vibrator.ko" "$DST_BASE/vibrator.ko"
cp "$SRC_BASE/scsi/scsi_wait_scan.ko" "$DST_BASE/scsi_wait_scan.ko"
cp "$SRC_BASE/staging/android/logger.ko" "$DST_BASE/logger.ko"
cp "$PWD/Kernel/fs/cifs/cifs.ko" "$DST_BASE/cifs.ko"

#strip modules
echo "Stripping modules in $DST_BASE/*"

$CC_STRIP -s "$DST_BASE/bthid.ko"
$CC_STRIP -s "$DST_BASE/dhd.ko"
$CC_STRIP -s "$DST_BASE/cmc7xx_sdio.ko"
$CC_STRIP -s "$DST_BASE/wimax_gpio.ko"
$CC_STRIP -s "$DST_BASE/dpram_recovery.ko"
#$CC_STRIP -s "$DST_BASE/dpram.ko"
$CC_STRIP -s "$DST_BASE/modemctl.ko"
$CC_STRIP -s "$DST_BASE/onedram.ko"
$CC_STRIP -s "$DST_BASE/svnet.ko"
$CC_STRIP -s "$DST_BASE/Si4709_driver.ko"
$CC_STRIP -s "$DST_BASE/vibrator.ko"
$CC_STRIP -s "$DST_BASE/scsi_wait_scan.ko"
$CC_STRIP -s "$DST_BASE/logger.ko"

echo "Finished."

