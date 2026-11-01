# Native Arch Linux ARM for Xiaomi Redmi Note 8 Pro

This branch develops an **experimental CSOT Terminal Edition**: native Arch
Linux ARM, device-specific Linux, Sway, foot and an always-visible wvkbd.
No Android runtime, proot or alternate distribution is used on the phone.

The owner has verified kernel/initramfs, ext4 root, systemd and sshd on-device.
USB gadget is partial; second-phone networking, display and touch remain
unverified. A successful Actions run proves build/software checks only.

See [Terminal Edition report](docs/TERMINAL_REPORT.md) and
[installation/rollback instructions](docs/TERMINAL_INSTALL.md).
Check the exact commit's Actions result before downloading images.
Installing the full rootfs overwrites userdata and requires explicit approval.
TWRP and calibration partitions must remain untouched.

Older headless documentation below is historical and does not describe this
branch's graphical package set. Preserve a matching headless boot/rootfs backup.

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
