# QEMU 虚拟机配置指南 - 反虚拟化检测与硬件自定义

## 目录
1. [概述](#概述)
2. [环境准备](#环境准备)
3. [反虚拟化检测配置](#反虚拟化检测配置)
4. [硬件参数自定义](#硬件参数自定义)
5. [完整配置示例](#完整配置示例)
6. [验证与测试](#验证与测试)
7. [常见问题](#常见问题)

---

## 概述

本文档提供使用 QEMU 创建虚拟机的完整方案,实现以下目标:
- **隐藏虚拟化特征**: 移除 VM、QEMU、KVM 等虚拟化标识
- **硬件参数自定义**: 自由修改 CPU、主板、硬盘、网卡等硬件信息

### 适用场景
- 软件兼容性测试
- 安全研究与分析
- 反作弊系统测试
- 硬件环境模拟

---

## 环境准备

### 系统要求
- **操作系统**: Linux (推荐 Ubuntu 20.04+) 或 macOS
- **QEMU 版本**: 6.0+ (推荐 7.0+)
- **硬件**: 支持 KVM 的 CPU (Linux) 或 HVF (macOS) 

### 安装 QEMU

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install qemu-system-x86 qemu-utils
```

#### macOS
```bash
brew install qemu
```

#### 验证安装
```bash
qemu-system-x86_64 --version
```

---

## 反虚拟化检测配置

### 1. CPU 虚拟化标识隐藏

#### 关键参数说明
- `cpu`: 指定 CPU 型号
- `-cpu host`: 使用宿主机 CPU 特性
- `kvm=off`: 隐藏 KVM 虚拟化标识
- `hv_vendor_id`: 自定义 Hypervisor 厂商 ID

#### 配置示例
```bash
-cpu host,kvm=off,hv_vendor_id=GenuineIntel
```

### 2. SMBIOS 信息自定义

SMBIOS (System Management BIOS) 包含主板、BIOS、系统制造商等信息,是虚拟化检测的重要特征。

#### 完整 SMBIOS 配置
```bash
-smbios type=0,vendor="American Megatrends Inc.",version="F23",date="08/12/2021" \
-smbios type=1,manufacturer="ASUS",product="ROG STRIX B550-F GAMING",version="1.0",serial="System-Serial-12345",uuid="12345678-1234-1234-1234-123456789abc",sku="SKU-001",family="Desktop" \
-smbios type=2,manufacturer="ASUS",product="ROG STRIX B550-F GAMING",version="Rev 1.xx",serial="Board-Serial-67890",asset="Asset-Tag-001",location="Part Component" \
-smbios type=3,manufacturer="ASUS",version="1.0",serial="Chassis-Serial-11111",asset="Asset-Tag-002"
```

#### SMBIOS Type 说明
- **Type 0**: BIOS 信息
- **Type 1**: 系统信息
- **Type 2**: 主板信息
- **Type 3**: 机箱信息

### 3. 硬盘信息自定义

#### 创建虚拟硬盘
```bash
qemu-img create -f qcow2 disk.qcow2 100G
```

#### 自定义硬盘参数
```bash
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \
-device ide-hd,drive=disk0,serial="WD-WCAV12345678",model="WDC WD10EZEX-08WN4A0",wwn=0x50014ee2b5c6d8e9
```

**参数说明**:
- `serial`: 硬盘序列号
- `model`: 硬盘型号
- `wwn`: World Wide Name (全球唯一标识符)

### 4. 网卡 MAC 地址自定义

```bash
-netdev user,id=net0 \
-device e1000,netdev=net0,mac=52:54:00:12:34:56
```

**MAC 地址规则**:
- 前 3 字节为厂商 OUI (如 `52:54:00` 是 QEMU 默认)
- 建议使用真实厂商 OUI,如:
  - Intel: `00:1B:21`
  - Realtek: `00:E0:4C`
  - Broadcom: `00:10:18`

### 5. 隐藏 QEMU 设备特征

#### 移除 QEMU 默认设备
```bash
-nodefaults \
-no-user-config \
-device VGA,id=video0 \
-device ich9-intel-hda,id=sound0 \
-device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0
```

#### 使用真实硬件设备模拟
```bash
-device e1000  # Intel 网卡 (而非 virtio)
-device ich9-ahci  # Intel AHCI 控制器
```

---

## 硬件参数自定义

### 1. CPU 配置

#### 自定义 CPU 型号
```bash
-cpu Skylake-Client,vendor=GenuineIntel,family=6,model=94,stepping=3
```

#### 自定义 CPU 核心数
```bash
-smp cores=4,threads=2,sockets=1  # 4核8线程
```

### 2. 内存配置

```bash
-m 8192  # 8GB 内存
```

### 3. 显卡配置

```bash
-vga std  # 标准 VGA
# 或
-device qxl-vga,vgamem_mb=64  # QXL 显卡
```

### 4. 音频设备

```bash
-device intel-hda -device hda-duplex
```

### 5. USB 设备

```bash
-device qemu-xhci,id=xhci \
-device usb-tablet,bus=xhci.0
```

---

## 完整配置示例

### 示例 1: Windows 10 虚拟机 (反检测配置)

```bash
#!/bin/bash

qemu-system-x86_64 \
  -name "Windows-10-Desktop" \
  -machine type=q35,accel=kvm \
  -cpu host,kvm=off,hv_vendor_id=GenuineIntel,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
  -smp cores=4,threads=2,sockets=1 \
  -m 8192 \
  \
  -smbios type=0,vendor="American Megatrends Inc.",version="F23",date="08/12/2021" \
  -smbios type=1,manufacturer="ASUS",product="ROG STRIX B550-F GAMING",version="1.0",serial="SYS20210812001",uuid="a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",sku="SKU-ROG-001",family="Desktop" \
  -smbios type=2,manufacturer="ASUS",product="ROG STRIX B550-F GAMING",version="Rev 1.02",serial="MB20210812001",asset="Asset-MB-001",location="Base Board" \
  -smbios type=3,manufacturer="ASUS",version="1.0",serial="CH20210812001",asset="Asset-CH-001" \
  \
  -drive file=windows10.qcow2,if=none,id=disk0,format=qcow2,cache=writeback \
  -device ide-hd,drive=disk0,serial="WD-WCAV29472851",model="WDC WD10EZEX-08WN4A0",wwn=0x50014ee2b5c6d8e9 \
  \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  -device e1000,netdev=net0,mac=00:1B:21:3A:4F:5C \
  \
  -vga qxl \
  -device intel-hda -device hda-duplex \
  -device qemu-xhci,id=xhci \
  -device usb-tablet,bus=xhci.0 \
  \
  -boot order=c \
  -rtc base=localtime,clock=host \
  -no-hpet \
  -global kvm-pit.lost_tick_policy=discard
```

### 示例 2: Linux 虚拟机 (简化配置)

```bash
#!/bin/bash

qemu-system-x86_64 \
  -name "Ubuntu-Desktop" \
  -machine type=q35,accel=kvm \
  -cpu host,kvm=off \
  -smp 4 \
  -m 4096 \
  \
  -smbios type=1,manufacturer="Dell Inc.",product="OptiPlex 7090",serial="DELL-SN-123456" \
  \
  -drive file=ubuntu.qcow2,if=virtio,format=qcow2 \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0,mac=00:E0:4C:68:00:99 \
  \
  -vga virtio \
  -display sdl \
  -boot order=c
```

### 示例 3: macOS 虚拟机配置脚本

```bash
#!/bin/bash

# 创建虚拟硬盘
qemu-img create -f qcow2 macos.qcow2 128G

# 启动虚拟机
qemu-system-x86_64 \
  -name "MacBook-Pro-Simulator" \
  -machine type=q35,accel=hvf \
  -cpu Penryn,vendor=GenuineIntel,kvm=off \
  -smp cores=4,threads=2 \
  -m 8192 \
  \
  -smbios type=2,manufacturer="Apple Inc.",product="MacBookPro16,1",version="1.0",serial="C02ABC123XYZ" \
  \
  -drive file=macos.qcow2,if=none,id=disk0,format=qcow2 \
  -device ide-hd,drive=disk0,serial="APPLE-SSD-001",model="APPLE SSD AP0512N" \
  \
  -netdev user,id=net0 \
  -device e1000-82545em,netdev=net0,mac=A4:83:E7:12:34:56 \
  \
  -vga vmware \
  -usb -device usb-kbd -device usb-tablet
```

---

## 验证与测试

### 1. Windows 系统检测

#### 使用 systeminfo 命令
```cmd
systeminfo | findstr /C:"System Manufacturer" /C:"System Model"
```

#### 使用 WMIC 命令
```cmd
wmic bios get manufacturer,serialnumber,version
wmic baseboard get manufacturer,product,serialnumber
wmic diskdrive get model,serialnumber
wmic cpu get name,manufacturer
wmic nic get macaddress,name
```

#### 使用 PowerShell
```powershell
Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer,Model
Get-WmiObject Win32_BIOS | Select-Object Manufacturer,SerialNumber,Version
Get-WmiObject Win32_DiskDrive | Select-Object Model,SerialNumber
Get-WmiObject Win32_Processor | Select-Object Name,Manufacturer
Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.MACAddress} | Select-Object Name,MACAddress
```

### 2. Linux 系统检测

```bash
# 查看 SMBIOS 信息
sudo dmidecode -t system
sudo dmidecode -t baseboard
sudo dmidecode -t bios

# 查看硬盘信息
sudo hdparm -I /dev/sda | grep "Serial Number"
lsblk -o NAME,MODEL,SERIAL

# 查看网卡 MAC 地址
ip link show
ifconfig -a

# 检测虚拟化
systemd-detect-virt
virt-what
```

### 3. 虚拟化检测工具

#### CPU-Z (Windows)
- 下载: https://www.cpuid.com/softwares/cpu-z.html
- 检查 CPU 型号、主板信息

#### HWiNFO (Windows)
- 下载: https://www.hwinfo.com/
- 详细硬件信息检测

#### Pafish (反虚拟化检测工具)
- 用于测试虚拟机是否能被检测
- 下载: https://github.com/a0rtega/pafish

---

## 常见问题

### Q1: 如何生成随机但合理的硬件序列号?

**A**: 使用以下脚本生成:

```bash
#!/bin/bash

# 生成随机 UUID
UUID=$(uuidgen)

# 生成随机硬盘序列号 (WD 格式)
HDD_SERIAL="WD-WCAV$(openssl rand -hex 4 | tr '[:lower:]' '[:upper:]')"

# 生成随机 MAC 地址 (Intel OUI)
MAC="00:1B:21:$(openssl rand -hex 3 | sed 's/../&:/g;s/:$//')"

echo "UUID: $UUID"
echo "HDD Serial: $HDD_SERIAL"
echo "MAC Address: $MAC"
```

### Q2: KVM 加速在 macOS 上不可用怎么办?

**A**: macOS 使用 HVF (Hypervisor Framework) 替代 KVM:
```bash
-machine type=q35,accel=hvf
```

### Q3: 如何确保每次启动使用不同的硬件参数?

**A**: 创建配置生成脚本:

```bash
#!/bin/bash

# 生成随机参数
UUID=$(uuidgen)
SERIAL="SYS$(date +%Y%m%d)$(shuf -i 100-999 -n 1)"
MAC="00:1B:21:$(openssl rand -hex 3 | sed 's/../&:/g;s/:$//')"

# 启动 QEMU
qemu-system-x86_64 \
  -smbios type=1,serial="$SERIAL",uuid="$UUID" \
  -device e1000,netdev=net0,mac="$MAC" \
  # ... 其他参数
```

### Q4: 虚拟机仍然被检测为 QEMU,如何排查?

**A**: 检查以下项目:
1. ACPI 表中是否包含 QEMU 字符串
2. PCI 设备 ID 是否为 QEMU 默认值
3. 是否使用了 virtio 等虚拟化专用驱动
4. CPUID 指令返回值是否包含虚拟化标识

**解决方案**:
```bash
# 使用真实硬件设备模拟
-device e1000  # 而非 virtio-net
-device ide-hd  # 而非 virtio-blk

# 隐藏 ACPI 表中的 QEMU 标识
-acpitable file=custom_dsdt.aml
```

### Q5: 如何备份和恢复虚拟机配置?

**A**:
```bash
# 备份虚拟硬盘
qemu-img convert -O qcow2 disk.qcow2 disk_backup.qcow2

# 创建快照
qemu-img snapshot -c snapshot1 disk.qcow2

# 恢复快照
qemu-img snapshot -a snapshot1 disk.qcow2

# 查看快照列表
qemu-img snapshot -l disk.qcow2
```

---

## 高级技巧

### 1. 使用配置文件管理参数

创建 `vm-config.cfg`:
```ini
[machine]
type = q35
accel = kvm

[cpu]
model = host
features = kvm=off,hv_vendor_id=GenuineIntel

[smbios]
manufacturer = ASUS
product = ROG STRIX B550-F GAMING
serial = SYS20210812001
```

### 2. 网络桥接配置 (更真实的网络环境)

```bash
# 创建网桥
sudo ip link add br0 type bridge
sudo ip link set br0 up

# QEMU 配置
-netdev bridge,id=net0,br=br0 \
-device e1000,netdev=net0,mac=00:1B:21:3A:4F:5C
```

### 3. GPU 直通 (PCI Passthrough)

```bash
# 绑定 GPU 到 vfio-pci
echo "10de 1c03" > /sys/bus/pci/drivers/vfio-pci/new_id

# QEMU 配置
-device vfio-pci,host=01:00.0
```

---

## 参考资源

- QEMU 官方文档: https://www.qemu.org/documentation/
- SMBIOS 规范: https://www.dmtf.org/standards/smbios
- PCI 设备数据库: https://pci-ids.ucw.cz/
- MAC 地址 OUI 查询: https://maclookup.app/

---

**文档版本**: 1.0
**最后更新**: 2026-02-11
**作者**: Claude Sonnet 4.5
