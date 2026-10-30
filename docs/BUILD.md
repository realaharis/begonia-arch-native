# Build and reproducibility

The workflow uses a native aarch64 Ubuntu runner as a compiler/build host.
It extracts the official Arch rootfs and uses a build-time chroot only to
configure that filesystem. The installed device boots Arch directly.

## Workflow

1. Push validates source and attempts kernel compilation.
2. Manual dispatch also builds images and requires an SSH public key.
3. Inputs are passed through environment variables, not interpolated into shell
   code. Never paste a private key.
4. Kernel and DTB come from one exact commit. The configuration is vendored,
   checked against the upstream SHA512, merged with the headless fragment, then
   checked again after olddefconfig. A dropped dependency fails the build.
5. The initramfs uses Arch's own BusyBox, blkid, mountpoint and their Arch shared
   libraries. Representative commands are executed inside the staged initramfs
   to detect missing interpreters/libraries. UFS, ext4, USB gadget and Type-C
   drivers are required built-ins.
6. Arch's original installed packages are retained; no rolling pacman upgrade is
   performed during image assembly. Unexpected desktops fail validation.
7. The boot image uses AOSP mkbootimg header v2, a real empty DT table container,
   matching DTB and the exact generated initramfs. There are ECM and RNDIS variants.
8. The rootfs is a raw ext4 filesystem labelled ARCHBEGONIA, not an MBR/GPT disk
   image. It is intended for one confirmed partition. This differs intentionally
   from postmarketOS/Kupfer nested partition layouts.

## Input locking

The official URL ends in `latest` and is rolling. The first retrieval records a
SHA256; this is a captured digest, **not independent authenticity verification**.
HTTPS transport is required and HTTP redirects are rejected.

Retain `official-arch-input-RUN_ID`, including the original tarball and digest.
For a repeat build, place the same archive at
`inputs/ArchLinuxARM-aarch64.tar.gz` and set ROOTFS_SHA256 to the saved digest.
The workflow can also check that a subsequent download still matches the supplied
digest; it fails if latest has changed. Artifact retention is only 30 days.

This is an input-recorded pipeline, not a claim of bit-for-bit reproducibility.
Ubuntu runner packages, action tags, filesystem UUIDs/timestamps, and packaging
tool versions are not all immutably pinned. Host/package versions are recorded.
Before a release, mirror the input archives durably, pin toolchain/container and
actions by digest, normalize filesystem metadata and compare independent rebuilds.
GitHub Actions has not run yet.

## Local native ARM builder

Use a fresh isolated ARM64 Linux builder with the packages listed in the workflow.
As root, from the repository root:

```sh
mkdir -p inputs
# Put your SSH public key in inputs/authorized_keys.
bash scripts/build.sh
```

These scripts modify only their staging rootfs and output files, not phone
partitions. Do not execute the target's usb-gadget script on the build host.

## Image checks

```sh
python3 scripts/validate-boot.py out/boot-ecm.img --components out
e2fsck -fn out/arch-rootfs.ext4
(cd out && sha256sum -c SHA256SUMS)
```

After reading the actual boot partition size from the device, additionally pass
`--boot-partition-bytes BYTES`. The provisional 64 MiB ceiling is a development
budget, not a verified size for the user's current partition table.

The validator checks header sizes/addresses, payload bounds, DTB compatibility,
empty DTBO structure, ARM64 kernel magic, cpio structure, aarch64 ELF entries,
Android payload SHA1, and equality with the output components. It does not
validate bootloader AVB policy, DRAM placement at runtime, driver behavior or
systemd boot. Firmware and panel activation remain a later milestone.

## Known implementation limits

* Kernel source compilation and a real Arch initramfs have not yet been tested.
* The official rootfs must include mkinitcpio-busybox, openssh, sudo, util-linux,
  glibc and systemd. Missing dependencies fail rather than silently substituting
  a foreign rootfs.
* The kernel archive is an integration tarball, not yet a pacman-managed kernel
  package. Generic linux-aarch64 updates are held; do not update/replace the
  device kernel until package ownership and recovery hooks are implemented.
* Firmware loading for display/touch is not enabled; no firmware matching is
  guessed from the fact that the phone runs ColorOS.
* Suspend is masked during the diagnostic milestone; power use is not optimized.
* No AVB/vbmeta modification or auto-flashing hook exists.
