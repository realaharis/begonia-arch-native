#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "Initramfs failed at line $LINENO: $BASH_COMMAND" >&2' ERR
cd "$(dirname "$0")/.."
root="$PWD/work/rootfs"
# ALARM's own BusyBox and glibc; no Alpine or foreign userspace.
chroot "$root" /bin/bash -s <<'CHROOT'
set -Eeuo pipefail
trap 'echo "Initramfs chroot failed at line $LINENO: $BASH_COMMAND" >&2' ERR
d=/tmp/begonia-initrd
test ! -e "$d"
mkdir -p "$d"/{bin,sbin,usr/bin,usr/sbin,usr/lib,dev,proc,sys,run,newroot}
ln -s usr/lib "$d/lib"
ln -s usr/lib "$d/lib64"
cp /usr/lib/initcpio/busybox "$d/bin/busybox"
for app in $(/usr/lib/initcpio/busybox --list); do
  [ "$app" = busybox ] || ln -sf busybox "$d/bin/$app"
done
# mkinitcpio-busybox deliberately omits mount and switch_root.
# Copy Arch util-linux binaries, never Ubuntu builder binaries.
binaries=(/usr/lib/initcpio/busybox)
for app in blkid mountpoint mount switch_root; do
  test -x "/usr/bin/$app" || { echo "Missing Arch util-linux binary: $app" >&2; exit 1; }
  rm -f "$d/bin/$app"
  cp -L "/usr/bin/$app" "$d/bin/$app"
  binaries+=("/usr/bin/$app")
done
for app in sh mount switch_root dmesg sleep cat tee cp sync mkdir grep kill ln; do
  test -e "$d/bin/$app" || { echo "Missing initramfs command: $app" >&2; exit 1; }
done
# Resolve every runtime dependency inside Arch, including libmount for mount.
ldd_output=$(ldd "${binaries[@]}")
if [[ "$ldd_output" == *"not found"* ]]; then
  printf '%s\n' "$ldd_output" >&2
  exit 1
fi
libs=$(printf '%s\n' "$ldd_output" | awk '!/:$/ && (/=> \/|^[[:space:]]*\//) {for (i=1;i<=NF;i++) if ($i ~ /^\//) print $i}' | sort -u)
for lib in $libs; do
  mkdir -p "$d$(dirname "$lib")"
  cp -L "$lib" "$d$lib"
done
install -m755 /usr/lib/begonia/init "$d/init"
install -m755 /usr/lib/begonia/usb-gadget "$d/usb-gadget"
CHROOT
d="$root/tmp/begonia-initrd"
python3 scripts/create-devices.py "$d"
# Run representative binaries inside the assembled initrd to catch missing loaders.
chroot "$d" /bin/sh -ec '
  for app in mount switch_root blkid mountpoint; do "/bin/$app" --version; done
  for app in sh dmesg sleep cat tee cp sync mkdir grep kill ln; do command -v "$app"; done
  echo initramfs-userspace-ok
' 
find "$d" -exec touch -h -d '@1756983151' {} +
(cd "$d" && find . -print0 | LC_ALL=C sort -z | cpio --null --create --format=newc --owner=0:0 --reproducible) | gzip -n -9 > out/initramfs.cpio.gz
rm -rf "$d"
