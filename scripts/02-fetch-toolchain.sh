#!/usr/bin/env bash
# 02-fetch-toolchain.sh — fetch AOSP clang prebuilt + mkbootimg + avbtool
# Note: legacy `build.sh` was removed from kernel/build (Google migrated to kleaf/Bazel).
# We use a manual `make` based build instead — see 06-build-kernel.sh.
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

echo "[*] Available clang versions (top 5):"
ls -1 "$TOOLCHAINS/clang-aosp" | grep '^clang-r' | sort -V | tail -5

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

echo "[*] Done. (We do NOT clone kernel/build — modern repo no longer ships build.sh.)"
echo "    The build script 06-build-kernel.sh uses direct 'make' instead."
