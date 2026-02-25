#!/bin/bash

################################################################################
# 硬件参数随机生成器
# 用途: 生成随机但真实的硬件参数，用于虚拟机配置
# 特点: 确保硬件配置符合物理世界的逻辑关系
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

# 生成随机日期 (根据硬件代际)
generate_date_range() {
    local start_year=$1
    local end_year=$2
    local start_days=$(( (start_year - 2020) * 365 ))
    local end_days=$(( (end_year - 2020) * 365 ))
    local days_range=$(( end_days - start_days ))
    local days_ago=$(( end_days - (RANDOM % days_range) ))

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

# 首先决定是品牌机还是 DIY 组装机
SYSTEM_TYPES=("OEM" "DIY")
SYSTEM_TYPE=${SYSTEM_TYPES[$RANDOM % ${#SYSTEM_TYPES[@]}]}

if [[ $SYSTEM_TYPE == "OEM" ]]; then
    # 品牌机配置
    OEM_BRANDS=("Dell Inc." "HP" "Lenovo")
    MANUFACTURER=${OEM_BRANDS[$RANDOM % ${#OEM_BRANDS[@]}]}

    case $MANUFACTURER in
        "Dell Inc.")
            PRODUCTS=("OptiPlex 7090:Intel:11:2021:2023" "Precision 3650:Intel:11:2021:2023" "XPS 8950:Intel:12:2022:2024" "Inspiron 3880:Intel:10:2020:2022")
            ;;
        "HP")
            PRODUCTS=("EliteDesk 800 G8:Intel:11:2021:2023" "ProDesk 600 G6:Intel:10:2020:2022" "Z2 Tower G9:Intel:12:2022:2024" "Pavilion Desktop:AMD:5000:2021:2023")
            ;;
        "Lenovo")
            PRODUCTS=("ThinkCentre M90t:Intel:11:2021:2023" "IdeaCentre 5i:Intel:10:2020:2022" "Legion T7:AMD:5000:2021:2023" "ThinkStation P350:Intel:11:2021:2023")
            ;;
    esac
else
    # DIY 组装机配置
    DIY_BRANDS=("ASUS" "MSI" "Gigabyte" "ASRock")
    MANUFACTURER=${DIY_BRANDS[$RANDOM % ${#DIY_BRANDS[@]}]}

    # 先随机选择 CPU 平台
    CPU_PLATFORMS=("Intel:12:2022:2024" "Intel:11:2021:2023" "Intel:10:2020:2022" "AMD:5000:2021:2023" "AMD:3000:2019:2021")
    CPU_PLATFORM=${CPU_PLATFORMS[$RANDOM % ${#CPU_PLATFORMS[@]}]}

    CPU_VENDOR=$(echo $CPU_PLATFORM | cut -d: -f1)
    CPU_GEN=$(echo $CPU_PLATFORM | cut -d: -f2)
    YEAR_START=$(echo $CPU_PLATFORM | cut -d: -f3)
    YEAR_END=$(echo $CPU_PLATFORM | cut -d: -f4)

    # 根据 CPU 平台选择匹配的主板
    case $MANUFACTURER in
        "ASUS")
            if [[ $CPU_VENDOR == "Intel" ]]; then
                case $CPU_GEN in
                    "12") PRODUCTS=("ROG MAXIMUS Z690 HERO:Intel:12:2022:2024" "TUF GAMING Z690-PLUS:Intel:12:2022:2024" "PRIME Z690-P:Intel:12:2022:2024") ;;
                    "11") PRODUCTS=("ROG MAXIMUS XIII HERO:Intel:11:2021:2023" "TUF GAMING Z590-PLUS:Intel:11:2021:2023" "PRIME Z590-P:Intel:11:2021:2023") ;;
                    "10") PRODUCTS=("ROG MAXIMUS XII HERO:Intel:10:2020:2022" "TUF GAMING Z490-PLUS:Intel:10:2020:2022" "PRIME Z490-P:Intel:10:2020:2022") ;;
                esac
            else
                case $CPU_GEN in
                    "5000") PRODUCTS=("ROG STRIX X570-E GAMING:AMD:5000:2021:2023" "TUF GAMING X570-PLUS:AMD:5000:2021:2023" "ROG STRIX B550-F GAMING:AMD:5000:2021:2023") ;;
                    "3000") PRODUCTS=("ROG STRIX X570-E GAMING:AMD:3000:2019:2021" "TUF GAMING X570-PLUS:AMD:3000:2019:2021" "PRIME X570-P:AMD:3000:2019:2021") ;;
                esac
            fi
            ;;
        "MSI")
            if [[ $CPU_VENDOR == "Intel" ]]; then
                case $CPU_GEN in
                    "12") PRODUCTS=("MPG Z690 CARBON WIFI:Intel:12:2022:2024" "MAG Z690 TOMAHAWK WIFI:Intel:12:2022:2024" "PRO Z690-A:Intel:12:2022:2024") ;;
                    "11") PRODUCTS=("MPG Z590 GAMING CARBON WIFI:Intel:11:2021:2023" "MAG Z590 TOMAHAWK WIFI:Intel:11:2021:2023" "PRO Z590-A:Intel:11:2021:2023") ;;
                    "10") PRODUCTS=("MPG Z490 GAMING CARBON WIFI:Intel:10:2020:2022" "MAG Z490 TOMAHAWK:Intel:10:2020:2022" "Z490-A PRO:Intel:10:2020:2022") ;;
                esac
            else
                case $CPU_GEN in
                    "5000") PRODUCTS=("MPG X570 GAMING EDGE WIFI:AMD:5000:2021:2023" "MAG B550 TOMAHAWK:AMD:5000:2021:2023" "B550-A PRO:AMD:5000:2021:2023") ;;
                    "3000") PRODUCTS=("MPG X570 GAMING PLUS:AMD:3000:2019:2021" "B450 TOMAHAWK MAX:AMD:3000:2019:2021" "X570-A PRO:AMD:3000:2019:2021") ;;
                esac
            fi
            ;;
        "Gigabyte")
            if [[ $CPU_VENDOR == "Intel" ]]; then
                case $CPU_GEN in
                    "12") PRODUCTS=("Z690 AORUS MASTER:Intel:12:2022:2024" "Z690 AORUS ELITE:Intel:12:2022:2024" "Z690 UD:Intel:12:2022:2024") ;;
                    "11") PRODUCTS=("Z590 AORUS MASTER:Intel:11:2021:2023" "Z590 AORUS ELITE:Intel:11:2021:2023" "Z590 UD:Intel:11:2021:2023") ;;
                    "10") PRODUCTS=("Z490 AORUS MASTER:Intel:10:2020:2022" "Z490 AORUS ELITE:Intel:10:2020:2022" "Z490 UD:Intel:10:2020:2022") ;;
                esac
            else
                case $CPU_GEN in
                    "5000") PRODUCTS=("X570 AORUS MASTER:AMD:5000:2021:2023" "B550 AORUS ELITE:AMD:5000:2021:2023" "B550M DS3H:AMD:5000:2021:2023") ;;
                    "3000") PRODUCTS=("X570 AORUS ULTRA:AMD:3000:2019:2021" "B450 AORUS M:AMD:3000:2019:2021" "B450M DS3H:AMD:3000:2019:2021") ;;
                esac
            fi
            ;;
        "ASRock")
            if [[ $CPU_VENDOR == "Intel" ]]; then
                case $CPU_GEN in
                    "12") PRODUCTS=("Z690 Taichi:Intel:12:2022:2024" "Z690 Steel Legend:Intel:12:2022:2024" "Z690 Pro RS:Intel:12:2022:2024") ;;
                    "11") PRODUCTS=("Z590 Taichi:Intel:11:2021:2023" "Z590 Steel Legend:Intel:11:2021:2023" "Z590 Pro4:Intel:11:2021:2023") ;;
                    "10") PRODUCTS=("Z490 Taichi:Intel:10:2020:2022" "Z490 Steel Legend:Intel:10:2020:2022" "Z490 Pro4:Intel:10:2020:2022") ;;
                esac
            else
                case $CPU_GEN in
                    "5000") PRODUCTS=("X570 Taichi:AMD:5000:2021:2023" "B550M Steel Legend:AMD:5000:2021:2023" "B550 Pro4:AMD:5000:2021:2023") ;;
                    "3000") PRODUCTS=("X570 Phantom Gaming 4:AMD:3000:2019:2021" "B450M Pro4:AMD:3000:2019:2021" "B450M Steel Legend:AMD:3000:2019:2021") ;;
                esac
            fi
            ;;
    esac
