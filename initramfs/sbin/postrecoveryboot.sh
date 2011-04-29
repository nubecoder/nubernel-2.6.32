#!/sbin/busybox sh

BB=/sbin/busybox

# Restart with root hacked adbd
$BB cat /proc/kmsg
$BB ls -l /dev/block
$BB ps

