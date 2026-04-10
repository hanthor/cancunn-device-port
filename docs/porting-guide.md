# Porting Guide — LineageOS & postmarketOS for cancunn

## Prerequisites

- Unlocked bootloader (see [partition-layout.md](partition-layout.md))
- Root access (Magisk v30.7+ confirmed working)
- Linux build machine with 16GB+ RAM, 200GB+ disk
- USB cable (USB-C)

## Step 1: Get the Kernel Source

Motorola is required to publish kernel source under GPL. Check:

```
https://github.com/MotorolaMobilityLLC/kernel-devicetree
https://github.com/MotorolaMobilityLLC/kernel-msm  (wrong SoC, ignore)
```

Search for `cancunn` or `MT6855` or `mt6855`. The MediaTek platform kernel may be under a separate repo. Also check:

```
https://github.com/MotorolaMobilityLLC/kernel-slsi
```

If not yet published, open a GPL request at: https://motorola-global-portal.custhelp.com/app/opensorce

Alternative: use the cancunf kernel source (same MT6855 SoC, international Moto G54 5G) as a starting point — cancunf has an active custom ROM community.

## Step 2: Extract Device Tree

Already done — see `device-tree/cancunn.dts` in this repo (10,057 lines).

Key nodes to port to a clean device tree for LineageOS:
- CPU cluster topology (`/cpus`)
- Memory map
- Clock providers (topckgen, infracfg_ao, apmixedsys, pericfg_ao)
- Pin control (pinctrl)
- I2C controllers
- Display (DSI + one panel driver)
- USB (usb20 + tphy-v2)
- PMIC (MT6375)
- Battery / charging

## Step 3: LineageOS Device Tree Structure

LineageOS requires three repositories:

```
device/motorola/cancunn/          — device configuration
kernel/motorola/cancunn/          — kernel source
vendor/motorola/cancunn/          — proprietary blobs
```

### Extract Blobs (with root)

```bash
# From a running stock Android with root:
adb root  # won't work on production build, use:
adb shell su -c "ls /vendor/lib64/" | head -20

# Use lineage-scripts extract-files.sh approach
# or adb pull individual HAL .so files from /vendor/lib/
```

### Reference Device Trees

Use cancunf (Moto G54 5G) device tree as reference — same MT6855 SoC:
- Search GitHub for `cancunf device tree` or `mt6855 device tree`
- YAAP and PixelOS repos for cancunf contain the closest reference material

## Step 4: postmarketOS

### Option A: Downstream Kernel (faster to first boot)

Use the stock 5.10 kernel with minimal patches. postmarketOS supports downstream kernels.

```bash
pip install pmbootstrap
pmbootstrap init
# Select: vendor=motorola, device=cancunn (new device)
pmbootstrap aportgen linux-motorola-cancunn
```

Target: boot to serial console first, then framebuffer.

### Option B: Mainline Kernel (correct long-term path)

MT6855 is not yet in mainline. Required upstream work:

| Subsystem | Status | Reference |
|-----------|--------|-----------|
| MT6855 topckgen | Not upstream | MT6893 driver as base |
| MT6855 infracfg | Not upstream | MT6893 driver as base |
| MT6855 pinctrl | Not upstream | MT6893 pinctrl |
| MT6855 DRM | Not upstream | MT8195 DRM |
| MT6855 SCPSYS | Not upstream | MT6893 scpsys |
| generic-tphy-v2 | Partially upstream | Existing driver |
| MT6375 PMIC | Not upstream | MT6359 as base |
| ST21NFC | Upstream | `st-nci` driver |

Check MediaTek's staging tree for any MT6855 work:
```
git clone https://git.kernel.org/pub/scm/linux/kernel/git/mediatek/linux.git
git log --oneline --all | grep -i "mt6855\|6855\|dimensity.7020"
```

### Minimum Viable Boot Sequence for pmOS

1. Build kernel with `CONFIG_SERIAL_8250=y` and MediaTek UART enabled
2. Boot via `fastboot boot` — **note: `fastboot boot` is NOT supported on cancunn**
   - Must flash to `boot_a` partition instead
   - Zero out AVB footer before flashing (see partition-layout.md)
3. Connect USB, check `dmesg | grep ttyACM` for serial console
4. UART baud rate: 921600 for MT6855

### Known MT6855 Gotchas

- `CONFIG_MTK_DEVAPC=y` causes boot hangs — disable for bringup
- DVFS (CPU frequency scaling) requires proprietary blobs initially — use fixed frequency
- Display init sequence is in LK (bootloader) — kernel must replicate it for framebuffer
- `CONFIG_MTK_PLAT_SRAM_FLAG=y` may be needed to pass boot args from LK to kernel

## Step 5: Useful ADB Commands for Porting Research

```bash
# Full device tree (requires root)
adb shell su -c "cat /sys/firmware/fdt" > cancunn.dtb
dtc -I dtb -O dts -o cancunn.dts cancunn.dtb

# Kernel config from running kernel
adb shell su -c "cat /proc/config.gz" | gunzip > cancunn_kconfig

# All system properties
adb shell getprop > cancunn_props.txt

# Vendor partition listing (for blob extraction)
adb shell su -c "find /vendor -name '*.so' -o -name '*.xml'" > vendor_files.txt

# Platform devices
adb shell su -c "ls /sys/bus/platform/devices/"

# I2C device scan
adb shell su -c "ls /sys/bus/i2c/devices/"

# Thermal zones
adb shell su -c "for f in /sys/class/thermal/thermal_zone*/type; do echo \$f: \$(cat \$f); done"
```

## Step 6: Pull Kernel Config

```bash
adb shell su -c "cat /proc/config.gz" | gunzip > cancunn_kconfig
```

This gives the exact config used by the stock 5.10 kernel — essential for knowing which drivers are enabled and what options to carry forward.

## Community

- XDA thread for cancunf (closest relative): https://xdaforums.com/t/unofficial-moto-g-power-5g-2024-moto-g54-5g-thread.4720792/
- postmarketOS device porting: https://wiki.postmarketos.org/wiki/Porting_to_a_new_device
- MediaTek upstream mailing list: linux-mediatek@lists.infradead.org
