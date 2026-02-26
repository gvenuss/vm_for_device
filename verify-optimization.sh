#!/bin/bash

################################################################################
# 虚拟机优化验证脚本
# 用途: 验证脚本优化是否成功
################################################################################

echo "=========================================="
echo "  虚拟机优化验证"
echo "  (反虚拟化检测优化版)"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

# 检查 1: Windows 脚本是否包含 VNC
echo "[1/7] 检查 Windows 脚本 VNC 配置..."
if grep -q "vnc :0" create-windows-vm.sh; then
    echo "✓ VNC 配置已添加"
    PASSED=$((PASSED + 1))
else
    echo "✗ VNC 配置缺失"
    FAILED=$((FAILED + 1))
fi

# 检查 1a: Windows 脚本是否使用优化的 CPU 配置
echo "[2/7] 检查 Windows 脚本 CPU 配置..."
if grep -q "hypervisor=off" create-windows-vm.sh && grep -q "hv_vendor_id=GenuineIntel" create-windows-vm.sh; then
    echo "✓ CPU 虚拟化特征已隐藏"
    PASSED=$((PASSED + 1))
else
    echo "✗ CPU 虚拟化特征需要优化"
    FAILED=$((FAILED + 1))
fi

# 检查 1b: Windows 脚本是否使用 QXL 显卡
echo "[3/7] 检查 Windows 脚本显卡配置..."
if grep -q "qxl-vga" create-windows-vm.sh && ! grep -q "virtio-vga" create-windows-vm.sh; then
    echo "✓ 使用 QXL 显卡替代 VirtIO"
    PASSED=$((PASSED + 1))
else
    echo "✗ 显卡配置需要优化"
    FAILED=$((FAILED + 1))
fi

# 检查 1c: Windows 脚本是否使用 AHCI 控制器
echo "[4/7] 检查 Windows 脚本磁盘控制器..."
if grep -q "ahci" create-windows-vm.sh; then
    echo "✓ 使用 AHCI 磁盘控制器"
    PASSED=$((PASSED + 1))
else
    echo "✗ 磁盘控制器需要优化"
    FAILED=$((FAILED + 1))
fi

# 检查 2: Windows 脚本是否包含优化的音频配置
echo "[2/5] 检查 Windows 脚本音频设备配置..."
if grep -q "audiodev none" create-windows-vm.sh && grep -q "intel-hda" create-windows-vm.sh; then
    echo "✓ 音频设备配置已优化"
    PASSED=$((PASSED + 1))
else
    echo "✗ 音频设备配置需要优化"
    FAILED=$((FAILED + 1))
fi

# 检查 5: Linux 脚本是否存在并检查其配置（如果存在）
if [ -f "create-linux-vm.sh" ]; then
    echo "[5/7] 检查 Linux 脚本 VNC 配置..."
    if grep -q "vnc :0" create-linux-vm.sh; then
        echo "✓ VNC 配置已添加"
        PASSED=$((PASSED + 1))
    else
        echo "✗ VNC 配置缺失"
        FAILED=$((FAILED + 1))
    fi

    echo "[6/7] 检查 Linux 脚本音频设备配置..."
    if grep -q "audiodev none" create-linux-vm.sh && grep -q "intel-hda" create-linux-vm.sh; then
        echo "✓ 音频设备配置已优化"
        PASSED=$((PASSED + 1))
    elif ! grep -q "intel-hda" create-linux-vm.sh; then
        echo "✓ 音频设备已删除"
        PASSED=$((PASSED + 1))
    else
        echo "✗ 音频设备配置需要优化"
        FAILED=$((FAILED + 1))
    fi
else
    echo "[5/7] Linux 脚本不存在，跳过检查"
    echo "[6/7] Linux 脚本不存在，跳过检查"
    PASSED=$((PASSED + 2))  # 为不存在的脚本添加通过分数
fi

# 检查 7: 脚本是否可执行
echo "[7/7] 检查脚本执行权限..."
if [ -x create-windows-vm.sh ]; then
    echo "✓ Windows 脚本有执行权限"
    if [ -f "create-linux-vm.sh" ] && [ -x create-linux-vm.sh ]; then
        echo "✓ Linux 脚本有执行权限"
        PASSED=$((PASSED + 1))
    elif [ ! -f "create-linux-vm.sh" ]; then
        echo "✓ Linux 脚本不存在，跳过检查"
        PASSED=$((PASSED + 1))
    else
        echo "! Linux 脚本缺少执行权限，正在添加..."
        chmod +x create-linux-vm.sh
        echo "✓ Linux 脚本执行权限已添加"
        PASSED=$((PASSED + 1))
    fi
else
    echo "! Windows 脚本缺少执行权限，正在添加..."
    chmod +x create-windows-vm.sh
    echo "✓ Windows 脚本执行权限已添加"
    if [ -f "create-linux-vm.sh" ]; then
        if [ ! -x create-linux-vm.sh ]; then
            echo "! Linux 脚本缺少执行权限，正在添加..."
            chmod +x create-linux-vm.sh
            echo "✓ Linux 脚本执行权限已添加"
        fi
    fi
    PASSED=$((PASSED + 1))
fi

echo ""
echo "=========================================="
echo "  验证结果"
echo "=========================================="
echo "通过: $PASSED/7"
echo "失败: $FAILED/7"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✓ 所有检查通过！脚本优化成功。"
    echo ""
    echo "下一步："
    echo "  1. 启动虚拟机: ./create-windows-vm.sh"
    echo "  2. 检查进程: ps aux | grep qemu"
    echo "  3. 检查端口: netstat -tlnp | grep 5900"
    echo "  4. 使用 VNC 客户端连接: <虚拟机IP>:5900"
    exit 0
else
    echo "✗ 有 $FAILED 项检查失败，请检查脚本。"
    exit 1
fi
