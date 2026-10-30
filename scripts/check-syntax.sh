#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for f in scripts/*.sh; do bash -n "$f"; done
for f in initramfs/init overlay/usr/lib/begonia/*; do sh -n "$f"; done
python3 -m py_compile scripts/*.py tests/*.py
