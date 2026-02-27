#!/bin/bash

################################################################################
# Windows 10/11 虚拟机启动脚本 (反虚拟化检测配置)
# 用途: 创建一个难以被检测为虚拟机的 Windows 环境
# 支持从 generate-hardware-params.sh 自动加载配置
################################################################################

# 检查是否传入配置文件
if [ "$1" = "--config" ] && [ -n "$2" ]; then
    echo "加载配置文件: $2"
    if [ -f "$2" ]; then
        # 尝试加载配置
        if grep -q "# 硬件信息自定义" "$2"; then
            # 提取配置变量
            TMP_CONFIG=$(mktemp /tmp/vm-tmp-config.XXXXXX)
            grep -A 40 "# 硬件信息自定义" "$2" > $TMP_CONFIG
            # 尝试执行配置（安全检查）
            if grep -E '^(BIOS_VENDOR|BIOS_VERSION|BIOS_DATE|SYSTEM_MANUFACTURER|SYSTEM_PRODUCT|SYSTEM_VERSION|SYSTEM_SERIAL|SYSTEM_UUID|SYSTEM_SKU|SYSTEM_FAMILY|BOARD_MANUFACTURER|BOARD_PRODUCT|BOARD_VERSION|BOARD_SERIAL|BOARD_ASSET|CHASSIS_MANUFACTURER|CHASSIS_VERSION|CHASSIS_SERIAL|CHASSIS_ASSET|GPU_VENDOR|GPU_MODEL|GPU_VENDOR_ID|GPU_DEVICE_ID|GPU_VRAM|GPU_MEM_TYPE|GPU_SERIAL|GPU_BIOS_VERSION|SOUND_CARD|SOUND_VENDOR|SOUND_SERIAL|RAM_BRAND|RAM_CAPACITY|RAM_SPEED|RAM_TYPE|RAM_SERIAL|RAM_PART_NUMBER|PSU_BRAND|PSU_MODEL|PSU_WATTAGE|PSU_SERIAL|HDD_SERIAL|HDD_MODEL|HDD_WWN|MAC_ADDRESS)=' $TMP_CONFIG > /dev/null 2>&1; then
                source $TMP_CONFIG
                echo "✓ 配置加载成功"
            else
                echo "警告: 配置文件格式不正确，使用默认配置"
            fi
        else
            echo "警告: 配置文件不是 generate-hardware-params.sh 格式，使用默认配置"
        fi
        rm -f $TMP_CONFIG
    else
        echo "警告: 配置文件不存在，使用默认配置"
    fi
elif [ "$1" = "--generate" ]; then
    echo "自动生成新配置并启动..."
    # 获取脚本所在的绝对路径
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TMP_CONFIG=$(mktemp /tmp/vm-gen-config.XXXXXX)
    "$SCRIPT_DIR/generate-hardware-params.sh" > $TMP_CONFIG 2>&1
    if [ $? -eq 0 ]; then
        # 提取配置变量
        grep -A 40 "# 硬件信息自定义" $TMP_CONFIG > /tmp/vm-extract-config.txt
        source /tmp/vm-extract-config.txt
        echo "✓ 配置生成并加载成功"
        rm -f /tmp/vm-extract-config.txt
    else
        echo "警告: 配置生成失败，使用默认配置"
    fi
else
    echo "使用默认配置启动"
fi

# 配置参数 - 确保这些参数不会被配置文件覆盖
VM_NAME="${VM_NAME:-"Windows-Desktop"}"
DISK_IMAGE="${DISK_IMAGE:-"windows10.qcow2"}"
DISK_SIZE="${DISK_SIZE:-"100G"}"
MEMORY="${MEMORY:-"8192"}"  # MB
CPU_CORES="${CPU_CORES:-"4"}"
CPU_THREADS="${CPU_THREADS:-"2"}"
ISO_PATH="${ISO_PATH:-"/app/windows_vm/windows.iso"}"

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

# 显卡信息
GPU_VENDOR="NVIDIA"
GPU_MODEL="GeForce RTX 3060"
GPU_VENDOR_ID="10DE"
GPU_DEVICE_ID="2487"
GPU_VRAM="8GB"
GPU_MEM_TYPE="GDDR6"
GPU_SERIAL="NV20210812001"
GPU_BIOS_VERSION="86.04.45.00"

# 声卡信息
SOUND_CARD="Realtek ALC887"
SOUND_VENDOR="Realtek"
SOUND_SERIAL="SND20210812001"

# 内存信息
RAM_BRAND="${RAM_BRAND:-"Samsung"}"
RAM_CAPACITY="${RAM_CAPACITY:-"16GB"}"
RAM_SPEED="${RAM_SPEED:-"3200MHz"}"
RAM_TYPE="${RAM_TYPE:-"DDR4"}"
RAM_SERIAL="${RAM_SERIAL:-"SM20210812001"}"
RAM_PART_NUMBER="${RAM_PART_NUMBER:-"SMG2021"}"

# 电源信息
PSU_BRAND="${PSU_BRAND:-"Corsair"}"
PSU_MODEL="${PSU_MODEL:-"Corsair RM650x"}"
PSU_WATTAGE="${PSU_WATTAGE:-"650W"}"
PSU_SERIAL="${PSU_SERIAL:-"CS20210812001"}"

