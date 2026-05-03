#!/usr/bin/env bash
# 00-collect-device-info.sh — re-gather phone info on demand (run inside Kali chroot OR Termux on phone)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/device-info"
mkdir -p "$OUT/devicetree"

uname -a > "$OUT/uname.txt"
cat /proc/version  > "$OUT/proc_version.txt" 2>/dev/null
cat /proc/cmdline  > "$OUT/proc_cmdline.txt" 2>/dev/null
cat /proc/cpuinfo  > "$OUT/proc_cpuinfo.txt" 2>/dev/null
cat /proc/meminfo  > "$OUT/proc_meminfo.txt" 2>/dev/null
cat /proc/modules  > "$OUT/proc_modules.txt" 2>/dev/null
cat /proc/partitions > "$OUT/proc_partitions.txt" 2>/dev/null
ls -la /dev/block/by-name/ > "$OUT/partitions.txt" 2>/dev/null || true

# Kernel config
mkdir -p "$ROOT/configs"
if [ -r /proc/config.gz ]; then
    cp /proc/config.gz "$ROOT/configs/proc_config.gz"
    zcat /proc/config.gz > "$ROOT/configs/running_kernel.config"
    echo "  saved /proc/config.gz"
fi

# Device tree
[ -r /proc/device-tree/compatible ] && tr -d '\0' < /proc/device-tree/compatible > "$OUT/devicetree/compatible.txt"
[ -r /proc/device-tree/model ] && tr -d '\0' < /proc/device-tree/model > "$OUT/devicetree/model.txt"

# Properties (Android getprop)
if command -v getprop >/dev/null 2>&1; then
    getprop > "$OUT/getprop_all.txt" 2>/dev/null || true
fi
for f in /system/build.prop /vendor/build.prop /system_ext/etc/build.prop /product/etc/build.prop; do
    [ -r "$f" ] || continue
    base=$(basename "$f")
    parent=$(dirname "$f" | tr '/' '_')
    cp "$f" "$OUT/${parent}_${base}" 2>/dev/null && echo "  saved $f"
done

echo "[*] Device info written to $OUT/"
ls -la "$OUT"
