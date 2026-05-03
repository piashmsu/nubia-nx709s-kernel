#!/usr/bin/env bash
# 03-extract-bootimg.sh — split boot.img into kernel + ramdisk + dtb
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOT_DIR="$ROOT/boot_image"
UNPACK="$BOOT_DIR/unpack"
TOOLS="$ROOT/toolchains/mkbootimg"

if [ ! -f "$BOOT_DIR/boot.img" ]; then
    echo "[!] $BOOT_DIR/boot.img not found."
    echo "    From the rooted phone, run:"
    echo "      su -c 'dd if=/dev/block/by-name/boot\$(getprop ro.boot.slot_suffix) of=/sdcard/boot.img'"
    echo "    Then: adb pull /sdcard/boot.img boot_image/"
    exit 1
fi

mkdir -p "$UNPACK"
echo "[*] Unpacking boot.img ..."
python3 "$TOOLS/unpack_bootimg.py" --boot_img "$BOOT_DIR/boot.img" --out "$UNPACK"

echo "[*] Output:"
ls -la "$UNPACK"

if [ -f "$BOOT_DIR/vendor_boot.img" ]; then
    echo "[*] Unpacking vendor_boot.img ..."
    mkdir -p "$BOOT_DIR/vendor_unpack"
    python3 "$TOOLS/unpack_bootimg.py" --boot_img "$BOOT_DIR/vendor_boot.img" \
        --out "$BOOT_DIR/vendor_unpack"
    ls -la "$BOOT_DIR/vendor_unpack"
fi

echo "[*] Done. Kernel: $UNPACK/kernel  Ramdisk: $UNPACK/ramdisk"
