# Source revisions, provenance and licensing

## Selected source

* Kernel: https://gitlab.postmarketos.org/mt6785-mainline/linux
* Inspected mirror: https://github.com/external-mirrors/mt6785-mainline-linux
* Tag 6.16.4-r0 resolves to commit
  203a993f86cdd71d2936ee0f301f733f5a15afcd.
* Kernel license: GPL-2.0-only, with per-file exceptions/dual licenses.
  The begonia DTS explicitly declares GPL-2.0 OR MIT and credits Dinolek.
* Configuration/device packaging mirror:
  https://github.com/external-mirrors/pmaports/tree/8f2c59fa9a74adadd89e7a0069adc1efa0e7b909
* Paths: device/testing/linux-postmarketos-mediatek-mt6785/ and
  device/testing/device-xiaomi-begonia/.
* The vendored kernel.config SHA512 is checked against the actual APKBUILD.
  The pmaports repository has GPL-3.0 licensing; device package metadata says
  MIT, kernel package metadata says GPL-2.0-only. Preserve upstream licensing;
  the original-project MIT license is not a relicensing of those inputs.

## Arch Linux ARM

* https://archlinuxarm.org/platforms/armv8/generic
* https://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
* Official aarch64 base rootfs, glibc, pacman, systemd and openssh.
* Per-package licenses apply, recorded via the installed package inventory.
* https://archlinuxarm.org/packages/aarch64/mkinitcpio-busybox documents the
  initramfs tools and their glibc/libxcrypt dependencies.
* Rootfs was not downloaded in this session. No SHA256 has been invented.

## Firmware

* https://gitlab.postmarketos.org/mt6785-mainline/firmware
* pmaports-pinned revision d62a654f9f84344571cbf5a306d33869d49aa70b.
* Package license is proprietary. Redistribution terms have not been established.
* The firmware reference is documented but blobs are not bundled.
* CSOT firmware belongs to the selected DTS. The user's panel is unknown.
  Touchscreen/GPU/display are not needed for the proposed headless milestone.

## Comparison sources (not incorporated as runtime packages)

* https://github.com/begonia-linux/adaptation-xiaomi-begonia/tree/droidian
  Android/vendor service and mount integration inspected.
* https://github.com/begonia-linux/droidian-xiaomi-begonia
* https://github.com/criollojoel10/begonia-kupfer-linux/tree/116f89e9cdbccfb6a4780672306f2efd706aa57b
  README, device configuration and kernel/firmware recipes inspected.
  License for reuse was not established; no substantial code from that repository
  is redistributed in this bundle. Its device-testing claims remain third-party.
* https://github.com/Hari-Pi/realme6-pmos-port
  Same-SoC precedent only; its Realme DTB must never be used for begonia.

## Format / diagnostics references

* https://source.android.com/docs/core/architecture/bootloader/boot-image-header
* https://docs.kernel.org/usb/gadget_configfs.html
* https://docs.kernel.org/admin-guide/pstore-blk.html
* https://sisik.eu/bugjaeger_faq and https://sisik.eu/bugjaeger document
  file transfer and the already-open ADB shell (do not prefix shell commands
  with adb).
* AOSP mkbootimg mirror used for local differential packaging validation:
  https://github.com/LineageOS/android_system_tools_mkbootimg/tree/808ecd09666ffe0ff5800f02af693abce56eb395
  mkbootimg.py and gki/generate_gki_certificate.py are now vendored unmodified
  under tools/mkbootimg with the Apache-2.0 license. Both the synthetic
  packaging cross-check and production image assembly use this pinned version.

## Build status and distribution obligations

No kernel/rootfs binaries are distributed in this checkpoint. If binaries are
published later, retain their complete corresponding kernel source, applied
patches, config and build instructions; comply with each package's source/license
obligations. A mutable branch URL alone is insufficient source preservation.
