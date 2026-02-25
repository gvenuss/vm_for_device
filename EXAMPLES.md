# 硬件参数生成器示例

本文档展示了 `generate-hardware-params.sh` 脚本生成的真实案例。

## 案例 1: DIY 组装机 - Gigabyte Z690 AORUS ELITE

```
系统类型: DIY
制造商: Gigabyte
产品型号: Z690 AORUS ELITE

CPU 厂商: Intel
CPU 型号: Intel(R) Core(TM) i5-12400F CPU @ 2.50GHz
APIC ID: 0x1f
微码版本: 0x00000426

BIOS 厂商: American Megatrends Inc.
BIOS 版本: F35
BIOS 日期: 05/27/2022

主板型号: Z690 AORUS ELITE
主板序列号: Gi45386CED73C8FB07
主板版本: Rev 2.02
资产标签: AST-MB-67CF3C

机箱序列号: Gi106A855A9F2798AC
资产标签: AST-CH-01C5FF

硬盘品牌: Crucial
硬盘型号: CT250MX500SSD1
硬盘序列号: 2038AC9C2345E86491C8
WWN: 0x500a07510489bf60
固件版本: M3CR032

网卡厂商: Realtek
MAC 地址: 00:E0:4C:02:4e:f8
```

**QEMU 配置参数：**
```bash
-smbios type=0,vendor="American Megatrends Inc.",version="F35",date="05/27/2022" \
-smbios type=1,manufacturer="Gigabyte",product="Z690 AORUS ELITE",version="1.0",serial="SYS9F957C7C02F6",uuid="9f88681f-16da-435b-beca-b551d99cf454",sku="SKU-001",family="Desktop" \
-smbios type=2,manufacturer="Gigabyte",product="Z690 AORUS ELITE",version="Rev 2.02",serial="Gi45386CED73C8FB07",asset="AST-MB-67CF3C",location="Base Board" \
-smbios type=3,manufacturer="Gigabyte",version="1.0",serial="Gi106A855A9F2798AC",asset="AST-CH-01C5FF" \
-cpu host,vendor=Intel \
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \
-device ide-hd,drive=disk0,serial="2038AC9C2345E86491C8",model="CT250MX500SSD1",wwn=0x500a07510489bf60 \
-netdev user,id=net0 \
-device e1000,netdev=net0,mac=00:E0:4C:02:4e:f8
```

**配置特点：**
- Intel 12代 CPU (i5-12400F) 与 Z690 芯片组完美匹配
- AMI BIOS 符合 DIY 主板标准
- BIOS 版本 F35 符合技嘉主板命名规范
- BIOS 日期 (2022年5月) 符合 Z690 主板发布时间
- 主板序列号前缀 "Gi" 代表 Gigabyte
- Crucial SSD 配正确的 WWN 前缀 (0x500a0751) 和固件版本

---

## 案例 2: DIY 组装机 - ASRock Z690 Pro RS

```
系统类型: DIY
制造商: ASRock
产品型号: Z690 Pro RS

CPU 厂商: Intel
CPU 型号: Intel(R) Core(TM) i7-12700K CPU @ 3.60GHz
APIC ID: 0x0e
微码版本: 0x0000042e

BIOS 厂商: American Megatrends Inc.
BIOS 版本: F15
BIOS 日期: 04/22/2023

主板型号: Z690 Pro RS
主板序列号: AS617F349C6489481B
主板版本: Rev 3.06
资产标签: AST-MB-1D1BF8

机箱序列号: AS4762F65AF94BF170
资产标签: AST-CH-34151A

硬盘品牌: WDC
硬盘型号: WDC WD20EZRZ-00Z5HB0
硬盘序列号: WD-WCAVF064227B
WWN: 0x50014ee00e7dd640
固件版本: 80.00A80

网卡厂商: Broadcom
MAC 地址: 00:10:18:b5:b4:09
```

