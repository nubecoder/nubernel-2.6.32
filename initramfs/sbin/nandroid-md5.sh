#!/sbin/busybox sh

BB=/sbin/busybox

cd $1
$BB md5sum *img > nandroid.md5
return $?