# 硬盘信息
HDD_SERIAL="WD-WCAV29472851"
HDD_MODEL="WDC WD10EZEX-08WN4A0"
HDD_WWN="0x50014ee2b5c6d8e9"

# 网卡 MAC 地址 (Intel OUI)
MAC_ADDRESS="00:1B:21:3A:4F:5C"

# 检查 ISO 文件是否存在
if [ ! -f "$ISO_PATH" ]; then
    echo "错误: ISO 文件不存在: $ISO_PATH"
    exit 1
fi

# 检查磁盘镜像是否存在
FIRST_BOOT=false
if [ ! -f "$DISK_IMAGE" ]; then
    echo "磁盘镜像不存在，正在创建 $DISK_IMAGE ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
    echo "磁盘镜像创建完成"
    echo ""
    echo "首次启动，将从 ISO 安装 Windows"
    FIRST_BOOT=true
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
echo "ISO: $ISO_PATH"
echo "MAC: $MAC_ADDRESS"
echo "VNC 端口: 5900 (使用 VNC 客户端连接)"
echo ""

# 设置启动顺序
if [ "$FIRST_BOOT" = true ]; then
    BOOT_ORDER="d"  # 从光驱启动（安装系统）
    echo "首次启动: 从 ISO 安装 Windows"
else
    BOOT_ORDER="c"  # 从硬盘启动
    echo "从硬盘启动已安装的系统"
fi
echo ""

# 启动 QEMU
qemu-system-x86_64 \
  -name "$VM_NAME" \
  -machine type=q35,accel=$ACCEL,vmport=off \
  -cpu host,kvm=off,hypervisor=off,hv_vendor_id=GenuineIntel,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,hv_reset,hv_vpindex,hv_runtime,hv_synic,hv_stimer,hv_msr_bitmap \
  -smp cores=$CPU_CORES,threads=$CPU_THREADS,sockets=1 \
  -m $MEMORY,slots=4,maxmem=$((MEMORY * 2))M \
  -smbios type=0,vendor="$BIOS_VENDOR",version="$BIOS_VERSION",date="$BIOS_DATE" \
  -smbios type=1,manufacturer="$SYSTEM_MANUFACTURER",product="$SYSTEM_PRODUCT",version="$SYSTEM_VERSION",serial="$SYSTEM_SERIAL",uuid="$SYSTEM_UUID",sku="$SYSTEM_SKU",family="$SYSTEM_FAMILY" \
  -smbios type=2,manufacturer="$BOARD_MANUFACTURER",product="$BOARD_PRODUCT",version="$BOARD_VERSION",serial="$BOARD_SERIAL",asset="$BOARD_ASSET",location="Base Board" \
  -smbios type=3,manufacturer="$CHASSIS_MANUFACTURER",version="$CHASSIS_VERSION",serial="$CHASSIS_SERIAL",asset="$CHASSIS_ASSET" \
  -drive file="$DISK_IMAGE",if=none,id=disk0,format=qcow2,cache=writeback \
  -device ich9-ahci,id=ahci0,bus=pcie.0,addr=0x4 \
  -device ide-hd,drive=disk0,bus=ahci0.0,serial="$HDD_SERIAL",model="$HDD_MODEL",wwn=$HDD_WWN \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  -device e1000e,netdev=net0,mac=$MAC_ADDRESS,id=net0,bus=pcie.0,addr=0x5 \
  -audiodev none,id=audio0 \
  -device intel-hda,id=sound0,bus=pcie.0,addr=0x3 \
  -device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0,audiodev=audio0 \
  -device virtio-vga-gl,xres=1920,yres=1080,id=video0,bus=pcie.0,addr=0x2 \
  -vnc :0 \
  -device ich9-usb-ehci1,id=ehci,bus=pcie.0,addr=0x6 \
  -device ich9-usb-uhci1,masterbus=ehci.0,firstport=0,bus=pcie.0,multifunction=on,addr=0x6.0x0 \
  -device ich9-usb-uhci2,masterbus=ehci.0,firstport=2,bus=pcie.0,multifunction=on,addr=0x6.0x1 \
  -device ich9-usb-uhci3,masterbus=ehci.0,firstport=4,bus=pcie.0,multifunction=on,addr=0x6.0x2 \
  -device usb-mouse,bus=ehci.0 \
  -device usb-kbd,bus=ehci.0 \
  -cdrom "$ISO_PATH" \
  -boot order=$BOOT_ORDER \
  -rtc base=localtime,clock=host \
  -no-hpet \
  -global kvm-pit.lost_tick_policy=discard \
  -global ich9-pm.disable_s3=1 \
  -global ich9-pm.disable_s4=1 \
  -device ich9-intel-hda,addr=0x1b,multifunction=on \
  -device virtio-balloon-pci,id=balloon0,bus=pcie.0,addr=0x7,disable-legacy=on \
  -device ipmi-bmc-sim,id=bmc0 \
  -device isa-ipmi-kcs,id=ipmi0,irq=5,ioaddr=0xca2,bmc=0 \
  -nodefaults \
  -device i82801b11-bridge,id=pci.1,bus=pcie.0,addr=0x1 \
  -device pci-bridge,chassis_nr=2,id=pci.2,bus=pci.1,addr=0x1
