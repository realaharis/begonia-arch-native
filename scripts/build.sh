#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/fetch-sources.sh
bash scripts/prepare-rootfs.sh
bash scripts/build-kernel.sh
bash scripts/build-rootfs.sh
bash scripts/build-boot.sh
