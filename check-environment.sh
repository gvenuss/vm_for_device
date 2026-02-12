#!/bin/bash

################################################################################
# 环境检查脚本
# 用途: 检查系统环境是否满足运行 QEMU 虚拟机的要求
################################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo -e "  QEMU 环境检查工具"
echo -e "==========================================${NC}"
echo ""

PASSED=0
FAILED=0
WARNINGS=0

# 检查 QEMU 是否安装
echo -e "${BLUE}[1/6] 检查 QEMU 安装${NC}"
if command -v qemu-system-x86_64 &> /dev/null; then
    VERSION=$(qemu-system-x86_64 --version | head -1)
    echo -e "${GREEN}✓${NC} QEMU 已安装: $VERSION"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} QEMU 未安装"
    echo "  安装方法:"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "    sudo apt install qemu-system-x86 qemu-utils"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "    brew install qemu"
    fi
    FAILED=$((FAILED + 1))
fi
echo ""

# 检查 qemu-img 工具
echo -e "${BLUE}[2/6] 检查 qemu-img 工具${NC}"
if command -v qemu-img &> /dev/null; then
    echo -e "${GREEN}✓${NC} qemu-img 已安装"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} qemu-img 未安装"
    FAILED=$((FAILED + 1))
fi
echo ""

# 检查硬件加速支持
echo -e "${BLUE}[3/6] 检查硬件加速支持${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -e /dev/kvm ]; then
        echo -e "${GREEN}✓${NC} KVM 硬件加速可用"

        # 检查 KVM 权限
        if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
            echo -e "${GREEN}✓${NC} KVM 权限正常"
            PASSED=$((PASSED + 1))
        else
            echo -e "${YELLOW}!${NC} KVM 权限不足"
            echo "  解决方法: sudo usermod -aG kvm $USER"
            echo "  然后重新登录"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${YELLOW}!${NC} KVM 不可用，将使用软件模拟 (性能较差)"
        echo "  检查 BIOS 是否启用了虚拟化支持 (VT-x/AMD-V)"
        WARNINGS=$((WARNINGS + 1))
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}✓${NC} macOS Hypervisor Framework (HVF) 可用"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}!${NC} 未知操作系统，可能不支持硬件加速"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 检查必要的工具
echo -e "${BLUE}[4/6] 检查必要工具${NC}"

# openssl
if command -v openssl &> /dev/null; then
    echo -e "${GREEN}✓${NC} openssl 已安装"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}!${NC} openssl 未安装 (用于生成随机参数)"
    WARNINGS=$((WARNINGS + 1))
fi

# uuidgen
if command -v uuidgen &> /dev/null; then
    echo -e "${GREEN}✓${NC} uuidgen 已安装"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}!${NC} uuidgen 未安装 (用于生成 UUID)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 检查磁盘空间
echo -e "${BLUE}[5/6] 检查磁盘空间${NC}"
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')

echo "  可用空间: $AVAILABLE_SPACE"

if [ "$AVAILABLE_SPACE_GB" -ge 50 ]; then
    echo -e "${GREEN}✓${NC} 磁盘空间充足"
    PASSED=$((PASSED + 1))
elif [ "$AVAILABLE_SPACE_GB" -ge 20 ]; then
    echo -e "${YELLOW}!${NC} 磁盘空间较少，建议至少 50GB"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}✗${NC} 磁盘空间不足，建议至少 50GB"
    FAILED=$((FAILED + 1))
fi
echo ""

# 检查内存
echo -e "${BLUE}[6/6] 检查系统内存${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    TOTAL_MEM=$(free -g | awk 'NR==2 {print $2}')
    echo "  总内存: ${TOTAL_MEM}GB"

    if [ "$TOTAL_MEM" -ge 8 ]; then
        echo -e "${GREEN}✓${NC} 内存充足"
        PASSED=$((PASSED + 1))
    elif [ "$TOTAL_MEM" -ge 4 ]; then
        echo -e "${YELLOW}!${NC} 内存较少，建议至少 8GB"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${RED}✗${NC} 内存不足，建议至少 8GB"
        FAILED=$((FAILED + 1))
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    TOTAL_MEM=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    echo "  总内存: ${TOTAL_MEM}GB"

    if [ "$TOTAL_MEM" -ge 8 ]; then
        echo -e "${GREEN}✓${NC} 内存充足"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}!${NC} 内存较少，建议至少 8GB"
        WARNINGS=$((WARNINGS + 1))
    fi
fi
echo ""

# 检查脚本文件
echo -e "${BLUE}检查项目文件${NC}"
REQUIRED_FILES=(
    "create-windows-vm.sh"
    "create-linux-vm.sh"
    "generate-hardware-params.sh"
    "test-vm-detection-linux.sh"
    "vm-manager.sh"
    "README.md"
    "QEMU虚拟机配置指南.md"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (缺失)"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "${GREEN}✓${NC} 所有必需文件完整"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} 缺失 $MISSING_FILES 个文件"
    FAILED=$((FAILED + 1))
fi
echo ""

# 总结
echo -e "${BLUE}=========================================="
echo -e "  检查结果汇总"
echo -e "==========================================${NC}"
echo ""
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${YELLOW}警告: $WARNINGS${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查完美通过！可以开始使用了。${NC}"
    echo ""
    echo "下一步:"
    echo "  1. chmod +x *.sh"
    echo "  2. ./create-windows-vm.sh 或 ./create-linux-vm.sh"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠ 环境基本满足要求，但有一些警告项。${NC}"
    echo "建议解决警告项以获得最佳体验。"
    exit 0
else
    echo -e "${RED}✗ 环境检查未通过，请先解决失败项。${NC}"
    exit 1
fi
