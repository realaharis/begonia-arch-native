# Local touchscreen terminal bring-up (experimental)

Target: begonia / MT6785, retain the known-working headless boot image and SSH diagnostics.
This branch is **not yet a flashable graphical release**.

## Confirmed from on-device logs
- /init ran; labelled userdata ext4 mounted as /dev/sdc46.
- systemd reached login target; sshd listened on TCP 22.
- display was black; the second Android phone was powered by begonia and did not enumerate a USB device.
- /var/log/begonia logs exist, but timestamps must be checked before attribution to a particular boot.

## Hardware blockers
1. Identify the actual DSI panel variant (CSOT/Huaxing vs Tianma). The current DTS references CSOT Novatek NT36672A; variant mismatches can leave the screen black.
2. Verify the MTK DRM/DSI host and backlight probe in the built kernel; a generic NT36672A driver alone does not guarantee this panel's init sequence works.
3. Identify SPI touch controller and exact firmware; `novatek/nt36672a_begonia_csot.bin` is referenced by source but not verified present or functioning on the device.
4. Enable kernel `CONFIG_VT`, `CONFIG_VT_CONSOLE`, `CONFIG_FRAMEBUFFER_CONSOLE`, `CONFIG_DRM_FBDEV_EMULATION`, MediaTek DRM/DSI, panel and input/touch drivers only after checking their dependencies in the pinned kernel.
5. Once /dev/dri/card* and /dev/input/event* are verified, use a compositor (Weston or another wlroots-compatible one), a terminal (foot), and a **compatible Wayland on-screen keyboard**. Squeekboard is a candidate, but interaction with the chosen compositor requires integration tests, not a package install alone.

## Read-only recovery probe from TWRP
```sh
cat /data/var/log/begonia/init-*.log
ls -lah /data/var/log/begonia/
grep -iE 'drm|dsi|panel|backlight|touch|novatek|firmware|input|fbcon' /data/var/log/begonia/dmesg-*.txt | tail -n 100
```

## Safety and acceptance
- Do not erase userdata: the installed rootfs is demonstrably valid.
- Do not flash dtbo, preloader, nvram, nvdata or recovery.
- The first display-enabled boot should be a boot-only flash after independently verifying the image fits the 64 MiB boot partition, recording its SHA256, and keeping the working headless boot.img and recovery.
- Confirm display/backlight, real touch events and on-screen keyboard input *on device* before claiming a usable local terminal.