fi

# 解析产品信息
PRODUCT_INFO=${PRODUCTS[$RANDOM % ${#PRODUCTS[@]}]}
PRODUCT=$(echo $PRODUCT_INFO | cut -d: -f1)
PRODUCT_CPU_VENDOR=$(echo $PRODUCT_INFO | cut -d: -f2)
PRODUCT_CPU_GEN=$(echo $PRODUCT_INFO | cut -d: -f3)
PRODUCT_YEAR_START=$(echo $PRODUCT_INFO | cut -d: -f4)
PRODUCT_YEAR_END=$(echo $PRODUCT_INFO | cut -d: -f5)

echo "制造商: $MANUFACTURER"
echo "产品型号: $PRODUCT"
echo "系统类型: $SYSTEM_TYPE"
echo ""

# 2. CPU 信息 (必须与主板匹配)
echo "2. CPU 信息"
echo "----------------------------"

if [[ $PRODUCT_CPU_VENDOR == "Intel" ]]; then
    case $PRODUCT_CPU_GEN in
        "12")
            CPU_MODELS=(
                "Intel(R) Core(TM) i5-12400F CPU @ 2.50GHz"
                "Intel(R) Core(TM) i5-12600K CPU @ 3.70GHz"
                "Intel(R) Core(TM) i7-12700K CPU @ 3.60GHz"
                "Intel(R) Core(TM) i9-12900K CPU @ 3.20GHz"
            )
            ;;
        "11")
            CPU_MODELS=(
                "Intel(R) Core(TM) i5-11400F CPU @ 2.60GHz"
                "Intel(R) Core(TM) i5-11600K CPU @ 3.90GHz"
                "Intel(R) Core(TM) i7-11700K CPU @ 3.60GHz"
                "Intel(R) Core(TM) i9-11900K CPU @ 3.50GHz"
            )
            ;;
        "10")
            CPU_MODELS=(
                "Intel(R) Core(TM) i5-10400F CPU @ 2.90GHz"
                "Intel(R) Core(TM) i5-10600K CPU @ 4.10GHz"
                "Intel(R) Core(TM) i7-10700K CPU @ 3.80GHz"
                "Intel(R) Core(TM) i9-10900K CPU @ 3.70GHz"
            )
            ;;
    esac
