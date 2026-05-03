#!/usr/bin/env bash
# 06-build-kernel.sh — build the GKI kernel via Google's build.sh wrapper
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KP="$ROOT/kernel_source/NX709S/kernel_platform"
TC="$ROOT/toolchains"

if [ ! -d "$KP/msm-kernel" ]; then
    echo "[!] Kernel source missing."
    exit 1
fi

# Pick latest available clang
CLANG_DIR=$(ls -1d "$TC/clang-aosp/clang-r"* 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$CLANG_DIR" ]; then
    echo "[!] No clang found under $TC/clang-aosp. Run 02-fetch-toolchain.sh first."
    exit 1
fi
export PATH="$CLANG_DIR/bin:$PATH"
echo "[*] Using clang: $CLANG_DIR"

# ccache speed-up
export USE_CCACHE=1
export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-20G}"
mkdir -p "$CCACHE_DIR"

mkdir -p "$ROOT/out/log"

cd "$KP"

if [ ! -d "build" ] && [ ! -d "$KP/../build" ]; then
    # Try running from the upper dir which is what build.sh expects
    cd "$KP/.."
fi

export ROOT_DIR="$KP/.."
export OUT_DIR="$ROOT/out"
export DIST_DIR="$ROOT/out/dist"
export VARIANT="${VARIANT:-gki}"
export LTO="${LTO:-thin}"
export SKIP_MRPROPER=1
export TRIM_UNUSED_MODULES=1
export BUILD_CONFIG="msm-kernel/build.config.nubia.nx709s"

JOBS="$(nproc)"
echo "[*] Building (variant=$VARIANT, LTO=$LTO, jobs=$JOBS) ..."
echo "[*] BUILD_CONFIG=$BUILD_CONFIG"
echo "[*] Logs: $ROOT/out/log/build.log"

if [ -x "$KP/build/build.sh" ]; then
    BUILDER="$KP/build/build.sh"
elif [ -x "$KP/../build/build.sh" ]; then
    BUILDER="$KP/../build/build.sh"
else
    echo "[!] build.sh missing. Run 02-fetch-toolchain.sh."
    exit 1
fi

set -o pipefail
"$BUILDER" -j"$JOBS" 2>&1 | tee "$ROOT/out/log/build.log"

echo "[*] Build artifacts:"
ls -la "$DIST_DIR" 2>/dev/null || ls -la "$OUT_DIR"
