# Headless acceptance: real hardware only

No checkbox below has been completed. CI success is only build evidence.

Record the exact build commit, kernel/config hashes, boot/rootfs hashes,
device model, current bootloader state and host-phone model for each test.

| Gate | Required evidence |
|---|---|
| Bootloader handoff | Kernel/initramfs output from actual begonia |
| Correct kernel | uname output matches out/kernel.release |
| Arch userspace | /etc/os-release identifies Arch Linux ARM |
| systemd PID 1 | ps -p 1 -o comm= prints systemd |
| Intended target | systemctl is-active multi-user.target prints active |
| Rootfs | findmnt / shows ext4 and rw, correct labelled partition |
| Persistence | Create a marker, sync, reboot and read it back |
| UFS | lsblk, sysfs and dmesg identify operational internal storage |
| USB | UDC state, host enumeration and usable function |
| Remote shell | Authenticated SSH session from the second phone |
| Boot logs | Kernel and systemd logs captured and reviewed |
| Failed-boot recovery | Re-enter TWRP and retrieve logs from a controlled failure |
| Recovery baseline | Demonstrate restore path before advancing to desktop |

Suggested commands after SSH access:

```sh
uname -a
cat /etc/os-release
ps -p 1 -o comm=
systemctl is-active multi-user.target
systemctl --failed
findmnt -no SOURCE,FSTYPE,OPTIONS /
lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTLABEL,MOUNTPOINTS
ip -br address
sudo sh -c 'date -u > /var/log/begonia/persistence-marker; sync'
sudo /usr/lib/begonia/collect-logs
```

Reboot once, reconnect and read the marker and prior journal. Stop on storage
errors, unexpected resets, charger/thermal errors or recovery failure.

Only after these gates pass: identify the actual CSOT/Tianma variant; enable
display/touch with matched firmware; evaluate Wi-Fi separately; test charge
current/temperature and battery gauge; then GPU, audio, Bluetooth and sensors.
Keep the headless image and its exact rootfs/kernel inputs as the diagnostic
baseline. A separate desktop image is not created before stable headless boot.