else
    case $PRODUCT_CPU_GEN in
        "5000")
            CPU_MODELS=(
                "AMD Ryzen 5 5600X 6-Core Processor"
                "AMD Ryzen 7 5800X 8-Core Processor"
                "AMD Ryzen 9 5900X 12-Core Processor"
                "AMD Ryzen 9 5950X 16-Core Processor"
            )
            ;;
        "3000")
            CPU_MODELS=(
                "AMD Ryzen 5 3600 6-Core Processor"
                "AMD Ryzen 7 3700X 8-Core Processor"
                "AMD Ryzen 9 3900X 12-Core Processor"
                "AMD Ryzen 9 3950X 16-Core Processor"
            )
            ;;
    esac
fi

CPU_MODEL=${CPU_MODELS[$RANDOM % ${#CPU_MODELS[@]}]}

# 生成 CPU 物理地址 (APIC ID)
CPU_APIC_ID=$(printf "0x%02x" $((RANDOM % 64)))

# 生成 CPU 微码版本 (根据代际)
if [[ $PRODUCT_CPU_VENDOR == "Intel" ]]; then
    case $PRODUCT_CPU_GEN in
        "12") CPU_MICROCODE=$(printf "0x%08x" $((0x00000420 + RANDOM % 16))) ;;
        "11") CPU_MICROCODE=$(printf "0x%08x" $((0x000000b4 + RANDOM % 16))) ;;
        "10") CPU_MICROCODE=$(printf "0x%08x" $((0x000000ea + RANDOM % 16))) ;;
    esac
