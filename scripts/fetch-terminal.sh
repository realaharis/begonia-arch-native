#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
mkdir -p inputs work out
commit=d62a654f9f84344571cbf5a306d33869d49aa70b
archive="inputs/firmware-$commit.tar.gz"
curl --fail --location --retry 3 --max-time 180 "https://gitlab.postmarketos.org/mt6785-mainline/firmware/-/archive/$commit/firmware-$commit.tar.gz" -o "$archive"
printf '%s  %s\n' "$(python3 -c 'import json; print(json.load(open("config/sources.json"))["touch_firmware_reference"]["sha512"])')" "$archive" | sha512sum -c -
mkdir -p work/firmware
tar -xf "$archive" -C work/firmware --strip-components=1
zstd -d -f "work/firmware/novatek/nt36672a_begonia_csot.bin.zst" -o work/firmware/nt36672a_begonia_csot.bin
sha256sum work/firmware/nt36672a_begonia_csot.bin > out/touch-firmware.sha256
git init work/wvkbd
git -C work/wvkbd fetch --depth=1 https://github.com/jjsullivan5196/wvkbd.git f7e9ea3a7565decd0d120861c1cb36a7b6836244
git -C work/wvkbd checkout --detach FETCH_HEAD
test "$(git -C work/wvkbd rev-parse HEAD)" = f7e9ea3a7565decd0d120861c1cb36a7b6836244
git -C work/wvkbd archive HEAD | gzip -n > inputs/wvkbd-source.tar.gz
