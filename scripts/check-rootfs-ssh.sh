#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD/work/rootfs"
# These are temporary host keys for configuration validation only.
trap 'rm -f "$root/etc/ssh/ssh_host_"*' EXIT
mkdir -p "$root/run/sshd"
chroot "$root" /usr/bin/ssh-keygen -A
chroot "$root" /usr/bin/sshd -t
