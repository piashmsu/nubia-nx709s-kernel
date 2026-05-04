# Recovery Guide — restoring stock boot.img

This document explains how to roll back to the stock kernel if a custom build bricks your phone.

## What was backed up (timestamp 2026-05-04)

| File | Size | Notes |
|---|---|---|
| boot_a.img | 96 MB | A-slot kernel + ramdisk |
| boot_b.img | 96 MB | B-slot kernel + ramdisk |
| dtbo_a.img | 24 MB | A-slot device-tree overlay |
| dtbo_b.img | 24 MB | B-slot device-tree overlay |
| vendor_boot_a.img | 96 MB | A-slot vendor ramdisk + DLKMs |
| vendor_boot_b.img | 96 MB | B-slot vendor ramdisk + DLKMs |
| vbmeta_a.img | 64 KB | A-slot AVB metadata |
| vbmeta_b.img | 64 KB | B-slot AVB metadata |
| vbmeta_system_a.img | 64 KB | A-slot system AVB |
| vbmeta_system_b.img | 64 KB | B-slot system AVB |
| recovery_a.img | 100 MB | A-slot recovery |
| recovery_b.img | 100 MB | B-slot recovery |
| **Total** | **~634 MB** | per snapshot |

## Backup locations (3 redundant copies)

1. `/sdcard/nubia_boot_backup_<timestamp>/` — primary, fastest recovery from TWRP
2. `/external_sd/nubia_backup_<timestamp>/` — external microSD redundancy
3. `<repo>/boot_image/backup_<date>/` — chroot/repo workspace (not committed to git)

Verify with `sha256sum -c SHA256SUMS` inside any backup dir.

## Symbol fingerprint of the running stock kernel

```
Linux version 5.10.168-android12-9-00001-g61344663df42-ab9937098
GKI ABI                   : ab9937098
boot kernel hash (1MB)    : c5af47db79f53b46  (same on both slots)
```

## How to restore — 3 paths

### Path A: fastboot (recommended, requires PC + USB cable)

```bash
adb reboot bootloader
fastboot devices            # confirm device shows up

# A-slot
fastboot --disable-verity --disable-verification flash boot_a        boot_a.img
fastboot --disable-verity --disable-verification flash dtbo_a        dtbo_a.img
fastboot --disable-verity --disable-verification flash vendor_boot_a vendor_boot_a.img
fastboot --disable-verity --disable-verification flash vbmeta_a      vbmeta_a.img
fastboot --disable-verity --disable-verification flash vbmeta_system_a vbmeta_system_a.img

# B-slot (mirror)
fastboot --disable-verity --disable-verification flash boot_b        boot_b.img
fastboot --disable-verity --disable-verification flash dtbo_b        dtbo_b.img
fastboot --disable-verity --disable-verification flash vendor_boot_b vendor_boot_b.img
fastboot --disable-verity --disable-verification flash vbmeta_b      vbmeta_b.img
fastboot --disable-verity --disable-verification flash vbmeta_system_b vbmeta_system_b.img

fastboot reboot
```

### Path B: TWRP custom recovery

If the phone won't boot but TWRP still works:

```bash
# In TWRP's Advanced -> Terminal:
cd /sdcard/nubia_boot_backup_*
dd if=boot_a.img        of=/dev/block/by-name/boot_a        bs=1M
dd if=boot_b.img        of=/dev/block/by-name/boot_b        bs=1M
dd if=dtbo_a.img        of=/dev/block/by-name/dtbo_a        bs=1M
dd if=dtbo_b.img        of=/dev/block/by-name/dtbo_b        bs=1M
dd if=vendor_boot_a.img of=/dev/block/by-name/vendor_boot_a bs=1M
dd if=vendor_boot_b.img of=/dev/block/by-name/vendor_boot_b bs=1M
dd if=vbmeta_a.img      of=/dev/block/by-name/vbmeta_a      bs=4K
dd if=vbmeta_b.img      of=/dev/block/by-name/vbmeta_b      bs=4K
sync
reboot
```

### Path C: Live phone (rooted, still booting) — chroot or Magisk shell

```bash
su -c 'bash /sdcard/nubia_boot_backup_*/restore.sh'
# or:
bash <repo>/scripts/99-restore-bootimg.sh
# select option 2 (DIRECT dd) and type RESTORE
```

This is the **most dangerous** option — overwriting `boot_a` while you're booted from `boot_a` is allowed but risky. Always ensure you've also flashed `vbmeta` and rebooted.

## Block device map (NX709S)

```
boot_a          /dev/block/sde13   (96 MB)
boot_b          /dev/block/sde41   (96 MB)
dtbo_a          /dev/block/sde17   (24 MB)
dtbo_b          /dev/block/sde45   (24 MB)
vendor_boot_a   /dev/block/sde24   (96 MB)
vendor_boot_b   /dev/block/sde52   (96 MB)
vbmeta_a        /dev/block/sde16   (64 KB)
vbmeta_b        /dev/block/sde44   (64 KB)
vbmeta_system_a /dev/block/sda8    (64 KB)
vbmeta_system_b /dev/block/sda9    (64 KB)
recovery_a      /dev/block/sde27   (100 MB)
recovery_b      /dev/block/sde54   (100 MB)
```

## What if the phone is hard-bricked (no fastboot, no recovery)?

Use **EDL (Emergency Download) mode** with QFIL or QPST:
- Hold both volume buttons + plug in USB
- Use Qualcomm's QFIL / QPST tool with the original ZTE programmer firehose
- Flash a full firmware package
- This bypasses bootloader entirely

EDL mode firmware for NX709S is available from ZTE service centers.

## Active slot

Both A and B slots had the SAME kernel content (matching hash `c5af47db79f53b46`).
The slots are likely synchronized (often the case after factory provisioning).
For safety, this backup snapshots BOTH slots — you can restore either or both.

## Do NOT commit the backup .img files to git

`.gitignore` already excludes them. The repo only stores documentation and scripts; the actual binary boot images stay on your device and SD cards.
