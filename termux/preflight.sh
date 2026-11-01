#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
echo "Begonia Ubuntu Touch - preflight (NO FLASH)"
command -v curl >/dev/null || { echo "Install curl: pkg install curl"; exit 1; }
mkdir -p "$HOME/begonia-ut"
curl -fLsS --retry 3 https://raw.githubusercontent.com/ubports/installer-configs/master/v2/devices/begonia.yml -o "$HOME/begonia-ut/begonia.yml" || { echo "Could not retrieve device config. Stop."; exit 1; }
echo "Official config downloaded: $HOME/begonia-ut/begonia.yml"
echo "Android 11 vendor detected previously; stock base compatibility UNVERIFIED."
echo "No partitions modified. Do not flash until firmware requirements and official image checksums are verified."
