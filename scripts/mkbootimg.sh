#!/usr/bin/env bash
set -euo pipefail
# Use the same pinned AOSP implementation for CI validation and real images.
exec python3 "$(dirname "$0")/../tools/mkbootimg/mkbootimg.py" "$@"
