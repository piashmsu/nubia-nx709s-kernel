#!/usr/bin/env bash
# 98-download-backup-from-release.sh
#
# One-shot recovery: pull stock boot images from the GitHub release
# (works on any phone/PC that has curl + zstd, no auth required).
#
# Usage:
#   bash 98-download-backup-from-release.sh [target_dir]
#
# Default target: $PWD/restored
set -euo pipefail

REL=https://github.com/piashmsu/nubia-nx709s-kernel/releases/download/stock-boot-backup-2026-05-04
DST=${1:-$PWD/restored}

mkdir -p "$DST"
cd "$DST"

FILES=(
    boot_a.img.zst
    boot_b.img.zst
    dtbo_a.img.zst
    dtbo_b.img.zst
    vendor_boot_a.img.zst
    vendor_boot_b.img.zst
    vbmeta_a.img.zst
    vbmeta_b.img.zst
    vbmeta_system_a.img.zst
    vbmeta_system_b.img.zst
    recovery_a.img.zst
    recovery_b.img.zst
    new-boot.img.zst
    SHA256SUMS.zst.txt
    SHA256SUMS.raw.txt
)

echo "[*] Downloading 15 files (~85 MB total) to $DST ..."
for f in "${FILES[@]}"; do
    echo -n "  $f ... "
    if curl -fsSL --retry 3 -o "$f" "$REL/$f"; then
        SZ=$(stat -c %s "$f" 2>/dev/null || stat -f %z "$f" 2>/dev/null)
        echo "$(numfmt --to=iec $SZ 2>/dev/null || echo $SZ)"
    else
        echo "FAILED"
    fi
done

echo
echo "[*] Verifying SHA256 of compressed files ..."
sha256sum -c SHA256SUMS.zst.txt 2>&1 | tail -20

echo
echo "[*] Decompressing .img.zst files ..."
if ! command -v zstd >/dev/null; then
    echo "[!] zstd not installed."
    echo "    On Debian/Kali/Ubuntu: apt install -y zstd"
    echo "    On Termux:             pkg install zstd"
    echo "    On Magisk Busybox:     skip (use 'zstd' from a desktop)"
    exit 1
fi
for f in *.img.zst; do
    zstd -d -f -q "$f"
done
ls -la *.img

echo
echo "[*] Verifying SHA256 of decompressed files ..."
sha256sum -c SHA256SUMS.raw.txt 2>&1 | tail -20

echo
echo "[*] Done. Files ready in $DST"
echo
echo "Next: choose a restore method"
echo "  - PC + fastboot:   see docs/RECOVERY_GUIDE.md  (Path A)"
echo "  - Live root/chroot:bash $(dirname "$0")/99-restore-bootimg.sh \"$DST\""
echo "  - TWRP terminal:   see docs/RECOVERY_GUIDE.md  (Path B)"
