# Hardware Analysis — cancunn (MT6855)

Derived from live device tree (`/sys/firmware/fdt`) pulled with root access on stock Android 15 (V1UD35H.26-14-6), supplemented by dmesg and getprop.

## SoC: MediaTek MT6855 (Dimensity 7020)

- `compatible = "mediatek,MT6855"`
- `mot,model = "cancunn"`
- `mot,board-id = <0x47 0xb100>`
- Chip ID in mtkclient: `0x1129`
- CPU: Arm Cortex-A78 + Cortex-A55 cluster (octa-core)
- GPU: Arm Mali-G57

## Clock / Power Domains

Key subsystem clocks confirmed present in DTS:

| Block | Compatible | Notes |
|-------|-----------|-------|
| Top clock gen | `mediatek,mt6855-topckgen` | Main PLL mux |
| Infra clock | `mediatek,mt6855-infracfg_ao` | Infrastructure |
| PLL / mixed sys | `mediatek,mt6855-apmixedsys` | PLLs |
| Peri clock | `mediatek,mt6855-pericfg_ao` | Peripheral buses |
| VLP clock | `mediatek,mt6855-vlp_cksys` | Very low power |
| I2C wrap 0–3 | `mediatek,mt6855-imp_iic_wrap0–3` | I2C controllers |
| SCPSYS | `mediatek,mt6855-scpsys` | Power domains |

None of these have upstream mainline drivers for MT6855 specifically. MT6893/MT6983 drivers exist and are the closest reference.

## Display Pipeline

Display uses MediaTek's standard DRM pipeline, all MT6855-specific:

| Component | Compatible | Register Base |
|-----------|-----------|---------------|
| RDMA0 | `mediatek,mt6855-disp-rdma` | — |
| TDSHP0 | `mediatek,mt6855-disp-tdshp` | — |
| COLOR0 | `mediatek,mt6855-disp-color` | — |
| CCORR0 | `mediatek,mt6855-disp-ccorr` | — |
| AAL0 | `mediatek,mt6855-disp-aal` | — |
| GAMMA0 | `mediatek,mt6855-disp-gamma` | — |
| POSTMASK0 | `mediatek,mt6855-disp-postmask` | — |
| DITHER0 | `mediatek,mt6855-disp-dither` | — |
| DSC wrap | `mediatek,mt6855-disp-dsc` | — |
| WDMA0 | `mediatek,mt6855-disp-wdma` | — |
| UFBC WDMA | `mediatek,mt6855-disp-ufbc-wdma` | — |
| MIPI TX | `mediatek,mt6855-mipi-tx` | — |
| DSI0 | `mediatek,mt6855-dsi` | — |

### Display Panels (three variants — one fitted per unit)

All connect via DSI, resolution 1080x2400, 120Hz:

| Vendor | Compatible | IC |
|--------|-----------|-----|
| TianMA | `tm,ili7807s,672,vdo,120hz` | Ilitek ILI7807S |
| DJN | `djn,ft8725,672,vdo,120hz` | FocalTech FT8725 |
| CSOT | `csot,icnl9922c,672,vdo,120hz` | InnoChips ICNL9922C |

The `672` in the compatible string refers to the panel width in mm×10 (67.2mm). All three have init sequences in the DTS.

## PMIC and Power

### Primary PMIC: MediaTek MT6375
- Compatible: `mediatek,mt6375`
- Sub-nodes:
  - `mediatek,mt6375-adc` — ADC channels
  - `mediatek,mt6375-chg` — Charger (PE/PE2/PE4/PE5/PD)
  - `mediatek,mt6375-tcpc` — USB-C PD controller
  - `mediatek,mt6375-auxadc` — Auxiliary ADC
  - `mediatek,mt6375-gauge` — Battery fuel gauge
  - `mediatek,mt6375-lbat-service` — Low battery service
- Connected via I2C (`i2c@11b20000`, address `0x34`)

### Sub-PMICs
| IC | Compatible | Function |
|----|-----------|---------|
| Richtek RT5133 | `richtek,rt5133` | Camera/display power rails |
| Richtek RT6160 | `richtek,rt6160` | Additional regulator |

### Wireless Charging
- IC: CPS CPS4038
- Compatible: `cps,wls-charger-cps4038`
- Connected via I2C (`i2c@11db0000`, address `0x38`)

