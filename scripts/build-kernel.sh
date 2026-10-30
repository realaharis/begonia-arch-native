#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out logs
exec > >(tee logs/kernel.log) 2>&1
test -f work/linux/Makefile
export ARCH=arm64 LLVM=1 KBUILD_BUILD_USER=builder KBUILD_BUILD_HOST=begonia-arch
export KBUILD_BUILD_TIMESTAMP='2025-09-04 10:52:31 +0000' KBUILD_BUILD_VERSION=1
unset LDFLAGS
cp config/kernel.config work/linux/.config
(cd work/linux && scripts/kconfig/merge_config.sh -m .config ../../config/headless.fragment)
make -C work/linux olddefconfig
python3 scripts/check-config.py work/linux/.config config/headless.fragment
make -C work/linux -j"${JOBS:-$(nproc)}" Image.gz modules mediatek/mt6785-xiaomi-begonia.dtb
make -C work/linux modules_install INSTALL_MOD_PATH="$PWD/work/kernel-package/usr" INSTALL_MOD_STRIP=1
find work/kernel-package/usr/lib/modules -name build -type l -delete
find work/kernel-package/usr/lib/modules -name source -type l -delete
cp work/linux/arch/arm64/boot/Image.gz out/Image.gz
cp work/linux/arch/arm64/boot/dts/mediatek/mt6785-xiaomi-begonia.dtb out/begonia.dtb
cp work/linux/.config out/kernel.config
cp work/linux/System.map out/System.map
make -s -C work/linux kernelrelease > out/kernel.release
tar -C work/kernel-package -cJf out/kernel-modules.tar.xz usr