else
    case $PRODUCT_CPU_GEN in
        "5000") CPU_MICROCODE=$(printf "0x%08x" $((0x0a50000c + RANDOM % 8))) ;;
        "3000") CPU_MICROCODE=$(printf "0x%08x" $((0x08701021 + RANDOM % 8))) ;;
    esac
fi

echo "CPU 厂商: $PRODUCT_CPU_VENDOR"
echo "CPU 型号: $CPU_MODEL"
echo "APIC ID: $CPU_APIC_ID"
echo "微码版本: $CPU_MICROCODE"
echo ""

# 3. BIOS 信息 (日期必须在硬件发布之后)
echo "3. BIOS 信息 (SMBIOS Type 0)"
echo "----------------------------"
BIOS_DATE=$(generate_date_range $PRODUCT_YEAR_START $PRODUCT_YEAR_END)

if [[ $SYSTEM_TYPE == "OEM" ]]; then
    BIOS_VENDOR=$MANUFACTURER
    # OEM 厂商的 BIOS 版本格式
    case $MANUFACTURER in
        "Dell Inc.") BIOS_VERSION="$(printf "%d.%d.%d" $((RANDOM % 3 + 1)) $((RANDOM % 20)) $((RANDOM % 10)))" ;;
        "HP") BIOS_VERSION="$(printf "S%02d Ver. %02d.%02d.%02d" $((RANDOM % 99 + 1)) $((RANDOM % 10)) $((RANDOM % 50)) $((RANDOM % 10)))" ;;
        "Lenovo") BIOS_VERSION="$(printf "M%02dKT%02dA" $((RANDOM % 99 + 1)) $((RANDOM % 99 + 1)))" ;;
    esac
else
    BIOS_VENDOR="American Megatrends Inc."
    # AMI BIOS 版本格式
    BIOS_VERSIONS=("F10" "F15" "F20" "F23" "F30" "F35")
    BIOS_VERSION=${BIOS_VERSIONS[$RANDOM % ${#BIOS_VERSIONS[@]}]}
fi

echo "BIOS 厂商: $BIOS_VENDOR"
echo "BIOS 版本: $BIOS_VERSION"
echo "BIOS 日期: $BIOS_DATE"
echo ""

# 4. 主板信息 (SMBIOS Type 2)
echo "4. 主板信息 (SMBIOS Type 2)"
echo "----------------------------"

if [[ $SYSTEM_TYPE == "OEM" ]]; then
    # OEM 主板使用数字编号
    case $MANUFACTURER in
        "Dell Inc.") BOARD_MODEL="0$(openssl rand -hex 3 | tr '[:lower:]' '[:upper:]')" ;;
        "HP") BOARD_MODEL="$(printf "%04d" $((RANDOM % 9999 + 1000)))" ;;
        "Lenovo") BOARD_MODEL="$(printf "%04X" $((RANDOM % 65535)))" ;;
    esac
else
    # DIY 主板型号与产品型号相同
    BOARD_MODEL=$PRODUCT
fi

BOARD_SERIAL=$(generate_serial "$(echo $MANUFACTURER | cut -c1-2)" 8)
BOARD_ASSET=$(generate_serial "AST-MB-" 3)
BOARD_VERSION="Rev $(printf "%d.%02d" $((RANDOM % 3 + 1)) $((RANDOM % 10)))"

echo "主板型号: $BOARD_MODEL"
echo "主板序列号: $BOARD_SERIAL"
echo "主板版本: $BOARD_VERSION"
echo "资产标签: $BOARD_ASSET"
echo ""

# 5. 机箱信息 (SMBIOS Type 3)
echo "5. 机箱信息 (SMBIOS Type 3)"
echo "----------------------------"
CHASSIS_SERIAL=$(generate_serial "$(echo $MANUFACTURER | cut -c1-2)" 8)
CHASSIS_ASSET=$(generate_serial "AST-CH-" 3)

echo "机箱序列号: $CHASSIS_SERIAL"
echo "资产标签: $CHASSIS_ASSET"
echo ""

