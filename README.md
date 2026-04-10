# Motorola Moto G Power 5G 2024 (cancunn) — Device Port Research

Community research repository for porting **LineageOS** and **postmarketOS** to the Motorola Moto G Power 5G 2024 (codename: `cancunn`).

This device has no existing custom ROM ecosystem. This repository documents hardware, device tree analysis, and porting progress to serve as a foundation for the community.

## Device Specifications

| Field | Value |
|-------|-------|
| Codename | cancunn |
| Model | XT2415-1 |
| SoC | MediaTek Dimensity 7020 (MT6855V/AZA) |
| Architecture | arm64 |
| RAM | 8GB LPDDR4X |
| Storage | 128GB UFS 2.2 |
| Kernel | 5.10.233 (Android 12 base, shipped with Android 15) |
| Android (stock) | 15 (SDK 35) |
| Security patch | 2025-04-01 |
| Bootloader | Unlockable via Motorola (flashing_unlocked) |
| Partition scheme | A/B (VAB) with dynamic/super partition |
| Serial (test device) | ZD222T9HBF |

## Hardware Components

| Component | Details | Mainline Driver Status |
|-----------|---------|----------------------|
| Display | 6.7" IPS LCD, 1080x2400, 120Hz | Partial — MT6855 DRM not upstream |
| Display panels | TianMA ili7807s / DJN ft8725 / CSOT icnl9922c (120Hz) | No upstream driver |
| Main camera | 50MP (f/1.8, OIS) | No |
| Ultrawide | 8MP | No |
| Front camera | 16MP | No |
| Battery | 5000mAh | MT6375 gauge — partial |
| Charging | 30W wired (PE/PE2/PE4/PE5/PD), 15W wireless (CPS4038) | No |
| PMIC | MediaTek MT6375 | Partial |
| Sub-PMICs | Richtek RT5133, RT6160 | No |
| Modem | MT6855 integrated 5G | No |
| Wi-Fi / BT | MediaTek (likely MT7921 or MT6639) | MT7921 has upstream driver |
| NFC | ST Microelectronics ST21NFC | Yes — `st-nci` in mainline |
| Haptics | Awinic AW8697/AW8671 (haptic_nv) | No |
| Fingerprint | Side-mounted | No |
| USB | USB-C, OTG, USB 2.0 | Partial — generic-tphy-v2 |
| Audio | 3.5mm jack, stereo speakers, MT6369 codec | No |
| GPS | A-GPS, Galileo, GLONASS | No |
| Proximity | Semtech SX937x | Partial |
| Flashlight | Awinic AW36518 / AW36515 | No |

## Repository Structure

```
cancunn-device-port/
├── README.md                   — This file
├── docs/
│   ├── hardware-analysis.md    — Detailed DTS-based hardware map
│   ├── porting-guide.md        — Steps to build LineageOS / postmarketOS
│   ├── partition-layout.md     — Partition table and flashing notes
│   └── boot-process.md         — Bootloader, AVB, A/B slot notes
├── device-tree/
│   ├── cancunn.dtb             — Live device tree (pulled from /sys/firmware/fdt)
│   └── cancunn.dts             — Decompiled device tree source
└── logs/
    ├── cancunn_props.txt       — Android system properties (getprop)
    ├── cancunn_dmesg.txt       — Kernel ring buffer (dmesg)
    ├── cancunn_cpuinfo.txt     — /proc/cpuinfo
    ├── cancunn_partitions.txt  — /proc/partitions
    └── cancunn_platform_devices.txt — /sys/bus/platform/devices/
```

## Related Devices

| Codename | Device | SoC | Notes |
|----------|--------|-----|-------|
| cancunf | Moto G54 5G (international) | MT6855 | Has custom ROM ecosystem (PixelOS, YAAP, /e/OS). NOT cross-flashable due to different partition layout, but device tree is useful reference |

## Current Status

| Goal | Status |
|------|--------|
| Bootloader unlocked | ✅ Done |
| Root access (Magisk v30.7) | ✅ Done |
| Device tree extracted | ✅ Done (300KB, 10057 lines) |
| Hardware inventory | ✅ Done |
| Kernel source located | ⏳ Pending — see [porting guide](docs/porting-guide.md) |
| LineageOS device tree | ⏳ Not started |
| postmarketOS package | ⏳ Not started |
| Mainline boot | ⏳ Not started |

## Key Findings

- **AVB preflash validation**: Motorola validates the AVB hash footer in boot.img before writing via fastboot. To flash custom boot images, zero out the 64-byte AVB footer at the end of the partition image before flashing.
- **Rollback protection**: The device ships with firmware newer than what is publicly available on mirrors. Disabling AVB verification in vbmeta (setting flags byte to `0x03`) bypasses rollback index checks when the bootloader is unlocked.
- **mtkclient**: The MT6855 preloader has SLA (Software Locking Authentication) enabled. mtkclient detects the device but the handshake fails. Hardware BROM access would require test point shorting.
- **Three display panels**: The DTS includes init sequences for three different panel vendors — any one of the three may be fitted depending on production batch.

## Contributing

Pull requests welcome. Priority areas:
1. Locating Motorola's GPL kernel source for cancunn
2. Comparing cancunn DTS with cancunf device tree
3. Testing mainline kernel boot (any output is progress)
4. Identifying MT6855 upstream kernel work

## Resources

- [postmarketOS porting guide](https://wiki.postmarketos.org/wiki/Porting_to_a_new_device)
- [LineageOS porting guide](https://wiki.lineageos.org/how-to/import-to-lineageos)
- [cancunf XDA thread](https://xdaforums.com/t/unofficial-moto-g-power-5g-2024-moto-g54-5g-thread.4720792/)
- [mtkclient](https://github.com/bkerler/mtkclient)
- [Motorola kernel source](https://github.com/MotorolaMobilityLLC)
- [MediaTek mainline kernel tree](https://git.kernel.org/pub/scm/linux/kernel/git/mediatek/linux.git)
