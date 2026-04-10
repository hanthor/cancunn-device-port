# Partition Layout — cancunn

## A/B Slot Configuration

The device uses a full A/B (Virtual A/B, VAB) partition scheme with a dynamic super partition.

From `fastboot getvar all` and `/proc/partitions`:

| Partition | Size | Notes |
|-----------|------|-------|
| boot_a / boot_b | 64MB (0x4000000) | Kernel + generic ramdisk |
| vendor_boot_a / vendor_boot_b | 64MB (0x4000000) | Vendor ramdisk |
| dtbo_a / dtbo_b | 8MB (0x800000) | Device tree overlay |
| vbmeta_a / vbmeta_b | ~8KB | AVB verification root |
| vbmeta_system_a / vbmeta_system_b | ~4KB | System AVB chain |
| super | Dynamic | Contains system / vendor / product / system_ext |
| userdata | ~112GB | User data (ext4/f2fs) |

Firmware partitions (non-A/B, flashed once):
`lk`, `tee`, `gz`, `scp`, `sspm`, `spmfw`, `mcupm`, `gpueb`, `md1img`, `dpm`, `logo`, `pi_img`, `vcp`

## Super Partition (Dynamic)

The `super` partition uses Android's logical partition system. Logical partitions within super:

| Logical Partition | Contents |
|-------------------|---------|
| system_a / system_b | Android system image (EROFS) |
| vendor_a / vendor_b | Vendor HALs and blobs |
| product_a / product_b | Product overlay |
| system_ext_a / system_ext_b | System extensions |
| odm_a / odm_b | ODM-specific overlays |

To manipulate dynamic partitions, use `fastboot reboot fastboot` (userspace fastbootd) — standard fastboot cannot resize/create logical partitions.

## Flashing Notes

### AVB Preflash Validation

Motorola's fastboot implementation validates the AVB hash footer embedded at the end of boot/vendor_boot images before writing. The footer is a 64-byte structure starting with `AVBf` magic, appended after the actual image data to fill the partition.

**To flash a custom boot image** (e.g. Magisk-patched):
```python
with open('magisk_patched.img', 'rb') as f:
    data = bytearray(f.read())
# Zero out the 64-byte AVB footer at end of image
data[-64:] = b'\x00' * 64
with open('magisk_patched_noavb.img', 'wb') as f:
    f.write(data)
```
Then flash `magisk_patched_noavb.img` normally.

### Disabling AVB Verification

To bypass rollback index checks (required when flashing older firmware):

```python
with open('vbmeta.img', 'rb') as f:
    data = bytearray(f.read())
# Flags at offset 123 — bit 0 = disable-verity, bit 1 = disable-verification
data[123] |= 0x03
with open('vbmeta_noavb.img', 'wb') as f:
    f.write(data)
```

Flash to both slots:
```bash
fastboot flash vbmeta_a vbmeta_noavb.img
fastboot flash vbmeta_b vbmeta_noavb.img
```

Note: `fastboot flash vbmeta --disable-verity --disable-verification` fails on this device with "Failed to find AVB_MAGIC" due to a fastboot 37.0.0 bug — use the manual patch above instead.

### Anti-Rollback Protection

The device enforces rollback index protection even with an unlocked bootloader. The factory firmware on this test device is `V1UDS35H.26-14-6-2-6` (March 2026), which is newer than publicly available firmware mirrors (`V1UDS35H.26-14-2-9`, May 2025).

Flashing older firmware with AVB enabled causes "No valid operating system could be found" at boot. Disabling AVB in vbmeta bypasses this check.

## Bootloader Unlock

Standard Motorola unlock process:
```bash
fastboot oem get_unlock_data
# Submit output to motorola.com/unlockbootloader
fastboot oem unlock <KEY>
```

The unlock key is device-specific and permanent — the same key works after re-locking and re-unlocking.
