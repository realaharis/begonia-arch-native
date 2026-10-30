# Native Arch Linux ARM for Xiaomi Redmi Note 8 Pro

**Engineering checkpoint, 2026-10-30. No flashable image has been built or
tested. Do not install this ZIP through TWRP: it contains source, not a recovery
installer.**

The target is native aarch64 Arch Linux ARM, booting the MT6785 Linux kernel
directly into systemd. No Android runtime, chroot, proot, emulation, Debian,
Alpine, or postmarketOS installation is part of the phone runtime.

The first milestone is headless. Display, touchscreen, Wi-Fi, GPU, audio and
desktop work are deliberately deferred until boot, storage and communication
have been verified on the actual device.

## Current evidence

| Item | Status |
|---|---|
| Kernel/config/DTB source selection | Pinned and source-inspected |
| Kernel config SHA512 | Matches pmaports APKBUILD |
| Validator tests | 10 passed locally |
| Independent AOSP boot packaging cross-check | Passed with synthetic payloads |
| Shell/Python syntax checks | Passed locally |
| Full build attempt | Stopped during source fetch: network timeout |
| GitHub repository | realaharis/begonia-arch-native |
| GitHub Actions run | Initial kernel CI being configured; see Actions for current result |
| Official Arch rootfs download | Attempted; blocked by network timeout |
| Compiled kernel / boot.img / rootfs image | Not produced |
| Real-device boot / USB / SSH | Untested |
| Headless milestone | Not achieved |

## Source selection

* MT6785 mainline fork, tag 6.16.4-r0, commit
  `203a993f86cdd71d2936ee0f301f733f5a15afcd`.
* Matching `mt6785-xiaomi-begonia.dtb` built from that same checkout.
* pmaports kernel configuration pinned to
  `8f2c59fa9a74adadd89e7a0069adc1efa0e7b909`, plus an auditable headless fragment.
* Official Arch Linux ARM generic aarch64 root filesystem; input capture and
  SHA256 retention, without installing any other distribution.
* No proprietary touchscreen or experimental connectivity blob is injected
  into this headless baseline. Generic firmware already in the official rootfs
  is inventoried.

See [hardware report](docs/HARDWARE.md), [sources and licenses](docs/SOURCES.md),
[build instructions](docs/BUILD.md), [phone preparation and recovery](docs/PHONE.md)
and [acceptance tests](docs/ACCEPTANCE.md).

## Expected build outputs, once CI succeeds

`boot-ecm.img`, `boot-rndis.img`, `arch-rootfs.ext4`,
`kernel-modules.tar.xz`, `Image.gz`, matching DTB, initramfs, SHA256SUMS,
configuration, source metadata, package/firmware inventory and build logs.
They remain development images until measured partition checks and device tests.

USB Ethernet is configured at 172.16.42.1/24 with a single-client DHCP pool.
SSH is key-only as `alarm`; that account has administrative sudo access.
A read-only USB ACM journal stream provides an alternate diagnostic channel.
Neither host-phone Ethernet support nor ACM compatibility has been verified.
Bugjaeger is used only for Android/recovery ADB and fastboot; native ADB is absent.

## Immediate continuation

Repository: https://github.com/realaharis/begonia-arch-native

Pushes run validation and kernel compilation without requiring an SSH key or
downloading a rootfs. Manual image builds additionally capture the official
Arch rootfs and require an SSH public key.

For the image build, supply an SSH **public** key. Run the read-only probe in
TWRP and retain boot/recovery backups off the phone before considering writes.
No destructive operation is approved by this source bundle.
