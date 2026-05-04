#!/usr/bin/env bash
# 99-restore-bootimg.sh — emergency restore of stock boot images
#
# Usage:
#   bash scripts/99-restore-bootimg.sh                  (auto-pick newest backup)
#   bash scripts/99-restore-bootimg.sh /path/to/backup  (explicit dir)
#
# Phone must be in fastboot/bootloader mode for fastboot-based restore.
# OR run this from inside the chroot if the phone still boots and you have
# a working ROOT shell with /dev/block/by-name/ visible.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---- Find backup directory ----
if [ -n "${1:-}" ]; then
    BAK="$1"
else
    # Try multiple common locations, newest wins
    BAK=$(ls -td \
        /sdcard/nubia_boot_backup_* \
        /external_sd/nubia_backup_* \
        "$ROOT/boot_image/backup_"* \
        2>/dev/null | head -1)
fi

if [ -z "$BAK" ] || [ ! -d "$BAK" ]; then
    echo "[!] No backup directory found."
    echo "    Looked in:"
    echo "      /sdcard/nubia_boot_backup_*"
    echo "      /external_sd/nubia_backup_*"
    echo "      $ROOT/boot_image/backup_*"
    exit 1
fi

echo "[*] Using backup directory: $BAK"
echo "[*] Files:"
ls -la "$BAK"/*.img 2>/dev/null
echo

# ---- Verify SHA256 if file present ----
if [ -f "$BAK/SHA256SUMS" ]; then
    echo "[*] Verifying SHA256 sums ..."
    (cd "$BAK" && sha256sum -c SHA256SUMS 2>&1 | tail -15)
    echo
fi

# ---- Restore mode detection ----
echo "[?] How do you want to restore?"
echo "    1) FASTBOOT (phone in bootloader mode, recommended)"
echo "    2) DIRECT dd  (phone is rooted and currently booted, dangerous)"
echo "    3) DRY-RUN   (just print the commands)"
echo
read -r -p "Select [1/2/3]: " MODE

case "$MODE" in
    1)
        echo
        echo "[*] Run these on a host with adb/fastboot connected to your phone:"
        echo
        for slot in a b; do
            for part in boot dtbo vendor_boot vbmeta vbmeta_system recovery; do
                f="$BAK/${part}_${slot}.img"
                [ -f "$f" ] || continue
                echo "fastboot --disable-verity --disable-verification flash ${part}_${slot} \"$f\""
            done
        done
        echo
        echo "fastboot reboot"
        ;;
    2)
        echo
        echo "[!!] DANGEROUS — writes to live block devices."
        read -r -p "Type RESTORE to proceed: " CONFIRM
        [ "$CONFIRM" = "RESTORE" ] || { echo "aborted"; exit 1; }
        for slot in a b; do
            for part in boot dtbo vendor_boot vbmeta vbmeta_system recovery; do
                f="$BAK/${part}_${slot}.img"
                T="/dev/block/by-name/${part}_${slot}"
                [ -f "$f" ] || continue
                [ -b "$T" ] || { echo "skip $part — $T not present"; continue; }
                echo "[*] dd if=$f of=$T bs=1M conv=fsync ..."
                dd if="$f" of="$T" bs=1M conv=fsync status=progress
            done
        done
        sync
        echo "[*] Done. Reboot now."
        ;;
    3|*)
        echo
        echo "Equivalent fastboot commands:"
        for slot in a b; do
            for part in boot dtbo vendor_boot vbmeta vbmeta_system recovery; do
                f="$BAK/${part}_${slot}.img"
                [ -f "$f" ] || continue
                echo "fastboot flash ${part}_${slot} \"$f\""
            done
        done
        ;;
esac
