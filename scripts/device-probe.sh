#!/sbin/sh
# Read-only hardware inspection. Run in TWRP through Bugjaeger ADB shell.
# Does not read partition payloads, IMEI or calibration data.
# Boot arguments may contain device identifiers: review output before sharing.
echo "=== model ==="
getprop ro.product.device
getprop ro.product.vendor.device
getprop ro.boot.hardware
getprop ro.boot.slot_suffix
echo "=== boot arguments ==="
cat /proc/cmdline
echo "=== partition names, resolved paths, byte sizes ==="
for dir in /dev/block/by-name /dev/block/bootdevice/by-name; do
  [ -d "$dir" ] || continue
  for p in "$dir"/*; do
    [ -b "$p" ] || continue
    printf '%s %s ' "${p##*/}" "$(readlink -f "$p")"
    blockdev --getsize64 "$p"
  done
  break
done
echo "=== block inventory ==="
cat /proc/partitions
echo "=== filesystem types ==="
blkid
echo "=== recovery fstab ==="
for f in /etc/recovery.fstab /etc/twrp.fstab; do
  [ ! -f "$f" ] || cat "$f"
done
echo "=== panel/touch/storage/USB driver messages ==="
dmesg | grep -iE 'lcm|panel|nt366|tianma|csot|ufs|mtu3|mt6360' | tail -100
echo "=== possible persistent crash log names ==="
ls -l /sys/fs/pstore 2>/dev/null
exit 0
