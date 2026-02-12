#!/bin/bash

################################################################################
# 虚拟化检测测试脚本 (Linux)
# 用途: 在虚拟机内运行，检测是否能被识别为虚拟机
################################################################################

echo "=========================================="
echo "  虚拟化检测测试工具"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DETECTED=0
TOTAL_TESTS=0

print_result() {
    local test_name=$1
    local result=$2
    local details=$3

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}[✓]${NC} $test_name"
        [ -n "$details" ] && echo "    $details"
    elif [ "$result" == "FAIL" ]; then
        echo -e "${RED}[✗]${NC} $test_name"
        [ -n "$details" ] && echo "    $details"
        DETECTED=$((DETECTED + 1))
    else
        echo -e "${YELLOW}[?]${NC} $test_name"
        [ -n "$details" ] && echo "    $details"
    fi
}

echo "1. 检测虚拟化工具"
echo "----------------------------"

# systemd-detect-virt
if command -v systemd-detect-virt &> /dev/null; then
    VIRT_RESULT=$(systemd-detect-virt)
    if [ "$VIRT_RESULT" == "none" ]; then
        print_result "systemd-detect-virt" "PASS" "检测结果: none (未检测到虚拟化)"
    else
        print_result "systemd-detect-virt" "FAIL" "检测结果: $VIRT_RESULT (检测到虚拟化)"
    fi
else
    print_result "systemd-detect-virt" "SKIP" "工具未安装"
fi

# virt-what
if command -v virt-what &> /dev/null; then
    VIRT_WHAT_RESULT=$(sudo virt-what 2>/dev/null)
    if [ -z "$VIRT_WHAT_RESULT" ]; then
        print_result "virt-what" "PASS" "未检测到虚拟化"
    else
        print_result "virt-what" "FAIL" "检测结果: $VIRT_WHAT_RESULT"
    fi
else
    print_result "virt-what" "SKIP" "工具未安装 (需要 root 权限)"
fi

echo ""
echo "2. CPU 信息检测"
echo "----------------------------"

# 检查 CPU 型号
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
if echo "$CPU_MODEL" | grep -iq "qemu\|virtual\|kvm"; then
    print_result "CPU 型号" "FAIL" "$CPU_MODEL (包含虚拟化关键字)"
else
    print_result "CPU 型号" "PASS" "$CPU_MODEL"
fi

# 检查 hypervisor 标志
if grep -q "hypervisor" /proc/cpuinfo; then
    print_result "Hypervisor 标志" "FAIL" "CPU 包含 hypervisor 标志"
else
    print_result "Hypervisor 标志" "PASS" "未检测到 hypervisor 标志"
fi

# 检查 CPUID
if command -v cpuid &> /dev/null; then
    CPUID_RESULT=$(cpuid | grep -i "hypervisor")
    if [ -n "$CPUID_RESULT" ]; then
        print_result "CPUID 检测" "FAIL" "检测到 hypervisor 特征"
    else
        print_result "CPUID 检测" "PASS" "未检测到虚拟化特征"
    fi
else
    print_result "CPUID 检测" "SKIP" "cpuid 工具未安装"
fi

echo ""
echo "3. DMI/SMBIOS 信息检测"
echo "----------------------------"

if command -v dmidecode &> /dev/null; then
    # 检查系统制造商
    SYS_MANUFACTURER=$(sudo dmidecode -s system-manufacturer 2>/dev/null)
    if echo "$SYS_MANUFACTURER" | grep -iq "qemu\|bochs\|virtual\|vmware\|virtualbox\|xen\|kvm"; then
        print_result "系统制造商" "FAIL" "$SYS_MANUFACTURER (包含虚拟化关键字)"
    else
        print_result "系统制造商" "PASS" "$SYS_MANUFACTURER"
    fi

    # 检查系统产品名
    SYS_PRODUCT=$(sudo dmidecode -s system-product-name 2>/dev/null)
    if echo "$SYS_PRODUCT" | grep -iq "qemu\|bochs\|virtual\|vmware\|virtualbox\|xen\|kvm"; then
        print_result "系统产品名" "FAIL" "$SYS_PRODUCT (包含虚拟化关键字)"
    else
        print_result "系统产品名" "PASS" "$SYS_PRODUCT"
    fi

    # 检查 BIOS 厂商
    BIOS_VENDOR=$(sudo dmidecode -s bios-vendor 2>/dev/null)
    if echo "$BIOS_VENDOR" | grep -iq "qemu\|bochs\|virtual\|vmware\|virtualbox\|xen\|kvm"; then
        print_result "BIOS 厂商" "FAIL" "$BIOS_VENDOR (包含虚拟化关键字)"
    else
        print_result "BIOS 厂商" "PASS" "$BIOS_VENDOR"
    fi

    # 检查主板制造商
    BOARD_MANUFACTURER=$(sudo dmidecode -s baseboard-manufacturer 2>/dev/null)
    if echo "$BOARD_MANUFACTURER" | grep -iq "qemu\|bochs\|virtual\|vmware\|virtualbox\|xen\|kvm"; then
        print_result "主板制造商" "FAIL" "$BOARD_MANUFACTURER (包含虚拟化关键字)"
    else
        print_result "主板制造商" "PASS" "$BOARD_MANUFACTURER"
    fi
