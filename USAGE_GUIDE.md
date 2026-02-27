# 如何应用生成的硬件配置到虚拟机

本指南详细说明如何使用 `generate-hardware-params.sh` 生成的硬件配置来创建和配置虚拟机。

## 方法一：修改现有的 create-windows-vm.sh 脚本（推荐）

这是最简单直接的方法，适合大多数用户。

### 步骤 1: 生成硬件配置

```bash
cd /path/to/vm_for_device
./generate-hardware-params.sh
```

当提示是否保存配置时，选择 `y` 保存到文件。脚本会生成类似 `vm-config-20260225-141605.txt` 的配置文件。

### 步骤 2: 查看生成的配置

```bash
cat vm-config-*.txt
```

你会看到类似这样的输出：

```
系统类型: DIY
系统 UUID: 9f88681f-16da-435b-beca-b551d99cf454
系统序列号: SYS9F957C7C02F6
制造商: Gigabyte
产品型号: Z690 AORUS ELITE

BIOS 厂商: American Megatrends Inc.
BIOS 版本: F35
BIOS 日期: 05/27/2022

主板型号: Z690 AORUS ELITE
主板序列号: Gi45386CED73C8FB07
主板版本: Rev 2.02

CPU 厂商: Intel
CPU 型号: Intel(R) Core(TM) i5-12400F CPU @ 2.50GHz
...
```

### 步骤 3: 编辑 create-windows-vm.sh

打开 `create-windows-vm.sh` 文件：

```bash
nano create-windows-vm.sh
```

找到硬件信息配置部分（第 17-47 行），替换为生成的配置：

**原始配置：**
```bash
# 硬件信息自定义
BIOS_VENDOR="American Megatrends Inc."
BIOS_VERSION="F23"
BIOS_DATE="08/12/2021"

SYSTEM_MANUFACTURER="ASUS"
SYSTEM_PRODUCT="ROG STRIX B550-F GAMING"
SYSTEM_VERSION="1.0"
SYSTEM_SERIAL="SYS20210812001"
SYSTEM_UUID="a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
...
```

**替换为生成的配置：**
```bash
# 硬件信息自定义
BIOS_VENDOR="American Megatrends Inc."
BIOS_VERSION="F35"
BIOS_DATE="05/27/2022"

SYSTEM_MANUFACTURER="Gigabyte"
SYSTEM_PRODUCT="Z690 AORUS ELITE"
SYSTEM_VERSION="1.0"
SYSTEM_SERIAL="SYS9F957C7C02F6"
SYSTEM_UUID="9f88681f-16da-435b-beca-b551d99cf454"
SYSTEM_SKU="SKU-001"
SYSTEM_FAMILY="Desktop"

BOARD_MANUFACTURER="Gigabyte"
BOARD_PRODUCT="Z690 AORUS ELITE"
BOARD_VERSION="Rev 2.02"
BOARD_SERIAL="Gi45386CED73C8FB07"
BOARD_ASSET="AST-MB-67CF3C"

CHASSIS_MANUFACTURER="Gigabyte"
CHASSIS_VERSION="1.0"
CHASSIS_SERIAL="Gi106A855A9F2798AC"
CHASSIS_ASSET="AST-CH-01C5FF"

# 硬盘信息
HDD_SERIAL="2038AC9C2345E86491C8"
HDD_MODEL="CT250MX500SSD1"
HDD_WWN="0x500a07510489bf60"

# 网卡 MAC 地址
MAC_ADDRESS="00:E0:4C:02:4e:f8"
```

### 步骤 4: 修改 ISO 路径（如果需要）

找到第 15 行，修改为你的 Windows ISO 文件路径：

```bash
ISO_PATH="/path/to/your/windows.iso"
```

### 步骤 5: 启动虚拟机

```bash
./create-windows-vm.sh
```

首次运行会自动创建磁盘镜像并从 ISO 启动安装 Windows。

---

## 方法二：直接使用 QEMU 命令行

如果你想完全自定义启动参数，可以直接使用生成的 QEMU 配置。

### 步骤 1: 生成配置并保存

```bash
./generate-hardware-params.sh
# 选择 y 保存配置
```

### 步骤 2: 创建磁盘镜像

```bash
qemu-img create -f qcow2 windows10.qcow2 100G
```

