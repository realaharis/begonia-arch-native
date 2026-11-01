# Terminal Edition engineering report

Status: experimental CSOT candidate; CI results belong to the exact Actions run,
not a declaration of physical display/touch success.

## Sources and compatibility

Kernel and DT: mt6785-mainline Linux 6.16.4-r0 commit
203a993f86cdd71d2936ee0f301f733f5a15afcd, GPL-2.0-only.
Configuration and firmware recipe were compared with pmaports commit
8f2c59fa9a74adadd89e7a0069adc1efa0e7b909, packages
linux-postmarketos-mediatek-mt6785, device-xiaomi-begonia and
firmware-xiaomi-begonia-touchscreen. GitLab MR6975 discussion was inaccessible
behind Anubis during this review; pinned mirrored source was inspected instead.
No postmarketOS rootfs is used. Arch Linux ARM remains the booted distribution.

The existing kernel already contains MediaTek DRM/MIPI DSI and Novatek drivers.
The DT explicitly selects xiaomi,begonia-csot-nt36672a, with LM36274 backlight
and SPI Novatek touchscreen. The exact firmware request is
novatek/nt36672a_begonia_csot.bin. The firmware archive is pinned to
 d62a654f9f84344571cbf5a306d33869d49aa70b and checked against the pmaports
SHA512. Its .zst file is decompressed into /usr/lib/firmware/novatek/.
Touch drivers are modules so probing occurs after rootfs firmware is available.
Firmware is proprietary; an open-source redistribution license has not been
established. Its provenance and unmodified source archive are retained.
The same panel driver also contains Tianma/beryllium entries; these are not
evidence for a begonia Tianma variant. No Tianma DT or firmware combination
is selected or claimed compatible. The CSOT mode is 1080 x 2340.
The owner's old LCM_name=NONE does not identify the installed panel.

Sway + foot + wvkbd use software rendering (pixman). GPU acceleration is not
claimed. Sway runs as alarm with PAM login and a physical tty1 controlling session; seatd grants DRM/input access. This VT binding is validated structurally in CI but must still be exercised on begonia hardware. wvkbd commit
f7e9ea3a7565decd0d120861c1cb36a7b6836244 (v0.21, GPLv3) is built natively
from retained source. It uses virtual-keyboard-v1 plus layer-shell, stays
visible and reserves screen space. foot is tiled, not fullscreen. This avoids
relying on text-input popup support. Full/special/nav/Persian layers include
letters, numbers, symbols, Ctrl, Alt, Escape, Tab and Enter. Layer switching
uses the keyboard key. Shift+space also produces Tab. Physical usability and
orientation remain device tests. Default is native portrait at scale 2, touch
mapped to DSI-1; verify the actual connector name in logs.

## Verification gates

CI: strict Kconfig after olddefconfig; full kernel/DT/modules compile; every
module vermagic and installed byte identity; firmware hash/DT request; signed
Arch package transaction; real aarch64 chroot execution; headless Sway runs
foot and wvkbd, verifies both Wayland protocols, sends a synthetic command using wtype through the
virtual-keyboard protocol and checks shell output (not a simulated tap on wvkbd); services enabled; ext4
fsck/label; Android v2 component/address validation and measured boot bound.
Headless compositor testing does not exercise MediaTek DRM or physical input.

The previous successful run 41245751321 did not install touch firmware or an
OSK. Its package warnings included ignored generic linux-aarch64 upgrade,
mkinitcpio architecture hook and generic privacy-screen module warnings. These
are distinct from device kernel compilation; this project builds its own
initramfs. The new run's complete logs remain authoritative. Seatd 0.9.x in Arch has its socket path compiled in and does not accept `-s`; the service now uses the default /run/seatd.sock, and CI validates the matching Sway environment.

## Hardware matrix

| Feature | Evidence/status |
|---|---|
| Native kernel, ext4 root, systemd, sshd | Previously device-verified by owner |
| USB gadget/usb0 | Partial; second-phone link unverified |
| CSOT display/backlight | Drivers/DT integrated; device untested |
| Novatek CSOT touch | Exact firmware integrated; device untested |
| Tianma panel | Unsupported by this selected DT; identification required |
| Terminal + OSK | CI software test required; physical touch untested |
| Wi-Fi, Bluetooth, audio, sensors | Untested, not enabled by this edition |
| GPU acceleration | Disabled pending hardware testing |
| Charging/battery | Existing kernel stack; safety/power behavior unverified |

Reproducibility: kernel/config/keyboard/firmware pinned, exact Arch input and
package cache retained. Arch packages are a recorded rolling transaction;
builder packages, filesystem UUIDs/timestamps prevent bit-identical claims.
No private SSH key is intentionally packaged. Existing owner public key is
retained. Local terminal is an unlocked engineering console with passwordless
sudo; possession of the phone provides local administrative access.