**QEMU 配置参数：**
```bash
-smbios type=0,vendor="American Megatrends Inc.",version="F15",date="04/22/2023" \
-smbios type=1,manufacturer="ASRock",product="Z690 Pro RS",version="1.0",serial="SYS6CCD34CB3B26",uuid="4d3b3cff-7a01-46d0-aa75-3cbf0c05af9b",sku="SKU-001",family="Desktop" \
-smbios type=2,manufacturer="ASRock",product="Z690 Pro RS",version="Rev 3.06",serial="AS617F349C6489481B",asset="AST-MB-1D1BF8",location="Base Board" \
-smbios type=3,manufacturer="ASRock",version="1.0",serial="AS4762F65AF94BF170",asset="AST-CH-34151A" \
-cpu host,vendor=Intel \
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \
-device ide-hd,drive=disk0,serial="WD-WCAVF064227B",model="WDC WD20EZRZ-00Z5HB0",wwn=0x50014ee00e7dd640 \
-netdev user,id=net0 \
-device e1000,netdev=net0,mac=00:10:18:b5:b4:09
```

**配置特点：**
- Intel 12代 CPU (i7-12700K) 与 Z690 芯片组匹配
- 主板序列号前缀 "AS" 代表 ASRock
- WD 硬盘配正确的 WWN 前缀 (0x50014ee) 和固件版本
- Broadcom 网卡 MAC 地址前缀 (00:10:18) 符合 OUI 规范

---

## 案例 3: 品牌机 - Lenovo Legion T7

```
系统类型: OEM
制造商: Lenovo
产品型号: Legion T7

CPU 厂商: AMD
CPU 型号: AMD Ryzen 5 5600X 6-Core Processor
APIC ID: 0x0c
微码版本: 0x0a500010

BIOS 厂商: Lenovo
BIOS 版本: M69KT79A
BIOS 日期: 02/17/2024

主板型号: 4848
主板序列号: Le93A2629436FBD240
主板版本: Rev 1.05
资产标签: AST-MB-2D7D23

机箱序列号: Le64423A5E39358E47
资产标签: AST-CH-024BF0

硬盘品牌: Toshiba
硬盘型号: DT01ACA100
硬盘序列号: Y9GS1491F24D
WWN: 0x500003900ecbd4b0
固件版本: MS2OA750

网卡厂商: Broadcom
MAC 地址: 00:10:18:8f:6e:e1
```

**QEMU 配置参数：**
```bash
-smbios type=0,vendor="Lenovo",version="M69KT79A",date="02/17/2024" \
-smbios type=1,manufacturer="Lenovo",product="Legion T7",version="1.0",serial="SYSC578BB29D963",uuid="1177f6b2-4663-451c-a32f-a3d69b0df1e2",sku="SKU-001",family="Desktop" \
-smbios type=2,manufacturer="Lenovo",product="4848",version="Rev 1.05",serial="Le93A2629436FBD240",asset="AST-MB-2D7D23",location="Base Board" \
-smbios type=3,manufacturer="Lenovo",version="1.0",serial="Le64423A5E39358E47",asset="AST-CH-024BF0" \
-cpu host,vendor=AMD \
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \
-device ide-hd,drive=disk0,serial="Y9GS1491F24D",model="DT01ACA100",wwn=0x500003900ecbd4b0 \
-netdev user,id=net0 \
-device e1000,netdev=net0,mac=00:10:18:8f:6e:e1
```

**配置特点：**
- AMD Ryzen 5000 系列 CPU 配联想品牌机
- BIOS 厂商为 Lenovo（品牌机使用自家 BIOS）
- BIOS 版本格式 M69KT79A 符合联想命名规范
- 主板型号使用数字编号 (4848)，符合 OEM 主板特征
- 序列号前缀 "Le" 代表 Lenovo
- Toshiba 硬盘配正确的 WWN 前缀 (0x5000039)

---

## 案例 4: 品牌机 - HP Z2 Tower G9

