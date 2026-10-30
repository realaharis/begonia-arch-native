#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD/work/rootfs"
# ALARM's own BusyBox and glibc; no Alpine or foreign userspace.
chroot "$root" /bin/bash -s <<'CHROOT'
set -euo pipefail
d=/tmp/begonia-initrd
test ! -e "$d"
mkdir -p "$d"/{bin,sbin,usr/bin,usr/sbin,usr/lib,dev,proc,sys,run,newroot}
ln -s usr/lib "$d/lib"
ln -s usr/lib "$d/lib64"
cp /usr/lib/initcpio/busybox "$d/bin/busybox"
for app in $(/usr/lib/initcpio/busybox --list); do
  [ "$app" = busybox ] || ln -sf busybox "$d/bin/$app"
done
for app in sh mount switch_root dmesg sleep cat tee cp sync mkdir grep kill; do
  test -e "$d/bin/$app"
done
rm -f "$d/bin/blkid" "$d/bin/mountpoint"
cp /usr/bin/blkid "$d/bin/blkid"
cp /usr/bin/mountpoint "$d/bin/mountpoint"
# Resolve runtime libraries from inside Arch, not the Ubuntu builder.
libs=$(ldd /usr/lib/initcpio/busybox /usr/bin/blkid /usr/bin/mountpoint | awk '/=> \/|^[[:space:]]*\// {for (i=1;i<=NF;i++) if ($i ~ /^\//) print $i}' | sort -u)
for lib in $libs; do
  mkdir -p "$d$(dirname "$lib")"
  cp -L "$lib" "$d$lib"
done
install -m755 /usr/lib/begonia/init "$d/init"
install -m755 /usr/lib/begonia/usb-gadget "$d/usb-gadget"
CHROOT
d="$root/tmp/begonia-initrd"
# Run representative binaries inside the assembled initrd to catch missing loaders.
chroot "$d" /bin/sh -c 'echo initramfs-userspace-ok; /bin/blkid --version; /bin/mountpoint --version'
find "$d" -exec touch -h -d '@1756983151' {} +
(cd "$d" && find . -print0 | LC_ALL=C sort -z | cpio --null --create --format=newc --owner=0:0 --reproducible) | gzip -n -9 > out/initramfs.cpio.gz
rm -rf "$d"
