#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p inputs out
readarray -t urls < <(python3 - <<'PY'
import json, os
s = json.load(open('config/sources.json'))['rootfs']
# An explicit override must not silently fall back to a different snapshot.
print('\n'.join([os.environ['ROOTFS_URL']] if os.environ.get('ROOTFS_URL')
                else [s['url'], *s.get('fallback_urls', [])]))
PY
)
trap 'rm -f inputs/rootfs.download out/rootfs-effective-url.tmp' EXIT
for url in "${urls[@]}"; do
  echo "Downloading official Arch Linux ARM rootfs: $url"
  if curl --fail --location --proto '=https' --proto-redir '=https' \
      --connect-timeout 15 --max-time 1800 --retry 2 \
      --speed-limit 1024 --speed-time 60 --write-out '%{url_effective}\n' \
      "$url" -o inputs/rootfs.download > out/rootfs-effective-url.tmp; then
    if gzip -t inputs/rootfs.download; then
      if [[ -n "${ROOTFS_SHA256:-}" ]]; then
        [[ "$ROOTFS_SHA256" =~ ^[a-fA-F0-9]{64}$ ]] || exit 1
        if ! printf '%s  %s\n' "$ROOTFS_SHA256" inputs/rootfs.download | sha256sum -c -; then
          echo 'Rootfs digest mismatch; refusing this mirror.' >&2
          continue
        fi
      fi
      mv inputs/rootfs.download inputs/ArchLinuxARM-aarch64.tar.gz
      mv out/rootfs-effective-url.tmp out/rootfs-effective-url.txt
      exit 0
    fi
  fi
  echo "Rootfs download failed: $url" >&2
done
echo 'All configured HTTPS rootfs sources failed.' >&2
exit 1
