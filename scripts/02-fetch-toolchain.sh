#!/usr/bin/env bash
# 02-fetch-toolchain.sh — fetch AOSP clang + mkbootimg + avbtool
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLCHAINS="$ROOT/toolchains"
mkdir -p "$TOOLCHAINS"

echo "[*] Fetching AOSP prebuilt clang (host: linux-x86_64) ..."
if [ ! -d "$TOOLCHAINS/clang-aosp" ]; then
    git clone --depth=1 -b master \
        https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 \
        "$TOOLCHAINS/clang-aosp"
else
    echo "  already present, skipping."
fi

echo "[*] Available clang versions:"
ls -1 "$TOOLCHAINS/clang-aosp" | grep '^clang-' | head

echo "[*] Fetching mkbootimg ..."
if [ ! -d "$TOOLCHAINS/mkbootimg" ]; then
    git clone --depth=1 \
        https://android.googlesource.com/platform/system/tools/mkbootimg \
        "$TOOLCHAINS/mkbootimg"
fi

echo "[*] Fetching avbtool ..."
if [ ! -d "$TOOLCHAINS/avb" ]; then
    git clone --depth=1 \
        https://android.googlesource.com/platform/external/avb \
        "$TOOLCHAINS/avb"
fi

echo "[*] Fetching kernel build wrapper (build/) ..."
if [ ! -d "$ROOT/kernel_source/NX709S/build" ]; then
    git clone --depth=1 \
        https://android.googlesource.com/kernel/build \
        "$ROOT/kernel_source/NX709S/build"
fi

echo "[*] Fetching common kernel (only if you want to update 5.10.101 -> 5.10.168) ..."
echo "    skipped by default; uncomment to enable."
# git clone --depth=1 -b android12-5.10 \
#     https://android.googlesource.com/kernel/common \
#     "$ROOT/kernel_source/NX709S/common"

echo "[*] Done."
