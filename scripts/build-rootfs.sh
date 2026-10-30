#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out logs work/rootfs
exec > >(tee logs/rootfs.log) 2>&1
[[ "$(id -u)" = 0 ]] || { echo "Run on an isolated root-capable builder"; exit 1; }
[[ "$(uname -m)" = aarch64 ]] || { echo "Native aarch64 builder required"; exit 1; }
[[ -s inputs/authorized_keys ]] || { echo "Supply an SSH PUBLIC key in inputs/authorized_keys"; exit 1; }
ssh-keygen -lf inputs/authorized_keys
test -s out/kernel.release
test -s inputs/ArchLinuxARM-aarch64.tar.gz
[[ -z "$(ls -A work/rootfs)" ]] || { echo "Rootfs work directory must be empty"; exit 1; }
root="$PWD/work/rootfs"
bsdtar --acls --xattrs -xpf inputs/ArchLinuxARM-aarch64.tar.gz -C "$root"
grep -Eq '^ID=("?archarm"?)$' "$root/etc/os-release"
for f in usr/lib/systemd/systemd usr/sbin/sshd usr/lib/initcpio/busybox usr/bin/blkid; do
  test -x "$root/$f"
done
# The host is aarch64; chroot is a build-time packaging tool only.
# The final phone boots this filesystem directly, without Android or containers.
chroot "$root" /usr/bin/pacman -Q > out/packages.txt
if grep -Eq '^(xorg-server|gnome-shell|plasma-desktop|phosh|xfce4-session) ' out/packages.txt; then
  echo "Unexpected desktop in input rootfs"; exit 1
fi
# Retain the generic package database, but never use its kernel for the phone.
# Prevent upgrades silently replacing the tested kernel payload.
mkdir -p "$root/etc/pacman.d"
sed -i '/^\[options\]/a IgnorePkg = linux-aarch64' "$root/etc/pacman.conf"
cp -a work/kernel-package/usr/lib/modules/. "$root/usr/lib/modules/"
cp out/Image.gz "$root/boot/Image-begonia.gz"
mkdir -p "$root/boot/dtbs/mediatek"
cp out/begonia.dtb "$root/boot/dtbs/mediatek/mt6785-xiaomi-begonia.dtb"
cp -a overlay/. "$root/"
sed -i '1i Include /etc/ssh/sshd_config.d/00-begonia.conf' "$root/etc/ssh/sshd_config"
chmod 755 "$root/usr/lib/begonia/"*
install -Dm755 initramfs/init "$root/usr/lib/begonia/init"
install -Dm600 inputs/authorized_keys "$root/home/alarm/.ssh/authorized_keys"
chroot "$root" chown -R alarm:alarm /home/alarm/.ssh
chmod 700 "$root/home/alarm/.ssh"
chroot "$root" passwd -l root
# '*' disables password authentication without OpenSSH's leading-'!' lock.
chroot "$root" usermod -p '*' alarm
install -d -m750 "$root/etc/sudoers.d"
printf 'alarm ALL=(ALL:ALL) NOPASSWD: ALL\n' > "$root/etc/sudoers.d/10-alarm"
chmod 440 "$root/etc/sudoers.d/10-alarm"
chroot "$root" visudo -cf /etc/sudoers.d/10-alarm
printf 'begonia-arch\n' > "$root/etc/hostname"
printf 'LABEL=ARCHBEGONIA / ext4 defaults,noatime 0 1\n' > "$root/etc/fstab"
units=(sshd.service systemd-networkd.service begonia-usb.service begonia-logs.service begonia-ssh-keys.service begonia-serial-log.service)
for unit in "${units[@]}"; do
  test -f "$root/usr/lib/systemd/system/$unit"
done
systemctl --root="$root" enable "${units[@]}"
ln -sfn /usr/lib/systemd/system/multi-user.target "$root/etc/systemd/system/default.target"
# No display/touch probe or firmware substitution in the headless baseline.
mkdir -p "$root/etc/modprobe.d" "$root/var/log/journal" "$root/var/log/begonia"
printf '%s\n' 'blacklist panel_novatek_nt36672a' 'blacklist novatek_nvt_ts_spi' 'blacklist panfrost' > "$root/etc/modprobe.d/begonia-headless.conf"
mkdir -p "$root/etc/systemd/system"
for unit in sleep.target suspend.target hibernate.target hybrid-sleep.target; do
  ln -sfn /dev/null "$root/etc/systemd/system/$unit"
done
# New host identity on the actual device. Do not distribute SSH private keys.
rm -f "$root/etc/ssh/ssh_host_"* "$root/etc/machine-id" "$root/var/lib/dbus/machine-id"
touch "$root/etc/machine-id"
ln -s /etc/machine-id "$root/var/lib/dbus/machine-id"
chroot "$root" /usr/bin/ssh-keygen -A
chroot "$root" /usr/bin/sshd -t
rm -f "$root/etc/ssh/ssh_host_"*
chroot "$root" /usr/bin/depmod "$(cat out/kernel.release)"
bash scripts/build-initramfs.sh
size="${ROOTFS_MIB:-4096}"
cp out/packages.txt "$root/var/log/begonia/build-packages.txt"
[[ "$size" =~ ^[0-9]+$ ]] && ((size >= 2048 && size <= 16384))
truncate -s "${size}M" out/arch-rootfs.ext4
# Raw ext4 in userdata, with no nested partition table; block size suits UFS.
mkfs.ext4 -F -b 4096 -L ARCHBEGONIA -m 0 \
  -O ^metadata_csum_seed,^orphan_file \
  -E lazy_itable_init=0,lazy_journal_init=0 -d "$root" out/arch-rootfs.ext4
e2fsck -fn out/arch-rootfs.ext4
test "$(blkid -p -s LABEL -o value out/arch-rootfs.ext4)" = ARCHBEGONIA
test "$(blkid -p -s TYPE -o value out/arch-rootfs.ext4)" = ext4
cp config/sources.json out/sources.json
find "$root/usr/lib/firmware" -type f -printf '%P\n' > out/firmware-inventory.txt
