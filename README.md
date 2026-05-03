# Nubia NX709S — NetHunter Kernel Build

Custom kernel build workspace for the **ZTE / Nubia NX709S** (Snapdragon 8+ Gen 1 / Cape, GKI 5.10 android12).

Goals: **NetHunter + KernelSU + performance tweaks**.

## Repository layout

```
device-info/   live phone properties, partitions, modules (gathered via Kali chroot)
configs/       running_kernel.config, build.config.nubia.nx709s, NX709S diff configs
kernel_source/ ZTE official GPL release (cloned at build time, .gitignored)
boot_image/    place dumped boot.img / vendor_boot.img here (.gitignored)
patches/       additional patches
scripts/       01..07 build automation
docs/
  README.md           overview
  DEVICE_INFO.md      complete spec sheet
  BUILD_GUIDE.md      step-by-step
  COPILOT_PROMPT.md   prompt for AI agents
```

## Quick start (Linux x86_64)

```bash
git clone https://github.com/<you>/<this-repo> nubia
cd nubia

# Get the 1.5 GB kernel source (NOT committed here)
git clone --depth=1 https://github.com/ztemt/NX709S kernel_source/NX709S

bash scripts/01-install-deps.sh
bash scripts/02-fetch-toolchain.sh
# place dumped boot.img, vendor_boot.img, dtbo.img into boot_image/
bash scripts/03-extract-bootimg.sh
bash scripts/04-apply-kernelsu.sh
bash scripts/05-apply-nethunter.sh
bash scripts/06-build-kernel.sh
bash scripts/07-pack-bootimg.sh
```

Result: `boot-new.img` and `dtbo-new.img` ready to flash via fastboot.

## CI / GitHub Actions / Copilot

See `docs/COPILOT_PROMPT.md` for the prompt to paste into GitHub Copilot Chat or any AI coding agent. The agent can run scripts 01–07 sequentially in a 16 GB Codespace or self-hosted runner.

A minimal GitHub Actions workflow (place at `.github/workflows/build.yml`):

```yaml
name: Build NetHunter Kernel
on:
  workflow_dispatch:
  push:
    branches: [main]
jobs:
  kernel:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - run: git clone --depth=1 https://github.com/ztemt/NX709S kernel_source/NX709S
      - run: bash scripts/01-install-deps.sh
      - run: bash scripts/02-fetch-toolchain.sh
      - run: bash scripts/04-apply-kernelsu.sh
      - run: bash scripts/05-apply-nethunter.sh
      - run: bash scripts/06-build-kernel.sh
      - uses: actions/upload-artifact@v4
        with:
          name: kernel-Image
          path: out/dist/Image
```

## Important notes

- **Source kernel is 5.10.101**, running kernel is 5.10.168. ZTE has not refreshed the GPL drop. For exact ABI match, overlay `android12-5.10` patches from `https://android.googlesource.com/kernel/common`.
- **GKI architecture**: only the kernel `Image` is rebuilt; vendor DLKM modules come from stock `vendor_boot.img`. Keep `CONFIG_MODULE_SIG=n` to avoid signature mismatch.
- **Bootloader unlock required**. ZTE/Nubia has a separate unlock procedure.
- **A/B device**: always flash to the inactive slot first.
- See `docs/BUILD_GUIDE.md` Phase 8 for safe flashing steps.

## License

Kernel source: GPL-2.0 (from ZTE official GPL release).
KernelSU: GPL-2.0.
NetHunter patches: see upstream Kali NetHunter project.
This workspace's scripts and docs: MIT (you can choose otherwise).
