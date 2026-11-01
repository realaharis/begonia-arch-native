#!/usr/bin/env bash
set -Eeuo pipefail
root="$PWD/work/rootfs"
release=$(cat out/kernel.release)
python3 scripts/check-config.py out/kernel.config config/headless.fragment
f=usr/lib/firmware/novatek/nt36672a_begonia_csot.bin
test -s "$root/$f"
cmp "work/firmware/nt36672a_begonia_csot.bin" "$root/$f"
test "$(fdtget out/begonia.dtb /soc/spi@11019000/touchscreen@0 firmware-name 2>/dev/null || dtc -I dtb -O dts out/begonia.dtb 2>/dev/null | sed -n 's/.*firmware-name = "\(.*\)";.*/\1/p')" = novatek/nt36672a_begonia_csot.bin
find "work/kernel-package/usr/lib/modules/$release" -name '*.ko' -print0 | while IFS= read -r -d '' module; do
  test "$(modinfo -F vermagic "$module" | cut -d' ' -f1)" = "$release"
  cmp "$module" "$root/${module#work/kernel-package/}"
done
systemctl --root="$root" is-enabled begonia-local-terminal.service
systemctl --root="$root" is-enabled begonia-seatd.service
# Arch seatd (0.9.x) no longer accepts -s; its socket is compiled at /run/seatd.sock.
grep -Fxq "ExecStart=/usr/bin/seatd -g video" "$root/usr/lib/systemd/system/begonia-seatd.service"
grep -Fxq "Environment=SEATD_SOCK=/run/seatd.sock" "$root/usr/lib/systemd/system/begonia-local-terminal.service"
# A physical DRM session must have an actual controlling VT and login PAM session.
grep -Fxq "PAMName=login" "$root/usr/lib/systemd/system/begonia-local-terminal.service"
grep -Fxq "TTYPath=/dev/tty1" "$root/usr/lib/systemd/system/begonia-local-terminal.service"
grep -Fxq "StandardInput=tty" "$root/usr/lib/systemd/system/begonia-local-terminal.service"
test "$(stat -c%s out/arch-rootfs.ext4)" -lt 56136531968
test -z "$(find "$root/etc/ssh" -name 'ssh_host_*_key' -print)"
printf 'PASS: exact modules, firmware/DT name, Kconfig, services, partition bounds, no SSH host private keys\n' | tee out/terminal-validation.txt
