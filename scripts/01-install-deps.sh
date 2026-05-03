#!/usr/bin/env bash
# 01-install-deps.sh — install all build dependencies on Ubuntu/Debian/Kali
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

echo "[*] Installing build dependencies..."

export DEBIAN_FRONTEND=noninteractive

$SUDO apt-get update

PKGS=(
    git build-essential bc bison flex
    libssl-dev libelf-dev kmod cpio rsync
    python3 python3-venv python3-pip perl ccache
    curl wget unzip tar xz-utils zstd
    libncurses-dev pkg-config zip
    device-tree-compiler dwarves
    gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
    gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi
    abootimg android-sdk-libsparse-utils
)

$SUDO apt-get install -y --no-install-recommends "${PKGS[@]}"

echo "[*] Verifying tools..."
for tool in clang aarch64-linux-gnu-gcc bison flex make python3 dtc; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  OK: $tool -> $(command -v "$tool")"
    else
        echo "  MISSING: $tool"
    fi
done

echo "[*] Done. Run 02-fetch-toolchain.sh next."
