# User hardware report, 2026-10-31

Reported by the owner from the existing phone environment, not the new kernel:
- Product begonia, SoC MT6785; bootloader reports unlocked.
- boot 67,108,864 bytes; recovery 67,108,864 bytes.
- userdata 56,136,531,968 bytes; dtbo 33,554,432 bytes.
- boot and userdata currently resolve to sdc34 and sdc46. Do not assume these runtime names in the new kernel.
- Display variant unknown (LCM_name=NONE).
- blkid unavailable in report environment; filesystem type unconfirmed.
- Existing cmdline contains ramoops region 0x4d010000, size 0xe0000. This is evidence for investigation only: do not enable in the new kernel until reserved-memory compatibility is checked.
- pstore was empty. No native Arch boot, USB networking or SSH test yet.

Serial numbers and chip identifiers deliberately omitted.
Current boot image still needed for header inspection; no destructive installation authorized at this stage.

The owner-specific public SSH key is in config/owner-ssh.pub. Its private half is delivered privately, never committed. Push builds now assemble full images; workflow_dispatch can override the public key.