else
    print_result "DMI 信息检测" "SKIP" "dmidecode 未安装 (需要 root 权限)"
fi

echo ""
echo "4. 硬盘信息检测"
echo "----------------------------"

# 检查硬盘型号
if [ -b /dev/sda ]; then
    DISK_MODEL=$(sudo hdparm -I /dev/sda 2>/dev/null | grep "Model Number" | cut -d: -f2 | xargs)
    if echo "$DISK_MODEL" | grep -iq "qemu\|virtual\|vbox"; then
        print_result "硬盘型号" "FAIL" "$DISK_MODEL (包含虚拟化关键字)"
    else
        print_result "硬盘型号" "PASS" "$DISK_MODEL"
    fi

    DISK_SERIAL=$(sudo hdparm -I /dev/sda 2>/dev/null | grep "Serial Number" | cut -d: -f2 | xargs)
    if echo "$DISK_SERIAL" | grep -iq "qm\|vb"; then
        print_result "硬盘序列号" "FAIL" "$DISK_SERIAL (可能是虚拟硬盘)"
    else
        print_result "硬盘序列号" "PASS" "$DISK_SERIAL"
    fi
else
    print_result "硬盘检测" "SKIP" "未找到 /dev/sda"
fi

echo ""
echo "5. 网络设备检测"
echo "----------------------------"

# 检查网卡型号
NET_DEVICES=$(lspci | grep -i "ethernet\|network")
if echo "$NET_DEVICES" | grep -iq "virtio\|qemu\|virtual"; then
    print_result "网卡设备" "FAIL" "检测到虚拟网卡"
    echo "    $NET_DEVICES"
else
    print_result "网卡设备" "PASS" "未检测到虚拟网卡特征"
fi

# 检查 MAC 地址
MAC_ADDRESSES=$(ip link show | grep "link/ether" | awk '{print $2}')
QEMU_MAC=0
while IFS= read -r mac; do
    # QEMU 默认 MAC 前缀: 52:54:00
    if echo "$mac" | grep -iq "^52:54:00"; then
        print_result "MAC 地址" "FAIL" "$mac (QEMU 默认前缀)"
        QEMU_MAC=1
    fi
done <<< "$MAC_ADDRESSES"

if [ $QEMU_MAC -eq 0 ]; then
    print_result "MAC 地址" "PASS" "未检测到 QEMU 默认 MAC 前缀"
fi

echo ""
echo "6. PCI 设备检测"
echo "----------------------------"

# 检查 PCI 设备
PCI_DEVICES=$(lspci)
if echo "$PCI_DEVICES" | grep -iq "qemu\|virtio\|bochs\|vmware\|virtualbox"; then
    print_result "PCI 设备" "FAIL" "检测到虚拟化 PCI 设备"
    echo "$PCI_DEVICES" | grep -i "qemu\|virtio\|bochs\|vmware\|virtualbox" | sed 's/^/    /'
else
    print_result "PCI 设备" "PASS" "未检测到虚拟化 PCI 设备"
fi

echo ""
echo "7. 内核模块检测"
echo "----------------------------"

# 检查虚拟化相关内核模块
VIRT_MODULES=$(lsmod | grep -i "kvm\|virtio\|vbox\|vmw")
if [ -n "$VIRT_MODULES" ]; then
    print_result "内核模块" "FAIL" "检测到虚拟化内核模块"
    echo "$VIRT_MODULES" | sed 's/^/    /'
else
    print_result "内核模块" "PASS" "未检测到虚拟化内核模块"
fi

echo ""
echo "8. 文件系统检测"
echo "----------------------------"

# 检查 /sys/class/dmi/id/
if [ -d /sys/class/dmi/id/ ]; then
    DMI_FILES=$(grep -r "qemu\|bochs\|virtual" /sys/class/dmi/id/ 2>/dev/null)
    if [ -n "$DMI_FILES" ]; then
        print_result "DMI 文件系统" "FAIL" "在 DMI 文件中发现虚拟化关键字"
    else
        print_result "DMI 文件系统" "PASS" "DMI 文件未包含虚拟化关键字"
    fi
else
    print_result "DMI 文件系统" "SKIP" "/sys/class/dmi/id/ 不存在"
fi

echo ""
echo "=========================================="
echo "  检测结果汇总"
echo "=========================================="
echo ""
echo "总测试数: $TOTAL_TESTS"
echo "检测到虚拟化: $DETECTED"
echo "通过测试: $((TOTAL_TESTS - DETECTED))"
echo ""

if [ $DETECTED -eq 0 ]; then
    echo -e "${GREEN}✓ 优秀! 未检测到明显的虚拟化特征${NC}"
    echo "该虚拟机配置较好地隐藏了虚拟化标识"
elif [ $DETECTED -le 3 ]; then
    echo -e "${YELLOW}⚠ 警告: 检测到少量虚拟化特征${NC}"
    echo "建议检查并优化失败的测试项"
else
    echo -e "${RED}✗ 注意: 检测到较多虚拟化特征${NC}"
    echo "该虚拟机容易被识别，建议重新配置"
fi

echo ""
echo "提示: 某些检测需要 root 权限，使用 sudo 运行以获得完整结果"
echo ""