# 6. 硬盘信息
echo "6. 硬盘信息"
echo "----------------------------"
HDD_BRANDS=("WDC" "Samsung" "Seagate" "Crucial" "Kingston" "Toshiba" "SanDisk")
HDD_BRAND=${HDD_BRANDS[$RANDOM % ${#HDD_BRANDS[@]}]}

case $HDD_BRAND in
    "WDC")
        HDD_MODELS=("WDC WD10EZEX-08WN4A0:80.00A80" "WDC WD20EZRZ-00Z5HB0:80.00A80" "WDC WD5000AAKX-60U6AA0:19.01H19" "WDC WD10EZEX-00BN5A0:01.01A01")
        HDD_INFO=${HDD_MODELS[$RANDOM % ${#HDD_MODELS[@]}]}
        HDD_MODEL=$(echo $HDD_INFO | cut -d: -f1)
        HDD_FIRMWARE=$(echo $HDD_INFO | cut -d: -f2)
        HDD_SERIAL=$(generate_serial "WD-WCAV" 4)
        HDD_WWN=$(printf "0x50014ee%09x" $((RANDOM * RANDOM % 1000000000)))
        ;;
    "Samsung")
        HDD_MODELS=("Samsung SSD 870 EVO 500GB:SVT02B6Q" "Samsung SSD 980 PRO 1TB:5B2QGXA7" "Samsung SSD 860 EVO 250GB:RVT04B6Q" "Samsung SSD 970 EVO Plus 500GB:4B2QEXM7")
        HDD_INFO=${HDD_MODELS[$RANDOM % ${#HDD_MODELS[@]}]}
        HDD_MODEL=$(echo $HDD_INFO | cut -d: -f1)
        HDD_FIRMWARE=$(echo $HDD_INFO | cut -d: -f2)
        HDD_SERIAL=$(generate_serial "S5H2N" 7)
        HDD_WWN=$(printf "0x5002538%09x" $((RANDOM * RANDOM % 1000000000)))
        ;;
    "Seagate")
        HDD_MODELS=("ST1000DM010-2EP102:CC43" "ST2000DM008-2FR102:0001" "ST500DM002-1BD142:KC45" "ST3000DM008-2DM166:CC26")
        HDD_INFO=${HDD_MODELS[$RANDOM % ${#HDD_MODELS[@]}]}
        HDD_MODEL=$(echo $HDD_INFO | cut -d: -f1)
        HDD_FIRMWARE=$(echo $HDD_INFO | cut -d: -f2)
        HDD_SERIAL=$(generate_serial "ZN1" 5)
        HDD_WWN=$(printf "0x5000c500%08x" $((RANDOM * RANDOM % 100000000)))
        ;;
    "Crucial")
        HDD_MODELS=("CT500MX500SSD1:M3CR033" "CT1000MX500SSD1:M3CR033" "CT250MX500SSD1:M3CR032" "CT2000MX500SSD1:M3CR033")
        HDD_INFO=${HDD_MODELS[$RANDOM % ${#HDD_MODELS[@]}]}
        HDD_MODEL=$(echo $HDD_INFO | cut -d: -f1)
        HDD_FIRMWARE=$(echo $HDD_INFO | cut -d: -f2)
        HDD_SERIAL=$(generate_serial "2038" 8)
        HDD_WWN=$(printf "0x500a0751%08x" $((RANDOM * RANDOM % 100000000)))
        ;;
    "Kingston")
        HDD_MODELS=("SA400S37480G:SBFK61D1" "SA400S37240G:SBFK61D1" "SA400S37960G:SBFK71E1" "SKC600512G:S4500107")
        HDD_INFO=${HDD_MODELS[$RANDOM % ${#HDD_MODELS[@]}]}
        HDD_MODEL=$(echo $HDD_INFO | cut -d: -f1)
        HDD_FIRMWARE=$(echo $HDD_INFO | cut -d: -f2)
        HDD_SERIAL=$(generate_serial "50026B" 6)
        HDD_WWN=$(printf "0x50026b76%08x" $((RANDOM * RANDOM % 100000000)))
        ;;
    "Toshiba")
        HDD_MODELS=("HDWD110:MS2OA8J0" "MQ01ABD100:AX0P2M" "DT01ACA100:MS2OA750" "HDWL120:MX6OACF0")
        HDD_INFO=${HDD_MODELS[$RANDOM % ${#HDD_MODELS[@]}]}
        HDD_MODEL=$(echo $HDD_INFO | cut -d: -f1)
        HDD_FIRMWARE=$(echo $HDD_INFO | cut -d: -f2)
        HDD_SERIAL=$(generate_serial "Y9GS" 4)
        HDD_WWN=$(printf "0x5000039%09x" $((RANDOM * RANDOM % 1000000000)))
        ;;
    "SanDisk")
        HDD_MODELS=("SDSSDA240G:Z33000RL" "SDSSDH3512G:X61170RL" "SDSSDA480G:Z33010RL" "SDSSDH31024G:X61180RL")
        HDD_INFO=${HDD_MODELS[$RANDOM % ${#HDD_MODELS[@]}]}
        HDD_MODEL=$(echo $HDD_INFO | cut -d: -f1)
        HDD_FIRMWARE=$(echo $HDD_INFO | cut -d: -f2)
        HDD_SERIAL=$(generate_serial "SD" 8)
        HDD_WWN=$(printf "0x5001b44%09x" $((RANDOM * RANDOM % 1000000000)))
        ;;
esac

echo "硬盘品牌: $HDD_BRAND"
echo "硬盘型号: $HDD_MODEL"
echo "硬盘序列号: $HDD_SERIAL"
echo "WWN: $HDD_WWN"
echo "固件版本: $HDD_FIRMWARE"
echo ""

# 7. 网卡信息
echo "7. 网卡信息"
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
-smbios type=2,manufacturer="$MANUFACTURER",product="$BOARD_MODEL",version="$BOARD_VERSION",serial="$BOARD_SERIAL",asset="$BOARD_ASSET",location="Base Board" \\
-smbios type=3,manufacturer="$MANUFACTURER",version="1.0",serial="$CHASSIS_SERIAL",asset="$CHASSIS_ASSET" \\

# CPU 配置
-cpu host,vendor=$PRODUCT_CPU_VENDOR \\

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

系统类型: $SYSTEM_TYPE
系统 UUID: $SYSTEM_UUID
系统序列号: $SYSTEM_SERIAL
制造商: $MANUFACTURER
产品型号: $PRODUCT

BIOS 厂商: $BIOS_VENDOR
BIOS 版本: $BIOS_VERSION
BIOS 日期: $BIOS_DATE

主板型号: $BOARD_MODEL
主板序列号: $BOARD_SERIAL
主板版本: $BOARD_VERSION

机箱序列号: $CHASSIS_SERIAL

CPU 厂商: $PRODUCT_CPU_VENDOR
CPU 型号: $CPU_MODEL
APIC ID: $CPU_APIC_ID
微码版本: $CPU_MICROCODE

硬盘品牌: $HDD_BRAND
硬盘型号: $HDD_MODEL
硬盘序列号: $HDD_SERIAL
WWN: $HDD_WWN
固件版本: $HDD_FIRMWARE

网卡厂商: $NIC_NAME
MAC 地址: $MAC_ADDRESS

---

QEMU 配置参数:

-smbios type=0,vendor="$BIOS_VENDOR",version="$BIOS_VERSION",date="$BIOS_DATE" \\
-smbios type=1,manufacturer="$MANUFACTURER",product="$PRODUCT",version="1.0",serial="$SYSTEM_SERIAL",uuid="$SYSTEM_UUID",sku="SKU-001",family="Desktop" \\
-smbios type=2,manufacturer="$MANUFACTURER",product="$BOARD_MODEL",version="$BOARD_VERSION",serial="$BOARD_SERIAL",asset="$BOARD_ASSET",location="Base Board" \\
-smbios type=3,manufacturer="$MANUFACTURER",version="1.0",serial="$CHASSIS_SERIAL",asset="$CHASSIS_ASSET" \\
-cpu host,vendor=$PRODUCT_CPU_VENDOR \\
-drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \\
-device ide-hd,drive=disk0,serial="$HDD_SERIAL",model="$HDD_MODEL",wwn=$HDD_WWN \\
-netdev user,id=net0 \\
-device e1000,netdev=net0,mac=$MAC_ADDRESS
EOF
    echo "配置已保存到: $OUTPUT_FILE"
fi
