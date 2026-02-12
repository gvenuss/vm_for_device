#!/bin/bash

################################################################################
# Linux 虚拟机启动脚本 (反虚拟化检测配置)
# 用途: 创建一个难以被检测为虚拟机的 Linux 环境
################################################################################

# 配置参数
VM_NAME="Ubuntu-Desktop"
DISK_IMAGE="ubuntu.qcow2"
DISK_SIZE="80G"
MEMORY="4096"  # MB
CPU_CORES="4"

# 硬件信息自定义
SYSTEM_MANUFACTURER="Dell Inc."
SYSTEM_PRODUCT="OptiPlex 7090"
SYSTEM_SERIAL="DELL-SN-$(openssl rand -hex 6 | tr '[:lower:]' '[:upper:]')"

# 硬盘信息
HDD_SERIAL="SAMSUNG-$(openssl rand -hex 8 | tr '[:lower:]' '[:upper:]')"
HDD_MODEL="Samsung SSD 870 EVO 500GB"

# 网卡 MAC 地址 (Realtek OUI)
MAC_ADDRESS="00:E0:4C:$(openssl rand -hex 3 | sed 's/../&:/g;s/:$//')"

# 检查磁盘镜像是否存在
if [ ! -f "$DISK_IMAGE" ]; then
    echo "磁盘镜像不存在，正在创建 $DISK_IMAGE ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
    echo "磁盘镜像创建完成"
    echo ""
    echo "请挂载 Linux 安装 ISO 并安装系统"
    echo "使用方法: 在下面的命令中添加 -cdrom ubuntu.iso -boot d"
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
echo "内存: ${MEMORY}MB, CPU: ${CPU_CORES}核"
echo "磁盘: $DISK_IMAGE"
echo "系统序列号: $SYSTEM_SERIAL"
echo "硬盘序列号: $HDD_SERIAL"
echo "MAC: $MAC_ADDRESS"
echo "VNC 端口: 5900 (使用 VNC 客户端连接)"
echo ""

# 启动 QEMU
qemu-system-x86_64 \
  -name "$VM_NAME" \
  -machine type=q35,accel=$ACCEL \
  -cpu host,kvm=off \
  -smp $CPU_CORES \
  -m $MEMORY \
  \
  -smbios type=1,manufacturer="$SYSTEM_MANUFACTURER",product="$SYSTEM_PRODUCT",serial="$SYSTEM_SERIAL" \
  \
  -drive file="$DISK_IMAGE",if=none,id=disk0,format=qcow2 \
  -device ide-hd,drive=disk0,serial="$HDD_SERIAL",model="$HDD_MODEL" \
  \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=net0,mac=$MAC_ADDRESS \
  \
  -vga virtio \
  -vnc :0 \
  -device qemu-xhci,id=xhci \
  -device usb-tablet,bus=xhci.0 \
  \
  -boot order=c \
  -rtc base=utc,clock=host

# 如果需要安装系统，取消下面两行的注释
# -cdrom ubuntu-22.04.iso \
# -boot d \