```
系统类型: OEM
制造商: HP
产品型号: Z2 Tower G9

CPU 厂商: Intel
CPU 型号: Intel(R) Core(TM) i7-12700K CPU @ 3.60GHz
APIC ID: 0x14
微码版本: 0x00000424

BIOS 厂商: HP
BIOS 版本: S08 Ver. 07.03.03
BIOS 日期: 01/31/2024

主板型号: 6672
主板序列号: HPB146CFD08E043AAE
主板版本: Rev 1.08
资产标签: AST-MB-AEC2B1

机箱序列号: HP3DDA1A792210F1DD
资产标签: AST-CH-8ADF2B

硬盘品牌: Samsung
硬盘型号: Samsung SSD 980 PRO 1TB
硬盘序列号: S5H2N95DEA2B6BC0DD0
WWN: 0x500253800004d6b5
固件版本: 5B2QGXA7

网卡厂商: Broadcom
MAC 地址: 00:10:18:e9:d2:8b
```

**QEMU 配置参数：**
```bash
-smbios type=0,vendor="HP",version="S08 Ver. 07.03.03",date="01/31/2024" \
-smbios type=1,manufacturer="HP",product="Z2 Tower G9",version="1.0",serial="SYS6DA4C830C0E1",uuid="490d60d9-31c8-4777-b7b5-2e59c71b6a48",sku="SKU-001",family="Desktop" \
-smbios type=2,manufacturer="HP",product="6672",version="Rev 1.08",serial="HPB146CFD08E043AAE",asset="AST-MB-AEC2B1",location="Base Board" \
-smbios type=3,manufacturer="HP",version="1.0",serial="HP3DDA1A792210F1DD",asset="AST-CH-8ADF2B" \
-cpu host,vendor=Intel \
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \
-device ide-hd,drive=disk0,serial="S5H2N95DEA2B6BC0DD0",model="Samsung SSD 980 PRO 1TB",wwn=0x500253800004d6b5 \
-netdev user,id=net0 \
-device e1000,netdev=net0,mac=00:10:18:e9:d2:8b
```

**配置特点：**
- Intel 12代 CPU 配 HP 工作站
- BIOS 版本格式 "S08 Ver. 07.03.03" 符合 HP 命名规范
- 主板型号使用数字编号 (6672)
- 序列号前缀 "HP" 代表 HP
- Samsung 980 PRO SSD 配正确的 WWN 前缀 (0x5002538) 和固件版本

---

## 配置逻辑说明

### CPU 和主板匹配关系

| CPU 代际 | 适配芯片组 | 发布年份 |
|---------|-----------|---------|
| Intel 12代 | Z690/B660 | 2022-2024 |
| Intel 11代 | Z590/B560 | 2021-2023 |
| Intel 10代 | Z490/B460 | 2020-2022 |
| AMD Ryzen 5000 | X570/B550 | 2021-2023 |
| AMD Ryzen 3000 | X570/B450 | 2019-2021 |

### 硬盘 WWN 前缀对照表

| 品牌 | WWN 前缀 |
|------|---------|
| WDC | 0x50014ee |
| Samsung | 0x5002538 |
| Seagate | 0x5000c500 |
| Crucial | 0x500a0751 |
| Kingston | 0x50026b76 |
| Toshiba | 0x5000039 |
| SanDisk | 0x5001b44 |

### 网卡 MAC 地址 OUI 前缀

| 厂商 | OUI 前缀 |
|------|---------|
| Intel | 00:1B:21 |
| Realtek | 00:E0:4C |
| Broadcom | 00:10:18 |
| Qualcomm | 00:03:7F |

### BIOS 版本格式

- **DIY 主板 (AMI BIOS)**: F10, F15, F20, F23, F30, F35
- **Dell**: 数字格式，如 1.2.3
- **HP**: S## Ver. ##.##.## 格式
- **Lenovo**: M##KT##A 格式
