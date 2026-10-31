#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
root="$PWD/work/rootfs"
[[ $(id -u) = 0 && $(uname -m) = aarch64 ]]
test -x "$root/usr/bin/pacman"
# Use a private mount namespace: never leave builder mounts in the image.
if [[ ${BEGONIA_MOUNT_NAMESPACE:-0} != 1 ]]; then
  exec unshare --mount --propagation private env BEGONIA_MOUNT_NAMESPACE=1 bash "$0"
fi
cleanup() {
  local status=$? cleanup_failed=0
  trap - EXIT
  set +e
  # pacman-key may leave gpg-agent holding /dev open.
  chroot "$root" /usr/bin/gpgconf --homedir /etc/pacman.d/gnupg --kill all
  for dir in run sys proc dev; do
    if mountpoint -q "$root/$dir"; then
      umount -R "$root/$dir" || cleanup_failed=1
    fi
  done
  rm -f "$root/etc/resolv.conf"
  if [[ -e "$root/etc/resolv.conf.build-save" || -L "$root/etc/resolv.conf.build-save" ]]; then
    mv "$root/etc/resolv.conf.build-save" "$root/etc/resolv.conf" || cleanup_failed=1
  fi
  if mountpoint -q "$root"; then
    umount "$root" || cleanup_failed=1
  fi
  # Preserve the original transaction error; never package a mounted tree.
  if (( status == 0 && cleanup_failed != 0 )); then status=1; fi
  exit "$status"
}
trap cleanup EXIT
# A real root mount is required for pacman's CheckSpace mount-table lookup.
mount --bind "$root" "$root"
if [[ -e "$root/etc/resolv.conf" || -L "$root/etc/resolv.conf" ]]; then
  mv "$root/etc/resolv.conf" "$root/etc/resolv.conf.build-save"
fi
cp -L /etc/resolv.conf "$root/etc/resolv.conf"
mkdir -p "$root"/{dev,proc,sys,run}
mount --rbind /dev "$root/dev"
mount --make-rslave "$root/dev"
mount -t proc proc "$root/proc"
mount --rbind /sys "$root/sys"
mount --make-rslave "$root/sys"
mount -t tmpfs tmpfs "$root/run"
# Same official HTTPS mirrors as the rootfs downloader; package signatures stay enabled.
cat > "$root/etc/pacman.d/mirrorlist" <<'MIRRORS'
Server = https://ca.us.mirror.archlinuxarm.org/$arch/$repo
Server = https://fl.us.mirror.archlinuxarm.org/$arch/$repo
Server = https://nj.us.mirror.archlinuxarm.org/$arch/$repo
MIRRORS
chroot "$root" /usr/bin/pacman-key --init
chroot "$root" /usr/bin/pacman-key --populate archlinuxarm
# Upgrade the userspace consistently rather than mixing a new sudo with old libraries.
chroot "$root" /usr/bin/findmnt -T /var/cache/pacman/pkg
chroot "$root" /usr/bin/df -h / /var/cache/pacman/pkg
chroot "$root" /usr/bin/pacman -Syu --needed --noconfirm sudo openssh mkinitcpio util-linux
for file in sudo visudo ssh-keygen mountpoint blkid; do
  test -x "$root/usr/bin/$file" || { echo "Missing required Arch binary: $file" >&2; exit 1; }
done
mkdir -p out
chroot "$root" /usr/bin/pacman -Q > out/packages.txt
# Keep exact downloaded packages for auditing/reconstruction of this rolling transaction.
tar -C "$root/var/cache/pacman/pkg" -cf inputs/arch-package-inputs.tar .
sha256sum inputs/arch-package-inputs.tar > out/package-inputs.sha256
