# Phone preparation, installation gates and recovery

**There are currently no built images. The source ZIP is not flashable.
Do only the read-only preparation below.**

Hardware: unlocked begonia; ColorOS 16 custom ROM; TWRP 3.7.1_12-Unified
(wuxinG90); second Android phone with previously tested Bugjaeger ADB/fastboot.
This does not establish compatibility of native USB Ethernet or serial.

## 1. Read-only device report

Boot begonia into the existing TWRP. Keep recovery intact. Connect the second
phone as USB host using the same working OTG/ADB arrangement.

In Bugjaeger's file-transfer interface, upload `scripts/device-probe.sh` from
this source bundle to `/tmp/device-probe.sh` on the TWRP device.
In its ADB shell, run:

```sh
sh /tmp/device-probe.sh > /tmp/begonia-probe.txt 2>&1
```

Download `/tmp/begonia-probe.txt` using Bugjaeger's file interface.
The script reads properties, partition links/sizes, filesystem metadata and
selected driver logs. It never formats, flashes or reads calibration payloads.
Review the report for boot arguments containing device identifiers before sharing.

Also capture the existing boot image for offline header inspection:

```sh
test -b /dev/block/by-name/boot &&
dd if=/dev/block/by-name/boot of=/tmp/current-boot.img bs=1048576 &&
sha256sum /tmp/current-boot.img
```

This is a **read from boot**, writing only a temporary copy in recovery RAM.
If the canonical by-name path is absent, stop and use the report to identify it;
do not replace it with a guessed numerical partition.
Download `/tmp/current-boot.img` to the second phone. It is a backup/analysis
input, not the new Linux image. Temporary /tmp files disappear after reboot.

## 2. Recovery baseline before any destructive test

* Verify the hardware-key combination can enter this existing TWRP and fastboot.
* In TWRP, back up the currently available Boot, Recovery and Android system/data
  components needed to restore ColorOS. Keep the backup on external microSD or
  the second phone, never only in userdata.
* Preserve the original boot, recovery, dtbo and vbmeta images when present.
  Read-only backups of device-specific calibration partitions may also be kept
  privately, but this project must never modify those partitions.
* Retain the known-good ColorOS installation package and exact TWRP image off
  device. A boot-only backup cannot recover Android after userdata replacement.
* Check backup hashes after transfer. Confirm enough battery for a short test;
  charging under the new kernel is unverified.

## 3. Image review gate

Before writing anything, use the probe and original boot header to confirm:

* Device is begonia; exact boot/userdata partition links and measured byte sizes.
* Slot layout and current boot format; do not infer these from ColorOS version.
* Whether fastboot `boot` is supported on this bootloader.
* Whether existing AVB state accepts the candidate. Do not automatically patch
  vbmeta, disable verification, or flash dtbo to work around a refusal.
* Boot image fits the **measured** boot partition and ext4 image fits the
  **measured** intended root partition.
* Source, kernel/config/initramfs consistency, checksums and recovery copies.

Then request approval specifying the exact images, hashes and exact partitions
to be overwritten. The user's general willingness to erase Android does not
replace the requested action-time destructive-operation approval.

## 4. Preferred first test

If supported, a temporary fastboot boot of the small headless image can test
kernel/initramfs/USB without replacing boot or userdata. Without an ARCHBEGONIA
filesystem, the initramfs intentionally times out and repeatedly offers logs
over USB ACM. This is a **narrow diagnostic**, not a successful Arch boot.
No postmarketOS diagnostic distribution is required.

Fastboot temporary boot support has not been established for this phone. If it
is unavailable, do not repeatedly flash alternatives: review a reversible
boot-only test using the saved original boot image and explicit approval.

## 5. Full installation, not authorized yet

After diagnostics and approval, the proposed layout is:

| Image | Intended target | Important distinction |
|---|---|---|
| boot-ecm.img OR boot-rndis.img | Confirmed boot partition | Android-format boot image |
| arch-rootfs.ext4 | Confirmed userdata partition | Raw ext4, not a ZIP or disk image |
| recovery | No change | Existing TWRP is the recovery route |
| preloader/nvram/nvdata/calibration | Never written | Out of scope |

Large raw rootfs transfer is best staged on external microSD. A direct fastboot
flash may encounter sparse/transfer limits; TWRP writing must use the exact
validated target, byte count and hash. Do not rely on TWRP's generic Install
Image screen to expose userdata as a valid target.

Exact destructive commands are intentionally not issued yet: the actual layout,
images and bootloader behavior have not been measured. They must be generated
from those inputs before approval. No installer ZIP is included.

## 6. Communication test from the second phone

On native Linux, Bugjaeger ADB no longer applies.

* ECM is the first candidate; RNDIS is an alternate **separate boot image**.
* The phone must enumerate USB Ethernet as a host, obtain 172.16.42.2, and allow
  an SSH app to reach 172.16.42.1. USB host mode alone does not guarantee this.
* Use the private half of the supplied key in the host's SSH client and connect
  as `alarm`. The build accepts only the public half.
* If Ethernet is unavailable, a USB CDC ACM-capable Android serial application
  may read the diagnostic stream. This is unverified and is not a shell.
* If neither path works, do not erase userdata hoping Wi-Fi will work. Supply
  host-phone model/kernel information and evaluate a supported USB host or
  external adapter as a separate hardware decision.

## 7. Logs and restoration

After a rootfs mount, early logs are copied to `/var/log/begonia`. systemd
journals persist in `/var/log/journal`. Once SSH works:

```sh
sudo /usr/lib/begonia/collect-logs
sudo journalctl -b --no-pager
```

After failure, return to the unchanged TWRP. If it recognizes the new ext4
userdata, mount it read-only. Prefer `ro,noload` for forensic log collection;
ordinary read-only ext4 mounting may replay its journal. Use the **confirmed**
userdata link and an empty temporary mount directory, then copy
`var/log/begonia` and `var/log/journal` to external storage.
Do not format when TWRP offers to repair an unfamiliar filesystem.

For a boot-only test, restore the saved original boot image to its original boot
partition via TWRP Restore/Install Image, after verifying the exact backup and
target. If userdata was replaced, restore the full previously verified Android
backup or reinstall the retained known-good ROM using its recovery procedure;
restoring boot alone is insufficient. Do not restore random firmware/preloader
images or relock the bootloader.

If a crash happens before USB and storage work, this build has no verified
reliable log channel. PSTORE configuration alone does not fix this: no ramoops
memory region has been validated. This remains an explicit milestone blocker.
