#!/usr/bin/env bash
# Build kernel for cancunn (Moto G Power 5G 2024, XT2415-1, MT6855)
# Tested with: Clang 19.1.7, aarch64-linux-gnu-gcc 14.2.0, kernel 5.10.233
# Source: Motorola GPL branch android-15-release-v1uds35h.26-14-6-2-4
# Result: out/arch/arm64/boot/Image.gz (~3.3 MB)
#         out/arch/arm64/boot/dts/mediatek/mt6855.dtb (~210 KB)

set -e

KERNEL_DIR="${KERNEL_DIR:-$HOME/kernel-mtk-cancunn}"
JOBS="${JOBS:-$(nproc)}"

cd "$KERNEL_DIR"

# Apply patches if not already applied
if ! git diff --quiet HEAD 2>/dev/null; then
    echo "Working tree has changes — skipping patch apply"
else
    echo "Applying cancunn build patches..."
    git am patches/0001-cancunn-clang19-gki-build-fixes.patch
fi

echo "Configuring kernel..."
LLVM=1 LLVM_IAS=0 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    make O=out mgk_64_k510_defconfig

# Merge cancunn-specific config fragments
for cfg in moto-mgk_64_k510-cancunn.config; do
    if [ -f "arch/arm64/configs/$cfg" ]; then
        LLVM=1 LLVM_IAS=0 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
            scripts/kconfig/merge_config.sh -m -O out \
            out/.config arch/arm64/configs/$cfg
    fi
done

# Key config overrides (see STATUS.md for rationale)
cat >> out/.config << 'CONFIG_EOF'
CONFIG_MODULES=y
CONFIG_ANDROID_VENDOR_OEM_DATA=y
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_NET=y
CONFIG_INET=y
CONFIG_MTK_CHARGER=y
CONFIG_MTK_ENABLE_GENIEZONE=y
CONFIG_TCPC_CLASS=y
CONFIG_MTK_AEE_IPANIC=y
CONFIG_MTK_HANG_DETECT=y
CONFIG_MTK_TRUSTED_MEMORY_SUBSYSTEM=m
# CONFIG_RTC_CLASS is not set
CONFIG_CONFIG_ANDROID_VENDOR_HOOKS is not set
CONFIG_EOF

LLVM=1 LLVM_IAS=0 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    make O=out olddefconfig

echo "Building kernel (${JOBS} jobs)..."
LLVM=1 LLVM_IAS=0 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
KCFLAGS="-D__ANDROID_COMMON_KERNEL__ \
  -Wno-error=bitwise-instead-of-logical \
  -Wno-error=unused-but-set-variable \
  -Wno-error=unused-function \
  -Wno-error=deprecated-non-prototype \
  -Wno-error=unused-label \
  -Wno-error=implicit-function-declaration \
  -Wno-error=incompatible-function-pointer-types \
  -Wno-error=single-bit-bitfield-constant-conversion \
  -Wno-error=unused-result \
  -Wno-error=unused-variable \
  -Wno-error=implicit-int \
  -Wno-error=return-type \
  -Wno-error=frame-larger-than" \
make O=out -j"${JOBS}" Image.gz dtbs

echo ""
echo "Build complete:"
ls -lh out/arch/arm64/boot/Image.gz \
       out/arch/arm64/boot/dts/mediatek/mt6855.dtb 2>/dev/null

# Build cancunn DTBOs
DTC="out/scripts/dtc/dtc"
SRC="arch/arm64/boot/dts/mediatek"
OUT="out/arch/arm64/boot/dts/mediatek"
for overlay in mt6855-cancunn-evb-overlay mt6855-cancunn-dvt-overlay; do
    clang-19 -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp \
        -I"$SRC" -Iarch/arm64/boot/dts -Iinclude \
        "$SRC/${overlay}.dts" 2>/dev/null | \
    "$DTC" -@ -I dts -O dtb -o "$OUT/${overlay}.dtbo" - 2>/dev/null && \
    echo "  $OUT/${overlay}.dtbo: $(ls -lh "$OUT/${overlay}.dtbo" | awk '{print $5}')"
done
