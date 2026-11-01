# Terminal Edition: test and recovery

Do not flash unless the exact run passed every job, SHA256SUMS verifies, and
your panel is confirmed CSOT. This is a candidate, not device-validated software.
Tianma must not be assumed compatible. Preserve a working headless boot/rootfs
pair and an external backup of current Arch files before installing.

## Confirmed partition measurements

boot: /dev/block/sdc34, 67108864 bytes.
userdata: /dev/block/sdc46, 56136531968 bytes.
recovery: /dev/block/sdc1, 67108864 bytes. A-only static layout.
Recheck by-name links and blockdev --getsize64 in TWRP before writing. Never
write to whole /dev/block/sdc, recovery, preloader, nvram, nvdata, persist,
calibration, dtbo or vbmeta. The empty recovery_dtbo is embedded in boot.img;
it is not an instruction to overwrite recovery or dtbo.

## Back up first (TWRP + Bugjaeger shell)

Use an external microSD/USB drive with enough space, not userdata/internal
storage which the rootfs write will destroy. A raw userdata backup needs about
56.2 GB and a filesystem supporting files over 4 GB. Back up boot and userdata
with TWRP's partition backup if it supports the installed layout, or use dd
from the verified by-name device to external storage. Verify backup checksums
and confirm TWRP remains accessible before proceeding. Do not rely on a backup
that exists only on the partition being overwritten.

## Destructive installation: explicit owner approval required

This edition has no verified in-place update package. The userspace changes
include a full signed rolling Arch upgrade and native library dependencies;
copying just UI binaries onto the old root would risk an ABI mismatch.
Writing arch-rootfs-terminal.ext4 replaces ALL current userdata, including
installed Arch and home files. Do not execute these steps without approval.

1. Download the successful run's output artifact and extract it on the second
   phone or external drive. Verify SHA256SUMS. Files are raw, not Android sparse.
2. Enter TWRP; copy the ext4 image to EXTERNAL storage. Unmount userdata (/data
   or any other mount of sdc46). Recheck device identity and partition sizes.
3. In Bugjaeger's recovery shell, substitute the actual external path below.
   Never place the image on /data. After approval only:

   ```sh
   dd if=/EXTERNAL/arch-rootfs-terminal.ext4 of=/dev/block/by-name/userdata bs=4M
   sync
   ```

   Require a successful dd exit and complete byte count. Do not format or
   resize afterward. The 6 GiB filesystem intentionally leaves free partition
   capacity; expansion is a separate operation after successful boot.
4. Reboot to bootloader. In Bugjaeger Fastboot select the boot partition and
   boot-terminal.img (ECM), then flash. Do NOT choose recovery or erase options.
   Equivalent command: fastboot flash boot boot-terminal.img.
   An OKAY reports transfer/write success, not Linux boot success.
5. Reboot. Expect terminal + always-visible keyboard if CSOT display/touch work.
   Allow 90 seconds for DRM discovery. USB/SSH remain independent diagnostics.
   boot-rndis.img is an alternative gadget mode with the same kernel/rootfs;
   neither mode proves compatibility with the second Android phone.

A temporary fastboot boot test can be tried only if the device supports it,
with this rootfs already installed; previous temporary OKAY returning to Android
was not evidence of Arch success. It cannot protect userdata from replacement.

## Acceptance and logs

From terminal run: uname -r; findmnt /; systemctl is-system-running;
systemctl status begonia-local-terminal begonia-seatd; libinput list-devices.
Test typing letters, digits, symbols, Ctrl-C, Tab, Escape, Alt combinations,
all screen corners, portrait alignment, and backlight. Confirm persistent logs.
Use sudo /usr/lib/begonia/collect-logs after failures where possible.
For USB, host must support Ethernet gadget, assign/get 172.16.42.2/24 and reach
172.16.42.1:22. Bugjaeger ADB is not a native Linux shell. Use the owner's existing
private key in an SSH client; never upload it to GitHub. ACM diagnostic output
may help if the host supports it; this is not guaranteed on the second phone.

If the screen stays black, enter TWRP, mount the Arch ext4 partition read-only
at a temporary directory (do not format it), and export /var/log/begonia and
/var/log/journal to the second phone/external storage. Preserve /sys/fs/pstore
if present; an empty pstore is not proof that no kernel failure occurred.

## Rollback

Return to TWRP, unmount userdata, restore the backed-up userdata image/backup
and its matching saved headless boot image. Alternatively restore the original
headless rootfs image (loses later user changes) plus its matching boot image.
Boot-only rollback cannot undo a userspace replacement. Never restore a raw
userdata backup larger than the measured partition. Keep recovery untouched.
For a UI-only failure with otherwise usable new rootfs, disabling
begonia-local-terminal.service from mounted rootfs preserves SSH/headless use;
this is troubleshooting, not a full rollback to the previous installation.