### Charging Protocols
All five MediaTek fast charging protocols present:
- PE (Pump Express), PE2, PE4, PE5
- USB Power Delivery (via MT6375 TCPC)

## USB

- Controller: `mediatek,mt6855-usb20`
- PHY: `mediatek,generic-tphy-v2`
- USB boost: `mediatek,usb_boost`
- OTG supported

The `generic-tphy-v2` has partial upstream support in mainline (other MediaTek SoCs use it).

## Audio

- Platform: `mediatek,mt6855-sound`
- Codec path: `mediatek,mt6855-mt6369-sound` (MT6369 codec)
- SCP audio: `mediatek,snd_scp_audio`, `mediatek,scp_audio_mbox`
- BT codec: `mediatek,mtk-btcvsd-snd`
- Features: 3.5mm jack, stereo speakers

## NFC

- IC: STMicroelectronics ST21NFC
- Compatible: `mediatek,nfc` / `st21nfc@08`
- Connected via I2C (`i2c@11ed0000`, address `0x08`)
- GPIO config: `mediatek,nfc-gpio-v2`
- **Mainline driver exists**: `st-nci` in `drivers/nfc/st-nci/`

## Camera

Multiple camera sensors via MediaTek SENINF (Serial Interface):
- SENINF ports 1–8 present (`mediatek,seninf1` through `seninf8`)
- Main: `mediatek,camera_main` (50MP, OIS)
- Ultrawide: `mediatek,camera_sub` (8MP)
- Front: not separately labeled (likely seninf3)
- AF drivers: `mediatek,camera_main_af`, `mediatek,camera_main_three_af`
- EEPROM: `mediatek,camera_eeprom` (two instances — main + ultrawide)
- Flashlight: `awinic,aw36518` + `mediatek,flashlights_aw36515`
- ISP: `mediatek,mt6855-camsys_main`, `camsys_rawa`, `camsys_rawb`
- Image processing: `mediatek,mt6855-imgsys1`, `imgsys2`, `mt6855-ipesys`

## Haptics

- IC: Awinic AW8697 or AW8671 (compatible: `awinic,haptic_nv`)
- Connected via I2C (`i2c@11db0000`, address `0x5A`)
- No mainline driver — downstream only

## Proximity / SAR

- IC: Semtech SX937x
- Compatible: `Semtech,sx937x`
- Connected via I2C (`i2c@11ed0000`)

## GPS

- `mediatek,gps` — Integrated MT6855 GNSS
- Supports: A-GPS, Galileo, GLONASS

## Thermal

- `mediatek,mt6855-board-ntc` — 5 instances (board thermistors)
- `mediatek,mt6855-oc-debug` — overcurrent debug

## Security / TEE

- Trustonic TEE: `android,trusty-smc-v1`, `mediatek,trusty-mtee-v1`
- GeniZone: `mediatek,trusty-gz`
- Nebula (second TEE): `android,nebula-smc-v1`
- Widevine: `mediatek,drm_wv`
- SVP (Secure Video Path): `medaitek,svp`

## Bootloader / Boot Timing (from DTS bootprof node)

| Stage | Time |
|-------|------|
| GZ (TrustZone) | 0ms |
| Secure OS | 11ms |
| TFA (Trusted Firmware-A) | 36ms |
| BL2 ext | 829ms |
| LK (Little Kernel) | 12039ms |
| Logo display | 773ms |
| PL (Preloader) | 4197ms |

LK takes ~12 seconds — notably long, likely due to display init and anti-rollback checks.

## Mainline Porting Priority

| Priority | Component | Effort | Reference |
|----------|-----------|--------|-----------|
| 1 | MT6855 SoC base (clocks, pinctrl) | Very High | MT6893/MT6983 drivers |
| 2 | MT6855 DRM + one panel | High | MT8195 DSI driver |
| 3 | MT6375 PMIC | Medium | MT6359 driver |
| 4 | USB (tphy-v2) | Low-Medium | Already partially upstream |
| 5 | NFC (ST21NFC) | Low | Already upstream |
| 6 | Wi-Fi | Low-Medium | MT7921 upstream (if same) |
| 7 | Audio | High | No MT6855 upstream |
| 8 | Camera | Very High | Last to land on any device |
| 9 | Modem (5G) | Very High | No open modem drivers |
