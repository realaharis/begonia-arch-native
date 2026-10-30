# Compatibility and stack selection

As of 2026-10-30, **no feature is verified on Ahmad's device**.
Source support is not the same as hardware success.

| Candidate | Evidence inspected | Decision |
|---|---|---|
| postmarketOS downstream 4.14.218 | Archived downstream packaging, old Android kernel | Not selected for modern Arch/systemd baseline |
| MT6785 mainline 6.16.4 | Actual matching DTS, Kconfig and device packaging | Selected for bounded headless baseline |
| Droidian begonia | Adaptation tree with Android mount services, vendor overlays, RIL and Droid audio configuration | Useful hardware reference; cannot transplant its full Android-dependent integration as native Arch |
| Community begonia Kupfer | Pinned repository read; kernel/firmware recipes and documented CI checks | Useful reference; README explicitly marks flashing/device validation pending |
| Kupfer connectivity-forward-port fork | Recipe pins minorum kernel 3a1ea7694219eb2fd513f0e630f2a882eab5c86f, firmware 33aa9fe1db0079945fa272e42f04db732489319d | Deferred; added vendor WLAN complexity and no proven device acceptance in inspected report |

This selects the most defensible inspected baseline for **headless boot**, not
the universally most complete phone stack. The available evidence does not
justify that broader claim. The primary postmarketOS wiki/GitLab endpoints could
not be read; inspected GitHub mirrors preserve source commits but are not claims
of current upstream endorsement.

| Feature | Selected-source evidence | Project status / next test |
|---|---|---|
| CPU / kernel boot | ARM64 MT6785 tree with begonia compatible | Untested; collect first kernel/USB output |
| UFS storage | Enabled ufshci and PHY; UFS MediaTek/SCSI drivers built in | Untested; identify partitions without hard-coded numbers |
| Root read/write | ext4 built in; labelled raw rootfs path | Untested; persistent write and reboot test |
| USB device | Enabled ssusb, MTU3, role switch and MT6360 Type-C | Untested; UDC enumeration and both phone host drivers |
| USB Ethernet / SSH | Configfs ECM or RNDIS; networkd DHCP server; SSH key-only | Untested; Android USB host support is a blocker until measured |
| USB serial diagnostics | ACM function and read-only journal stream | Untested; compatible host serial app required |
| Display | DTS explicitly names CSOT Novatek NT36672A panel | Deferred / untested; actual panel variant unknown |
| Touch | DTS requests novatek/nt36672a_begonia_csot.bin | Deferred / untested; do not substitute Tianma firmware blindly |
| Tianma variation | Kupfer author reports firmware-name substitution on their own phone | Partial external evidence only, not verified on user's phone |
| Internal Wi-Fi | Selected baseline does not integrate Kupfer's WMT/gen4m fork | Unsupported by this baseline; later work |
| GPU | DTS enables Mali GPU; Panfrost config exists | Deferred / untested; no acceleration claim |
| Battery capacity | No complete battery gauge integration established in inspected DTS | Untested; distinguish gauge from charger |
| Charging | MT6360 charger and USB-C power role nodes | Untested; never infer safe charging from driver presence |
| Audio | Droidian uses Android/Droid audio configuration | Unsupported by baseline; native path not established |
| Internal Bluetooth | Kupfer author reports missing HCI integration | Unsupported by baseline |
| Sensors | Some proximity/magnetometer/IMU nodes exist | Untested; not a milestone dependency |
| Cameras / modem / GPS / fingerprint | Not enabled by this project | Unsupported by baseline |
| Persistent crash logs | PSTORE/RAM configured, but no ramoops reservation found in inspected DTS/DTSI | Unverified; no invented reserved RAM or partition |

## Boot layout derived from source

Android boot header v2; page size 2048; no second payload. Base 0x40078000,
kernel address 0x40080000, ramdisk 0x47c80000, tags and DTB 0x4bc80000.
An empty DT table is required as recovery_dtbo inside the boot image.
This is **not** a request to flash the phone's dtbo partition.
`bootopt=64S3,32N2,64N2` comes from the device's kernel-cmdline.conf.

The device packaging uses 4096-byte rootfs image sectors for UFS. Our raw ext4
filesystem uses 4096-byte filesystem blocks and does not embed another partition
table. Neither userdata partition number, size, filesystem state, A/B layout,
AVB behavior nor temporary fastboot boot support is assumed from another phone.
The current ColorOS boot image and read-only TWRP report must be inspected.