### 步骤 3: 复制 QEMU 配置参数

从生成的配置文件中复制 QEMU 配置参数部分：

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

### 步骤 4: 构建完整的 QEMU 命令

```bash
qemu-system-x86_64 \
  -name "Windows-Desktop" \
  -machine type=q35,accel=kvm \
  -cpu host,kvm=off,hv_vendor_id=GenuineIntel \
  -smp cores=4,threads=2,sockets=1 \
  -m 8192 \
  \
  -smbios type=0,vendor="American Megatrends Inc.",version="F35",date="05/27/2022" \
  -smbios type=1,manufacturer="Gigabyte",product="Z690 AORUS ELITE",version="1.0",serial="SYS9F957C7C02F6",uuid="9f88681f-16da-435b-beca-b551d99cf454",sku="SKU-001",family="Desktop" \
  -smbios type=2,manufacturer="Gigabyte",product="Z690 AORUS ELITE",version="Rev 2.02",serial="Gi45386CED73C8FB07",asset="AST-MB-67CF3C",location="Base Board" \
  -smbios type=3,manufacturer="Gigabyte",version="1.0",serial="Gi106A855A9F2798AC",asset="AST-CH-01C5FF" \
  \
  -drive file=windows10.qcow2,if=none,id=disk0,format=qcow2 \
  -device ide-hd,drive=disk0,serial="2038AC9C2345E86491C8",model="CT250MX500SSD1",wwn=0x500a07510489bf60 \
  \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  -device e1000,netdev=net0,mac=00:E0:4C:02:4e:f8 \
  \
  -cdrom windows.iso \
  -boot order=d \
  -vnc :0
```

---

## 方法三：使用 vm-manager.sh（简化管理）

`vm-manager.sh` 提供了简化的虚拟机管理功能，但使用的是简化的硬件配置。

### 基本用法

```bash
# 列出所有虚拟机
./vm-manager.sh list

# 创建新虚拟机
./vm-manager.sh create

# 启动虚拟机
./vm-manager.sh start myvm

# 查看虚拟机信息
./vm-manager.sh info myvm
```

### 自定义 vm-manager.sh 使用生成的配置

如果你想让 `vm-manager.sh` 使用生成的硬件配置，需要修改脚本的第 162-175 行：

```bash
nano vm-manager.sh
```

找到启动虚拟机的部分，将生成的 SMBIOS 参数替换进去。

---

## 完整工作流程示例

### 场景：创建一个新的 Windows 10 虚拟机

**1. 生成硬件配置**
```bash
cd /path/to/vm_for_device
./generate-hardware-params.sh
# 输入 y 保存配置
```

**2. 记录生成的配置文件名**
```bash
ls -lt vm-config-*.txt | head -1
# 输出: vm-config-20260225-141605.txt
```

**3. 查看配置内容**
```bash
cat vm-config-20260225-141605.txt
```

**4. 编辑启动脚本**
```bash
cp create-windows-vm.sh my-custom-vm.sh
nano my-custom-vm.sh
```

**5. 替换硬件配置**
- 将配置文件中的所有硬件参数复制到脚本中
- 修改 `ISO_PATH` 为你的 Windows ISO 路径
- 修改 `DISK_IMAGE` 为新的磁盘文件名（如 `my-windows.qcow2`）

**6. 启动虚拟机**
```bash
chmod +x my-custom-vm.sh
./my-custom-vm.sh
```

**7. 连接 VNC 安装系统**
```bash
# 使用 VNC 客户端连接
vncviewer localhost:5900
```

**8. 安装完成后验证配置**

在 Windows 虚拟机中打开 PowerShell：

```powershell
# 查看系统信息
Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer,Model

# 查看 BIOS 信息
Get-WmiObject Win32_BIOS | Select-Object Manufacturer,Version,SerialNumber

# 查看主板信息
Get-WmiObject Win32_BaseBoard | Select-Object Manufacturer,Product,SerialNumber

# 查看硬盘信息
Get-WmiObject Win32_DiskDrive | Select-Object Model,SerialNumber

# 查看网卡 MAC 地址
Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.MACAddress} | Select-Object Name,MACAddress

# 查看 CPU 信息
Get-WmiObject Win32_Processor | Select-Object Name
```

