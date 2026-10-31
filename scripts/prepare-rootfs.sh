#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "Rootfs preparation failed at line $LINENO: $BASH_COMMAND" >&2' ERR
cd "$(dirname "$0")/.."
mkdir -p out logs work/rootfs
exec > >(tee logs/rootfs-prepare.log) 2>&1
[[ $(id -u) = 0 && $(uname -m) = aarch64 ]]
test -s inputs/ArchLinuxARM-aarch64.tar.gz
[[ -z "$(ls -A work/rootfs)" ]] || { echo "Rootfs work directory must be empty"; exit 1; }
root="$PWD/work/rootfs"
bsdtar --acls --xattrs -xpf inputs/ArchLinuxARM-aarch64.tar.gz -C "$root"
grep -Eq '^ID=("?archarm"?)$' "$root/etc/os-release"
# Retain the device-specific kernel while preparing consistent Arch userspace.
mkdir -p "$root/etc/pacman.d"
sed -i '/^\[options\]/a IgnorePkg = linux-aarch64' "$root/etc/pacman.conf"
bash scripts/prepare-rootfs-packages.sh
for f in usr/lib/systemd/systemd usr/sbin/sshd usr/lib/initcpio/busybox usr/bin/blkid usr/bin/visudo; do
  test -x "$root/$f" || { echo "Missing required rootfs binary: $f"; exit 1; }
done
if grep -Eq '^(xorg-server|gnome-shell|plasma-desktop|phosh|xfce4-session) ' out/packages.txt; then
  echo "Unexpected desktop in input rootfs"; exit 1
fi
touch work/rootfs-prepared
