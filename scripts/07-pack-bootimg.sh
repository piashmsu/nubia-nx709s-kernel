#!/usr/bin/env bash
# 07-pack-bootimg.sh — pack new kernel into a flashable boot.img using stock ramdisk
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/out/dist"
UNPACK="$ROOT/boot_image/unpack"
TOOLS="$ROOT/toolchains/mkbootimg"
OUT_IMG="$ROOT/boot-new.img"

if [ ! -f "$DIST/Image" ] && [ ! -f "$ROOT/out/msm-kernel/dist/Image" ]; then
    echo "[!] kernel Image not found in $DIST. Build first."
    exit 1
fi

KERNEL_IMAGE="$DIST/Image"
[ -f "$ROOT/out/msm-kernel/dist/Image" ] && KERNEL_IMAGE="$ROOT/out/msm-kernel/dist/Image"

if [ ! -d "$UNPACK" ] || [ ! -f "$UNPACK/ramdisk" ]; then
    echo "[!] Unpacked stock boot.img not found at $UNPACK. Run 03-extract-bootimg.sh first."
    exit 1
fi

# Read original cmdline if available
CMDLINE_FILE="$UNPACK/boot_args"
[ -f "$CMDLINE_FILE" ] || CMDLINE_FILE="$UNPACK/cmdline"
CMDLINE="console=ttyMSM0,115200n8"
[ -f "$CMDLINE_FILE" ] && CMDLINE="$(cat "$CMDLINE_FILE")"

echo "[*] Packing boot.img ..."
echo "    kernel : $KERNEL_IMAGE"
echo "    ramdisk: $UNPACK/ramdisk"
echo "    cmdline: $CMDLINE"

python3 "$TOOLS/mkbootimg.py" \
    --kernel "$KERNEL_IMAGE" \
    --ramdisk "$UNPACK/ramdisk" \
    --header_version 4 \
    --base 0x80000000 \
    --pagesize 4096 \
    --cmdline "$CMDLINE" \
    --os_version 12.0.0 \
    --os_patch_level 2026-04 \
    --output "$OUT_IMG"

echo "[*] Pack ok."
ls -la "$OUT_IMG"
sha256sum "$OUT_IMG"

# Optionally pack dtbo if rebuilt
if [ -f "$DIST/dtbo.img" ]; then
    cp "$DIST/dtbo.img" "$ROOT/dtbo-new.img"
    sha256sum "$ROOT/dtbo-new.img"
fi

cat <<EOF

[*] Done.

To flash (after backing up stock):
    fastboot --slot=other flash boot $(basename "$OUT_IMG")
    fastboot --slot=other flash dtbo dtbo-new.img    # if present
    fastboot set_active other
    fastboot reboot
EOF