**9. 运行虚拟化检测测试**
```cmd
# 在虚拟机内运行
test-vm-detection-windows.bat
```

---

## 配置参数说明

### SMBIOS Type 0 (BIOS 信息)
- `vendor`: BIOS 厂商（如 "American Megatrends Inc."）
- `version`: BIOS 版本（如 "F35"）
- `date`: BIOS 日期（如 "05/27/2022"）

### SMBIOS Type 1 (系统信息)
- `manufacturer`: 系统制造商（如 "Gigabyte"）
- `product`: 产品型号（如 "Z690 AORUS ELITE"）
- `serial`: 系统序列号
- `uuid`: 系统 UUID
- `sku`: SKU 编号
- `family`: 产品系列（如 "Desktop"）

### SMBIOS Type 2 (主板信息)
- `manufacturer`: 主板制造商
- `product`: 主板型号
- `version`: 主板版本（如 "Rev 2.02"）
- `serial`: 主板序列号
- `asset`: 资产标签

### SMBIOS Type 3 (机箱信息)
- `manufacturer`: 机箱制造商
- `version`: 机箱版本
- `serial`: 机箱序列号
- `asset`: 资产标签

### 硬盘配置
- `serial`: 硬盘序列号
- `model`: 硬盘型号
- `wwn`: World Wide Name（全球唯一标识符）

### 网卡配置
- `mac`: MAC 地址（必须使用真实厂商的 OUI 前缀）

---

## 常见问题

### Q1: 每次都需要重新生成配置吗？

不需要。一旦生成并应用了配置，虚拟机会一直使用这些参数。除非你想创建新的虚拟机或更换硬件配置。

### Q2: 可以在运行中的虚拟机上修改配置吗？

不可以。必须关闭虚拟机，修改启动脚本，然后重新启动。

### Q3: 如何验证配置是否生效？

在 Windows 虚拟机中运行：
```powershell
Get-WmiObject Win32_ComputerSystem
Get-WmiObject Win32_BIOS
Get-WmiObject Win32_BaseBoard
```

### Q4: 配置文件保存在哪里？

生成的配置文件保存在当前目录，文件名格式为 `vm-config-YYYYMMDD-HHMMSS.txt`。

### Q5: 可以为多个虚拟机使用相同的配置吗？

不建议。每个虚拟机应该有唯一的序列号、UUID 和 MAC 地址，就像真实硬件一样。为每个虚拟机重新运行生成器。

### Q6: 如何确保配置不会被检测为虚拟机？

1. 使用生成器生成的配置（确保硬件逻辑一致）
2. 避免使用 virtio 等虚拟化专用设备
3. 使用真实厂商的 MAC 地址前缀
4. 确保 CPU、主板、BIOS 的代际匹配
5. 运行 `test-vm-detection-windows.bat` 进行验证

---

## 高级技巧

### 批量创建多个虚拟机

```bash
#!/bin/bash
for i in {1..5}; do
    # 生成配置
    echo "n" | ./generate-hardware-params.sh > /dev/null

    # 创建虚拟机脚本
    cp create-windows-vm.sh vm-$i.sh

    # 修改磁盘文件名
    sed -i "s/windows10.qcow2/windows-$i.qcow2/" vm-$i.sh

    echo "虚拟机 $i 配置完成"
done
```

### 保存配置模板

```bash
# 将常用配置保存为模板
mkdir -p templates
cp vm-config-*.txt templates/template-gigabyte-z690.txt
```

### 自动化配置应用

创建一个脚本自动应用配置：

```bash
#!/bin/bash
# apply-config.sh

CONFIG_FILE=$1
VM_SCRIPT=$2

if [ -z "$CONFIG_FILE" ] || [ -z "$VM_SCRIPT" ]; then
    echo "用法: $0 <config_file> <vm_script>"
    exit 1
fi

# 从配置文件提取参数并应用到脚本
# (需要根据实际格式编写解析逻辑)
```

---

## 总结

推荐使用**方法一**（修改 create-windows-vm.sh），这是最简单且最可靠的方式。生成配置 → 复制参数 → 修改脚本 → 启动虚拟机，四步即可完成。

记住：每次创建新虚拟机时都应该重新生成配置，确保每个虚拟机都有唯一的硬件标识。
