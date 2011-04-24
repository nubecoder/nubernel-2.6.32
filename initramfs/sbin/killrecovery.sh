#!/sbin/busybox sh

BB=/sbin/busybox

$BB mkdir -p /sd-ext
$BB rm /cache/recovery/command
$BB rm /cache/update.zip
$BB touch /tmp/.ignorebootmessage
$BB kill $($BB ps | $BB grep /sbin/adbd)
$BB kill $($BB ps | $BB grep /sbin/recovery)

# On the Galaxy S, the recovery comes test signed, but the
# recovery is not automatically restarted.
if [ -f /init.smdkc110.rc ]; then
    /sbin/recovery &
fi

exit 1
