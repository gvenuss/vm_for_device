#!/bin/bash

################################################################################
# 虚拟机优化验证脚本
# 用途: 验证脚本优化是否成功
################################################################################

echo "=========================================="
echo "  虚拟机优化验证"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

# 检查 1: Windows 脚本是否包含 VNC
echo "[1/5] 检查 Windows 脚本 VNC 配置..."
if grep -q "vnc :0" create-windows-vm.sh; then
    echo "✓ VNC 配置已添加"
    PASSED=$((PASSED + 1))
else
    echo "✗ VNC 配置缺失"
    FAILED=$((FAILED + 1))
fi

# 检查 2: Windows 脚本是否删除音频
echo "[2/5] 检查 Windows 脚本音频设备..."
if ! grep -q "intel-hda" create-windows-vm.sh; then
    echo "✓ 音频设备已删除"
    PASSED=$((PASSED + 1))
else
    echo "✗ 音频设备仍存在"
    FAILED=$((FAILED + 1))
fi

# 检查 3: Linux 脚本是否包含 VNC
echo "[3/5] 检查 Linux 脚本 VNC 配置..."
if grep -q "vnc :0" create-linux-vm.sh; then
    echo "✓ VNC 配置已添加"
    PASSED=$((PASSED + 1))
else
    echo "✗ VNC 配置缺失"
    FAILED=$((FAILED + 1))
fi

# 检查 4: Linux 脚本是否删除音频
echo "[4/5] 检查 Linux 脚本音频设备..."
if ! grep -q "intel-hda" create-linux-vm.sh; then
    echo "✓ 音频设备已删除"
    PASSED=$((PASSED + 1))
else
    echo "✗ 音频设备仍存在"
    FAILED=$((FAILED + 1))
fi

# 检查 5: 脚本是否可执行
echo "[5/5] 检查脚本执行权限..."
if [ -x create-windows-vm.sh ] && [ -x create-linux-vm.sh ]; then
    echo "✓ 脚本有执行权限"
    PASSED=$((PASSED + 1))
else
    echo "! 脚本缺少执行权限，正在添加..."
    chmod +x create-windows-vm.sh create-linux-vm.sh
    echo "✓ 执行权限已添加"
    PASSED=$((PASSED + 1))
fi

echo ""
echo "=========================================="
echo "  验证结果"
echo "=========================================="
echo "通过: $PASSED/5"
echo "失败: $FAILED/5"
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
