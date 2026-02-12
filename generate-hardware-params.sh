#!/bin/bash

################################################################################
# 硬件参数随机生成器
# 用途: 生成随机但真实的硬件参数，用于虚拟机配置
################################################################################

echo "=========================================="
echo "  QEMU 虚拟机硬件参数随机生成器"
echo "=========================================="
echo ""

# 生成随机 UUID
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # 手动生成 UUID
        printf '%08x-%04x-%04x-%04x-%012x\n' \
            $RANDOM$RANDOM \
            $RANDOM \
            $((RANDOM & 0x0fff | 0x4000)) \
            $((RANDOM & 0x3fff | 0x8000)) \
            $RANDOM$RANDOM$RANDOM
    fi
}

# 生成随机序列号
generate_serial() {
    local prefix=$1
    local length=$2
    echo "${prefix}$(openssl rand -hex $length | tr '[:lower:]' '[:upper:]')"
}

# 生成随机 MAC 地址
generate_mac() {
    local oui=$1  # 厂商 OUI
    echo "${oui}:$(openssl rand -hex 3 | sed 's/../&:/g;s/:$//')"
}

# 生成随机日期 (过去3年内)
generate_date() {
    local days_ago=$((RANDOM % 1095))  # 0-1095 天
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -v-${days_ago}d "+%m/%d/%Y"
    else
        date -d "$days_ago days ago" "+%m/%d/%Y"
    fi
}

echo "1. 系统信息 (SMBIOS Type 1)"
echo "----------------------------"
SYSTEM_UUID=$(generate_uuid)
SYSTEM_SERIAL=$(generate_serial "SYS" 6)
SYSTEM_ASSET=$(generate_serial "AST" 4)

echo "UUID: $SYSTEM_UUID"
echo "序列号: $SYSTEM_SERIAL"
echo "资产标签: $SYSTEM_ASSET"
echo ""

# 主板制造商列表
MANUFACTURERS=("ASUS" "MSI" "Gigabyte" "ASRock" "Dell Inc." "HP" "Lenovo")
MANUFACTURER=${MANUFACTURERS[$RANDOM % ${#MANUFACTURERS[@]}]}

# 根据制造商选择产品型号
case $MANUFACTURER in
    "ASUS")
        PRODUCTS=("ROG STRIX B550-F GAMING" "TUF GAMING X570-PLUS" "PRIME Z690-P" "ROG MAXIMUS Z690 HERO")
        ;;
    "MSI")
        PRODUCTS=("MAG B550 TOMAHAWK" "MPG Z690 CARBON WIFI" "B450 TOMAHAWK MAX" "X570-A PRO")
        ;;
    "Gigabyte")
        PRODUCTS=("B550 AORUS ELITE" "Z690 AORUS MASTER" "X570 AORUS ULTRA" "B450M DS3H")
        ;;
    "ASRock")
        PRODUCTS=("B550M Steel Legend" "Z690 Taichi" "X570 Phantom Gaming 4" "B450M Pro4")
        ;;
    "Dell Inc.")
        PRODUCTS=("OptiPlex 7090" "Precision 3650" "XPS 8950" "Inspiron 3880")
        ;;
    "HP")
        PRODUCTS=("EliteDesk 800 G8" "ProDesk 600 G6" "Z2 Tower G9" "Pavilion Desktop")
        ;;
    "Lenovo")
        PRODUCTS=("ThinkCentre M90t" "IdeaCentre 5i" "Legion T7" "ThinkStation P350")
        ;;
esac

