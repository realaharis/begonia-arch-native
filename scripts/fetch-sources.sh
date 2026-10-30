#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p work inputs out logs
exec > >(tee logs/fetch.log) 2>&1
readarray -t fields < <(python3 - <<'PY'
import json
s=json.load(open("config/sources.json"))
print(s["kernel"]["url"]); print(s["kernel"]["commit"])
print(s["pmaports"]["config_sha512"]); print(s["rootfs"]["url"])
PY
)
printf '%s  %s\n' "${fields[2]}" config/kernel.config | sha512sum -c -
if [[ ! -d work/linux/.git ]]; then git init work/linux; fi
git -C work/linux fetch --depth=1 "${fields[0]}" "${fields[1]}"
git -C work/linux checkout --detach FETCH_HEAD
test "$(git -C work/linux rev-parse HEAD)" = "${fields[1]}"
git -C work/linux diff --exit-code
git -C work/linux show -s --format=fuller HEAD > out/kernel-source.txt
if [[ "${FETCH_ROOTFS:-1}" = 0 ]]; then exit 0; fi
if [[ ! -s inputs/ArchLinuxARM-aarch64.tar.gz ]]; then
  curl --fail --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 15 --max-time 1800 --retry 2 \
    "${ROOTFS_URL:-${fields[3]}}" -o inputs/rootfs.download
  mv inputs/rootfs.download inputs/ArchLinuxARM-aarch64.tar.gz
fi
if [[ -n "${ROOTFS_SHA256:-}" ]]; then
  [[ "$ROOTFS_SHA256" =~ ^[a-fA-F0-9]{64}$ ]]
  printf '%s  %s\n' "$ROOTFS_SHA256" inputs/ArchLinuxARM-aarch64.tar.gz | sha256sum -c -
else
  echo "INITIAL SNAPSHOT: rootfs digest observed over HTTPS, not independently authenticated."
fi
sha256sum inputs/ArchLinuxARM-aarch64.tar.gz > inputs/SHA256SUMS
cp inputs/SHA256SUMS out/rootfs-input.sha256
