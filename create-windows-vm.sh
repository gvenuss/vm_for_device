#!/bin/bash

################################################################################
# Windows 10/11 虚拟机启动脚本 (反虚拟化检测配置)
# 用途: 创建一个难以被检测为虚拟机的 Windows 环境
################################################################################

# 配置参数
VM_NAME="Windows-Desktop"
DISK_IMAGE="windows10.qcow2"
DISK_SIZE="100G"
MEMORY="8192"  # MB
CPU_CORES="4"
CPU_THREADS="2"

# 硬件信息自定义
BIOS_VENDOR="American Megatrends Inc."
BIOS_VERSION="F23"
BIOS_DATE="08/12/2021"

SYSTEM_MANUFACTURER="ASUS"
SYSTEM_PRODUCT="ROG STRIX B550-F GAMING"
SYSTEM_VERSION="1.0"
SYSTEM_SERIAL="SYS20210812001"
SYSTEM_UUID="a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
SYSTEM_SKU="SKU-ROG-001"
SYSTEM_FAMILY="Desktop"

BOARD_MANUFACTURER="ASUS"
BOARD_PRODUCT="ROG STRIX B550-F GAMING"
BOARD_VERSION="Rev 1.02"
BOARD_SERIAL="MB20210812001"
BOARD_ASSET="Asset-MB-001"

CHASSIS_MANUFACTURER="ASUS"
CHASSIS_VERSION="1.0"
CHASSIS_SERIAL="CH20210812001"
CHASSIS_ASSET="Asset-CH-001"

# 硬盘信息
HDD_SERIAL="WD-WCAV29472851"
HDD_MODEL="WDC WD10EZEX-08WN4A0"
HDD_WWN="0x50014ee2b5c6d8e9"

# 网卡 MAC 地址 (Intel OUI)
MAC_ADDRESS="00:1B:21:3A:4F:5C"

# 检查磁盘镜像是否存在
if [ ! -f "$DISK_IMAGE" ]; then
    echo "磁盘镜像不存在，正在创建 $DISK_IMAGE ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
    echo "磁盘镜像创建完成"
    echo ""
    echo "请挂载 Windows 安装 ISO 并安装系统"
    echo "使用方法: 在下面的命令中添加 -cdrom windows.iso -boot d"
    echo ""
fi

# 检测加速器
ACCEL="tcg"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -e /dev/kvm ]; then
        ACCEL="kvm"
        echo "使用 KVM 硬件加速"
    else
        echo "警告: KVM 不可用，使用软件模拟 (性能较差)"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ACCEL="hvf"
    echo "使用 macOS Hypervisor Framework 加速"
fi

echo "启动虚拟机: $VM_NAME"
echo "内存: ${MEMORY}MB, CPU: ${CPU_CORES}核${CPU_THREADS}线程"
echo "磁盘: $DISK_IMAGE"
echo "MAC: $MAC_ADDRESS"
echo "VNC 端口: 5900 (使用 VNC 客户端连接)"
echo ""

# 启动 QEMU
qemu-system-x86_64 \
  -name "$VM_NAME" \
  -machine type=q35,accel=$ACCEL \
  -cpu host,kvm=off,hv_vendor_id=GenuineIntel,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
  -smp cores=$CPU_CORES,threads=$CPU_THREADS,sockets=1 \
  -m $MEMORY \
  \
  -smbios type=0,vendor="$BIOS_VENDOR",version="$BIOS_VERSION",date="$BIOS_DATE" \
  -smbios type=1,manufacturer="$SYSTEM_MANUFACTURER",product="$SYSTEM_PRODUCT",version="$SYSTEM_VERSION",serial="$SYSTEM_SERIAL",uuid="$SYSTEM_UUID",sku="$SYSTEM_SKU",family="$SYSTEM_FAMILY" \
  -smbios type=2,manufacturer="$BOARD_MANUFACTURER",product="$BOARD_PRODUCT",version="$BOARD_VERSION",serial="$BOARD_SERIAL",asset="$BOARD_ASSET",location="Base Board" \
  -smbios type=3,manufacturer="$CHASSIS_MANUFACTURER",version="$CHASSIS_VERSION",serial="$CHASSIS_SERIAL",asset="$CHASSIS_ASSET" \
  \
  -drive file="$DISK_IMAGE",if=none,id=disk0,format=qcow2,cache=writeback \
  -device ide-hd,drive=disk0,serial="$HDD_SERIAL",model="$HDD_MODEL",wwn=$HDD_WWN \
  \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  -device e1000,netdev=net0,mac=$MAC_ADDRESS \
  \
  -vga qxl \
  -vnc :0 \
  -device qemu-xhci,id=xhci \
  -device usb-tablet,bus=xhci.0 \
  \
  -boot order=c \
  -rtc base=localtime,clock=host \
  -no-hpet \
  -global kvm-pit.lost_tick_policy=discard

# 如果需要安装系统，取消下面两行的注释
# -cdrom windows.iso \
# -boot d \
