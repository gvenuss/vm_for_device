# QEMU 虚拟机反检测配置工具

一套完整的 QEMU 虚拟机配置工具，用于创建难以被检测的虚拟机环境，支持自定义硬件参数。

## 功能特性

- ✅ 隐藏虚拟化特征 - 移除 VM、QEMU、KVM 等虚拟化标识
- ✅ 硬件参数自定义 - 自由修改 CPU、主板、硬盘、网卡等硬件信息
- ✅ 随机参数生成 - 自动生成真实的硬件序列号和配置
- ✅ 检测工具 - 验证虚拟机是否能被识别

## 快速开始

### 1. 安装 QEMU

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install qemu-system-x86 qemu-utils -y
```

**macOS:**
```bash
brew install qemu
```

### 2. 创建虚拟机

```bash
# 赋予脚本执行权限
chmod +x *.sh

# 启动 Windows 虚拟机
./create-windows-vm.sh

# 或启动 Linux 虚拟机
./create-linux-vm.sh
```

首次运行会自动创建磁盘镜像。

### 3. 安装操作系统（可选）

如需安装系统，编辑启动脚本取消注释：

```bash
nano create-windows-vm.sh

# 找到并取消注释这两行：
-cdrom windows.iso \
-boot d \
```

### 4. 连接虚拟机

虚拟机使用 VNC 显示，端口 5900：

```bash
# 使用 VNC 客户端连接
localhost:5900

# 或通过 SSH 端口转发（推荐）
ssh -L 5900:localhost:5900 user@host
```

## 文件说明

### 核心脚本
- `create-windows-vm.sh` - Windows 虚拟机启动脚本
- `create-linux-vm.sh` - Linux 虚拟机启动脚本
- `generate-hardware-params.sh` - 硬件参数随机生成器

### 检测工具
- `test-vm-detection-linux.sh` - Linux 虚拟化检测测试
- `test-vm-detection-windows.bat` - Windows 虚拟化检测测试

## 自定义硬件参数

### 方法 1: 使用生成器
```bash
./generate-hardware-params.sh
```
复制生成的参数到启动脚本中。

### 方法 2: 手动编辑
编辑 `create-windows-vm.sh` 或 `create-linux-vm.sh`：

```bash
# 基本配置
MEMORY="8192"      # 内存 (MB)
CPU_CORES="4"      # CPU 核心数
DISK_SIZE="100G"   # 磁盘大小

# SMBIOS 信息
SYSTEM_MANUFACTURER="ASUS"
SYSTEM_PRODUCT="ROG STRIX B550-F GAMING"
SYSTEM_SERIAL="SYS20210812001"

# 硬盘信息
HDD_SERIAL="WD-WCAV29472851"
HDD_MODEL="WDC WD10EZEX-08WN4A0"

# 网卡 MAC 地址
MAC_ADDRESS="00:1B:21:3A:4F:5C"
```

## 常用命令

### 虚拟机管理
```bash
# 查看虚拟机进程
ps aux | grep qemu

# 停止虚拟机
pkill qemu-system-x86_64

# 查看磁盘信息
qemu-img info windows10.qcow2
```

### 磁盘快照
```bash
# 创建快照
qemu-img snapshot -c snapshot1 disk.qcow2

# 查看快照列表
qemu-img snapshot -l disk.qcow2

# 恢复快照
qemu-img snapshot -a snapshot1 disk.qcow2

# 删除快照
qemu-img snapshot -d snapshot1 disk.qcow2
```

### 磁盘管理
```bash
# 创建磁盘
qemu-img create -f qcow2 disk.qcow2 100G

# 扩容磁盘
qemu-img resize disk.qcow2 +50G

# 转换格式
qemu-img convert -f qcow2 -O raw disk.qcow2 disk.img
```

## 验证配置

### Windows 系统
在虚拟机内运行 PowerShell：

```powershell
# 系统信息
Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer,Model

# BIOS 信息
Get-WmiObject Win32_BIOS | Select-Object Manufacturer,SerialNumber

# 硬盘信息
Get-WmiObject Win32_DiskDrive | Select-Object Model,SerialNumber

# 网卡 MAC 地址
Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.MACAddress} | Select-Object Name,MACAddress
```

### Linux 系统
```bash
# SMBIOS 信息
sudo dmidecode -t system
sudo dmidecode -t baseboard

# 硬盘信息
lsblk -o NAME,MODEL,SERIAL

# 网卡信息
ip link show

# 检测虚拟化
systemd-detect-virt
```

## 端口说明

| 端口 | 用途 | 说明 |
|------|------|------|
| 5900 | VNC | 虚拟机显示 |
| 3389 | RDP | Windows 远程桌面 |
| 2222 | SSH | Linux SSH |

## 故障排查

### 虚拟机无法启动
```bash
# 检查 QEMU 版本
qemu-system-x86_64 --version

# 检查 KVM 支持
ls -l /dev/kvm

# 检查磁盘镜像
qemu-img check disk.qcow2
```

### VNC 无法连接
```bash
# 检查端口
netstat -tlnp | grep 5900

# 检查防火墙
ufw allow 5900/tcp

# 检查虚拟机进程
ps aux | grep qemu
```

### 性能问题
```bash
# 确认使用 KVM 加速
ps aux | grep qemu | grep kvm

# 增加资源（编辑启动脚本）
MEMORY="16384"  # 增加内存
CPU_CORES="8"   # 增加 CPU 核心
```

### 仍被检测为虚拟机
1. 运行检测脚本找出问题
2. 检查是否使用了 virtio 等虚拟化专用设备
3. 确认 SMBIOS 信息已正确配置
4. 检查 MAC 地址是否使用了 QEMU 默认前缀 (52:54:00)

## 常见硬件厂商参考

### MAC 地址前缀 (OUI)
- Intel: `00:1B:21`
- Realtek: `00:E0:4C`
- Broadcom: `00:10:18`
- Qualcomm: `00:03:7F`

### 主板厂商
- ASUS: ROG STRIX, TUF GAMING, PRIME
- MSI: MAG, MPG, MEG
- Gigabyte: AORUS, Gaming
- ASRock: Phantom Gaming, Steel Legend

## 免责声明

本工具仅供以下合法用途：
- 软件兼容性测试
- 安全研究与分析
- 教育和学习目的
- 硬件环境模拟

请勿将本工具用于：
- 绕过软件授权验证
- 恶意软件分析和传播
- 违反服务条款的行为
- 任何非法活动

使用者需自行承担使用本工具的法律责任。

## 参考资源

- [QEMU 官方文档](https://www.qemu.org/documentation/)
- [SMBIOS 规范](https://www.dmtf.org/standards/smbios)
- [PCI 设备数据库](https://pci-ids.ucw.cz/)
- [MAC 地址 OUI 查询](https://maclookup.app/)

---

**版本**: 1.1
**最后更新**: 2026-02-12
