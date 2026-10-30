#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out logs
exec > >(tee logs/boot-image.log) 2>&1
printf '/dts-v1/; / { };\n' | dtc -I dts -O dtb -o out/empty.dtb
python3 - <<'PY'
import struct
from pathlib import Path
b=Path("out/empty.dtb").read_bytes()
# Android dt_table_header and one dt_table_entry; all fields are big endian.
hdr=struct.pack(">8I",0xd7b7ab1e,64+len(b),32,32,1,32,2048,0)
entry=struct.pack(">8I",len(b),64,0,0,0,0,0,0)
Path("out/empty.dtbo").write_bytes(hdr+entry+b)
PY
for mode in ecm rndis; do
  mkbootimg --header_version 2 --base 0x40078000 \
    --kernel_offset 0x00008000 --ramdisk_offset 0x07c08000 \
    --second_offset 0xbff88000 --tags_offset 0x0bc08000 --dtb_offset 0x0bc08000 \
    --pagesize 2048 --kernel out/Image.gz --ramdisk out/initramfs.cpio.gz \
    --dtb out/begonia.dtb --recovery_dtbo out/empty.dtbo \
    --cmdline "bootopt=64S3,32N2,64N2 root=LABEL=ARCHBEGONIA rw loglevel=7 ignore_loglevel panic=0 systemd.unit=multi-user.target arch.usb=$mode" \
    --output "out/boot-$mode.img"
  python3 scripts/validate-boot.py "out/boot-$mode.img" --components out > "out/validation-$mode.json"
done
# Development ceiling only. Measured boot-partition size is checked separately.
(cd out && sha256sum Image.gz begonia.dtb initramfs.cpio.gz empty.dtbo boot-*.img arch-rootfs.ext4 kernel-modules.tar.xz > SHA256SUMS)
python3 scripts/manifest.py
