#!/bin/bash

# 测试 generate-hardware-params.sh 和 create-windows-vm.sh 之间的变量匹配

echo "=========================================="
echo "  测试变量匹配"
echo "=========================================="
echo ""

# 临时文件
TEMP_CONFIG=$(mktemp /tmp/vm-config.XXXXXX)

# 运行 generate-hardware-params.sh 并捕获生成的变量定义
if [ -f "./generate-hardware-params.sh" ]; then
    echo "1. 运行 generate-hardware-params.sh 生成配置..."
    ./generate-hardware-params.sh > $TEMP_CONFIG 2>&1
    # 提取变量定义部分
    grep -A 40 "# 硬件信息自定义" $TEMP_CONFIG > /tmp/gen-vars.txt
    echo "   ✓ 完成"
else
    echo "错误: 找不到 generate-hardware-params.sh"
    exit 1
fi

# 检查 create-windows-vm.sh 中的变量定义
if [ -f "./create-windows-vm.sh" ]; then
    echo "2. 分析 create-windows-vm.sh 中的变量..."
    grep -A 40 "# 硬件信息自定义" ./create-windows-vm.sh > /tmp/cwv-vars.txt
    echo "   ✓ 完成"
else
    echo "错误: 找不到 create-windows-vm.sh"
    exit 1
fi

# 提取变量名
cut -d'=' -f1 /tmp/gen-vars.txt | grep -E '^[A-Z_]+' | sed 's/^[[:space:]]*//' | sort > /tmp/gen-var-names.txt
cut -d'=' -f1 /tmp/cwv-vars.txt | grep -E '^[A-Z_]+' | sed 's/^[[:space:]]*//' | sort > /tmp/cwv-var-names.txt

# 检查匹配情况
echo ""
echo "3. 变量匹配情况:"
echo "--------------------------"

MATCHED=()
UNMATCHED_GEN=()
UNMATCHED_CWV=()

while read -r var; do
    if grep -q "^${var}" /tmp/cwv-var-names.txt; then
        MATCHED+=("$var")
    else
        UNMATCHED_GEN+=("$var")
    fi
done < /tmp/gen-var-names.txt

while read -r var; do
    if ! grep -q "^${var}" /tmp/gen-var-names.txt; then
        UNMATCHED_CWV+=("$var")
    fi
done < /tmp/cwv-var-names.txt

echo "匹配的变量:"
for var in "${MATCHED[@]}"; do
    echo "  ✓ $var"
done

echo ""
if [ ${#UNMATCHED_GEN[@]} -gt 0 ]; then
    echo "generate-hardware-params.sh 中未匹配的变量:"
    for var in "${UNMATCHED_GEN[@]}"; do
        echo "  ✗ $var"
    done
else
    echo "✓ generate-hardware-params.sh 所有变量均已匹配"
fi

echo ""
if [ ${#UNMATCHED_CWV[@]} -gt 0 ]; then
    echo "create-windows-vm.sh 中额外的变量:"
    for var in "${UNMATCHED_CWV[@]}"; do
        echo "  ! $var"
    done
fi

# 检查是否存在不匹配的变量
if [ ${#UNMATCHED_GEN[@]} -gt 0 ]; then
    echo ""
    echo "=========================================="
    echo "  发现不匹配的变量"
    echo "=========================================="
    echo "需要在 create-windows-vm.sh 中添加以下变量:"
    echo ""

    # 从 generate-hardware-params.sh 中获取未匹配变量的默认值
    while read -r line; do
        var=$(echo "$line" | cut -d'=' -f1 | sed 's/^[[:space:]]*//')
        if grep -q "^${var}" /tmp/gen-var-names.txt && ! grep -q "^${var}" /tmp/cwv-var-names.txt; then
            echo "$line"
        fi
    done < /tmp/gen-vars.txt
else
    echo ""
    echo "=========================================="
    echo "  所有变量匹配成功"
    echo "=========================================="
fi

# 清理临时文件
rm -f $TEMP_CONFIG /tmp/gen-vars.txt /tmp/cwv-vars.txt /tmp/gen-var-names.txt /tmp/cwv-var-names.txt

echo ""
echo "测试完成!"