PRODUCT=${PRODUCTS[$RANDOM % ${#PRODUCTS[@]}]}

echo "制造商: $MANUFACTURER"
echo "产品型号: $PRODUCT"
echo ""

echo "2. BIOS 信息 (SMBIOS Type 0)"
echo "----------------------------"
BIOS_DATE=$(generate_date)
BIOS_VERSIONS=("F10" "F15" "F20" "F23" "1.20" "2.10" "3.05" "A05" "A10")
BIOS_VERSION=${BIOS_VERSIONS[$RANDOM % ${#BIOS_VERSIONS[@]}]}

if [[ $MANUFACTURER == "Dell Inc." ]] || [[ $MANUFACTURER == "HP" ]] || [[ $MANUFACTURER == "Lenovo" ]]; then
    BIOS_VENDOR=$MANUFACTURER
else
    BIOS_VENDOR="American Megatrends Inc."
fi

echo "BIOS 厂商: $BIOS_VENDOR"
echo "BIOS 版本: $BIOS_VERSION"
echo "BIOS 日期: $BIOS_DATE"
echo ""

echo "3. 主板信息 (SMBIOS Type 2)"
echo "----------------------------"
BOARD_SERIAL=$(generate_serial "MB" 6)
BOARD_ASSET=$(generate_serial "AST-MB-" 3)
BOARD_VERSION="Rev 1.0$((RANDOM % 10))"

echo "主板序列号: $BOARD_SERIAL"
echo "主板版本: $BOARD_VERSION"
echo "资产标签: $BOARD_ASSET"
echo ""

echo "4. 机箱信息 (SMBIOS Type 3)"
echo "----------------------------"
CHASSIS_SERIAL=$(generate_serial "CH" 6)
CHASSIS_ASSET=$(generate_serial "AST-CH-" 3)

echo "机箱序列号: $CHASSIS_SERIAL"
echo "资产标签: $CHASSIS_ASSET"
echo ""

echo "5. 硬盘信息"
echo "----------------------------"
HDD_BRANDS=("WDC" "Samsung" "Seagate" "Crucial" "Kingston")
HDD_BRAND=${HDD_BRANDS[$RANDOM % ${#HDD_BRANDS[@]}]}

case $HDD_BRAND in
    "WDC")
        HDD_MODEL="WDC WD10EZEX-08WN4A0"
        HDD_SERIAL=$(generate_serial "WD-WCAV" 4)
        ;;
    "Samsung")
        HDD_MODEL="Samsung SSD 870 EVO 500GB"
        HDD_SERIAL=$(generate_serial "S5H2N" 7)
        ;;
    "Seagate")
        HDD_MODEL="ST1000DM010-2EP102"
        HDD_SERIAL=$(generate_serial "ZN1" 5)
        ;;
    "Crucial")
        HDD_MODEL="CT500MX500SSD1"
        HDD_SERIAL=$(generate_serial "2038" 8)
        ;;
    "Kingston")
        HDD_MODEL="SA400S37480G"
        HDD_SERIAL=$(generate_serial "50026B" 6)
        ;;
esac

# 生成 WWN (World Wide Name)
HDD_WWN=$(printf "0x50014ee%09x" $((RANDOM * RANDOM)))

echo "硬盘品牌: $HDD_BRAND"
echo "硬盘型号: $HDD_MODEL"
echo "硬盘序列号: $HDD_SERIAL"
echo "WWN: $HDD_WWN"
echo ""

echo "6. 网卡信息"
echo "----------------------------"
# 常见网卡厂商 OUI
NIC_VENDORS=("Intel:00:1B:21" "Realtek:00:E0:4C" "Broadcom:00:10:18" "Qualcomm:00:03:7F")
NIC_VENDOR=${NIC_VENDORS[$RANDOM % ${#NIC_VENDORS[@]}]}
NIC_NAME=$(echo $NIC_VENDOR | cut -d: -f1)
NIC_OUI=$(echo $NIC_VENDOR | cut -d: -f2-)

MAC_ADDRESS=$(generate_mac "$NIC_OUI")

echo "网卡厂商: $NIC_NAME"
echo "MAC 地址: $MAC_ADDRESS"
echo ""

echo "=========================================="
echo "  生成的 QEMU 配置参数"
echo "=========================================="
echo ""

cat << EOF
# SMBIOS 配置
-smbios type=0,vendor="$BIOS_VENDOR",version="$BIOS_VERSION",date="$BIOS_DATE" \\
-smbios type=1,manufacturer="$MANUFACTURER",product="$PRODUCT",version="1.0",serial="$SYSTEM_SERIAL",uuid="$SYSTEM_UUID",sku="SKU-001",family="Desktop" \\
-smbios type=2,manufacturer="$MANUFACTURER",product="$PRODUCT",version="$BOARD_VERSION",serial="$BOARD_SERIAL",asset="$BOARD_ASSET",location="Base Board" \\
-smbios type=3,manufacturer="$MANUFACTURER",version="1.0",serial="$CHASSIS_SERIAL",asset="$CHASSIS_ASSET" \\

# 硬盘配置
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \\
-device ide-hd,drive=disk0,serial="$HDD_SERIAL",model="$HDD_MODEL",wwn=$HDD_WWN \\

# 网卡配置
-netdev user,id=net0 \\
-device e1000,netdev=net0,mac=$MAC_ADDRESS
EOF

echo ""
echo "=========================================="
echo "  配置已生成完成"
echo "=========================================="
echo ""
echo "提示: 将上述配置复制到你的 QEMU 启动脚本中"
echo ""

# 可选: 保存到文件
read -p "是否保存配置到文件? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    OUTPUT_FILE="vm-config-$(date +%Y%m%d-%H%M%S).txt"
    cat > "$OUTPUT_FILE" << EOF
# 虚拟机硬件配置
# 生成时间: $(date)

系统 UUID: $SYSTEM_UUID
系统序列号: $SYSTEM_SERIAL
制造商: $MANUFACTURER
产品型号: $PRODUCT

BIOS 厂商: $BIOS_VENDOR
BIOS 版本: $BIOS_VERSION
BIOS 日期: $BIOS_DATE

主板序列号: $BOARD_SERIAL
主板版本: $BOARD_VERSION

机箱序列号: $CHASSIS_SERIAL

硬盘型号: $HDD_MODEL
硬盘序列号: $HDD_SERIAL
WWN: $HDD_WWN

网卡厂商: $NIC_NAME
MAC 地址: $MAC_ADDRESS

---

QEMU 配置参数:

-smbios type=0,vendor="$BIOS_VENDOR",version="$BIOS_VERSION",date="$BIOS_DATE" \\
-smbios type=1,manufacturer="$MANUFACTURER",product="$PRODUCT",version="1.0",serial="$SYSTEM_SERIAL",uuid="$SYSTEM_UUID",sku="SKU-001",family="Desktop" \\
-smbios type=2,manufacturer="$MANUFACTURER",product="$PRODUCT",version="$BOARD_VERSION",serial="$BOARD_SERIAL",asset="$BOARD_ASSET",location="Base Board" \\
-smbios type=3,manufacturer="$MANUFACTURER",version="1.0",serial="$CHASSIS_SERIAL",asset="$CHASSIS_ASSET" \\
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \\
-device ide-hd,drive=disk0,serial="$HDD_SERIAL",model="$HDD_MODEL",wwn=$HDD_WWN \\
-netdev user,id=net0 \\
-device e1000,netdev=net0,mac=$MAC_ADDRESS
EOF
    echo "配置已保存到: $OUTPUT_FILE"
fi
