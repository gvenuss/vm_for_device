#!/bin/bash

################################################################################
# al-khaser_x64 优化验证脚本
# 用途: 自动化验证所有优化是否正确应用到虚拟机配置中
# 提供详细的验证报告
# 作者: VM Anti-Detection Project
# 版本: 1.0
# 日期: $(date "+%Y-%m-%d")
################################################################################

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 报告文件
REPORT_FILE="al-khaser-optimization-report-$(date "+%Y%m%d-%H%M%S").txt"

# 验证结果数组
RESULTS=()
PASSED_TESTS=0
FAILED_TESTS=0

# 输出彩色消息
print_message() {
    local color=$1
    local message=$2
    printf "${color}${message}${NC}\n"
}

# 输出详细信息
print_detail() {
    local message=$1
    printf "  ${BLUE}•${NC} ${message}\n"
}

# 验证通过
test_passed() {
    local test_name=$1
    local details=$2
    RESULTS+=("✅ $test_name: 通过")
    PASSED_TESTS=$((PASSED_TESTS + 1))
    print_message $GREEN "✅ $test_name: 通过"
    if [ -n "$details" ]; then
        print_detail "$details"
    fi
    echo ""
}

# 验证失败
test_failed() {
    local test_name=$1
    local details=$2
    RESULTS+=("❌ $test_name: 失败")
    FAILED_TESTS=$((FAILED_TESTS + 1))
    print_message $RED "❌ $test_name: 失败"
    if [ -n "$details" ]; then
        print_detail "$details"
    fi
    echo ""
}

# 验证警告
test_warning() {
    local test_name=$1
    local details=$2
    RESULTS+=("⚠️ $test_name: 警告")
    print_message $YELLOW "⚠️ $test_name: 警告"
    if [ -n "$details" ]; then
        print_detail "$details"
    fi
    echo ""
}

# 验证文件是否存在
test_file_exists() {
    local file_path=$1
    local description=$2
    if [ -f "$file_path" ]; then
        test_passed "$description" "文件存在"
    else
        test_failed "$description" "文件不存在: $file_path"
    fi
}

# 验证脚本是否可执行
test_script_executable() {
    local file_path=$1
    local description=$2
    if [ -x "$file_path" ]; then
        test_passed "$description" "脚本可执行"
    elif [ -f "$file_path" ]; then
        test_warning "$description" "脚本需要执行权限"
    else
        test_failed "$description" "脚本不存在"
    fi
}

# 验证配置文件中的参数
test_config_parameter() {
    local config_file=$1
    local parameter=$2
    local description=$3
    local expected_value=$4
    if [ -f "$config_file" ]; then
        if grep -q "$parameter" "$config_file"; then
            if [ -z "$expected_value" ]; then
                test_passed "$description" "参数存在"
            else
                local actual_value=$(grep "$parameter" "$config_file" | grep -o "$expected_value" || true)
                if [ -n "$actual_value" ]; then
                    test_passed "$description" "参数值正确 ($expected_value)"
                else
                    test_failed "$description" "参数值不正确"
                fi
            fi
        else
            test_failed "$description" "参数不存在"
        fi
    else
        test_failed "$description" "配置文件不存在"
    fi
}

# 验证 SMBIOS 配置
test_smbios_config() {
    print_message $CYAN "验证 SMBIOS 配置..."
    echo "------------------------"

    test_config_parameter "create-windows-vm.sh" "BIOS_VENDOR" "BIOS 厂商配置"
    test_config_parameter "create-windows-vm.sh" "BIOS_VERSION" "BIOS 版本配置"
    test_config_parameter "create-windows-vm.sh" "SYSTEM_MANUFACTURER" "系统制造商配置"
    test_config_parameter "create-windows-vm.sh" "SYSTEM_PRODUCT" "系统产品配置"
    test_config_parameter "create-windows-vm.sh" "SYSTEM_SERIAL" "系统序列号配置"
}

# 验证输入设备优化
test_input_devices() {
    print_message $CYAN "验证输入设备优化..."
    echo "------------------------"

    if grep -q "usb-tablet" "create-windows-vm.sh"; then
        test_failed "USB 设备类型" "仍在使用 usb-tablet，应改为 usb-mouse + usb-kbd"
    elif grep -q "usb-mouse" "create-windows-vm.sh" && grep -q "usb-kbd" "create-windows-vm.sh"; then
        test_passed "USB 设备类型" "已使用 usb-mouse + usb-kbd 替代 usb-tablet"
    else
        test_warning "USB 设备类型" "未找到期望的输入设备配置"
    fi

    if grep -q "xhci" "create-windows-vm.sh"; then
        if grep -q "ehci" "create-windows-vm.sh"; then
            test_warning "USB 控制器类型" "同时检测到 ehci 和 xhci 控制器"
        else
            test_failed "USB 控制器类型" "仍在使用 xhci，应改为 ehci"
        fi
    elif grep -q "ehci" "create-windows-vm.sh"; then
        test_passed "USB 控制器类型" "已使用 ehci 控制器"
    else
        test_warning "USB 控制器类型" "未找到 USB 控制器配置"
    fi
}

# 验证存储设备优化
test_storage_devices() {
    print_message $CYAN "验证存储设备优化..."
    echo "------------------------"

    if grep -q "ich9-ahci" "create-windows-vm.sh"; then
        test_passed "存储控制器类型" "已使用 ich9-ahci 控制器"
    elif grep -q "ahci" "create-windows-vm.sh"; then
        test_warning "存储控制器类型" "使用标准 ahci，建议升级到 ich9-ahci"
    else
        test_failed "存储控制器类型" "未找到 AHCI 控制器配置"
    fi

    test_config_parameter "create-windows-vm.sh" "HDD_SERIAL" "硬盘序列号配置"
    test_config_parameter "create-windows-vm.sh" "HDD_MODEL" "硬盘型号配置"
    test_config_parameter "create-windows-vm.sh" "HDD_WWN" "硬盘 WWN 配置"
}

# 验证 PCI 设备优化
test_pci_devices() {
    print_message $CYAN "验证 PCI 设备优化..."
    echo "------------------------"

    if grep -q "virtio-vga-gl" "create-windows-vm.sh"; then
        test_passed "显卡类型" "已使用 virtio-vga-gl 替代 qxl-vga"
    elif grep -q "qxl-vga" "create-windows-vm.sh"; then
        test_failed "显卡类型" "仍在使用 qxl-vga，应改为 virtio-vga-gl"
    else
        test_warning "显卡类型" "未找到期望的显卡配置"
    fi

    if grep -q "e1000e" "create-windows-vm.sh"; then
        test_passed "网卡类型" "已使用 e1000e 替代 e1000"
    elif grep -q "e1000" "create-windows-vm.sh"; then
        test_warning "网卡类型" "使用 e1000，建议升级到 e1000e"
    else
        test_failed "网卡类型" "未找到期望的网卡配置"
    fi
}

# 验证 Hyper-V 检测防护优化
test_hyperv_detection() {
    print_message $CYAN "验证 Hyper-V 检测防护优化..."
    echo "------------------------"

    if grep -q "hv_msr_bitmap" "create-windows-vm.sh"; then
        test_passed "Hyper-V MSR 位图" "已配置 hv_msr_bitmap"
    else
        test_warning "Hyper-V MSR 位图" "未配置 hv_msr_bitmap"
    fi

    if grep -q "hv-vendor-id" "create-windows-vm.sh" || grep -q "hv_vendor_id" "create-windows-vm.sh"; then
        test_passed "Hyper-V 供应商 ID" "已配置 Hyper-V 供应商 ID"
    else
        test_failed "Hyper-V 供应商 ID" "未配置 Hyper-V 供应商 ID"
    fi

    if grep -q "hypervisor=off" "create-windows-vm.sh"; then
        test_passed "Hypervisor 标志" "已禁用 hypervisor 标志"
    else
        test_failed "Hypervisor 标志" "hypervisor 标志未禁用"
    fi
}

# 验证 WMI 传感器模拟
test_wmi_sensors() {
    print_message $CYAN "验证 WMI 传感器模拟..."
    echo "------------------------"

    if grep -q "ipmi" "create-windows-vm.sh"; then
        test_passed "IPMI 传感器模拟" "已配置 IPMI 传感器模拟"
    else
        test_warning "IPMI 传感器模拟" "未配置 IPMI 传感器模拟"
    fi
}

# 验证文件完整性
test_file_integrity() {
    print_message $CYAN "验证项目文件完整性..."
    echo "------------------------"

    test_file_exists "create-windows-vm.sh" "主配置脚本"
    test_file_exists "generate-hardware-params.sh" "硬件参数生成器"
    test_file_exists "test-al-khaser-detection.ps1" "PowerShell 检测脚本"
    test_file_exists "verify-al-khaser-optimization.sh" "验证脚本"
    test_file_exists "update-vm-config.sh" "配置更新脚本"
    test_file_exists "maintenance-plan.md" "维护计划"
}

# 验证脚本可执行权限
test_script_permissions() {
    print_message $CYAN "验证脚本执行权限..."
    echo "------------------------"

    test_script_executable "create-windows-vm.sh" "主配置脚本权限"
    test_script_executable "generate-hardware-params.sh" "硬件参数生成器权限"
    test_script_executable "verify-al-khaser-optimization.sh" "验证脚本权限"
    test_script_executable "update-vm-config.sh" "配置更新脚本权限"
}

# 验证硬件参数生成器功能
test_hardware_generator() {
    print_message $CYAN "验证硬件参数生成器..."
    echo "------------------------"

    if grep -q "SMBIOS Type 4" "generate-hardware-params.sh" && grep -q "SMBIOS Type 17" "generate-hardware-params.sh"; then
        test_passed "SMBIOS 类型支持" "已支持 Type 4 和 Type 17 表"
    else
        test_warning "SMBIOS 类型支持" "建议添加 Type 4 和 Type 17 表"
    fi
}

# 生成验证报告
generate_report() {
    print_message $BLUE "生成验证报告..."
    echo "------------------------"

    cat > $REPORT_FILE <<EOF
al-khaser_x64 优化验证报告
============================

报告生成时间: $(date "+%Y-%m-%d %H:%M:%S")

系统信息:
---------
主机名: $(hostname 2>/dev/null || echo "Unknown")
操作系统: $(uname -a)
架构: $(uname -m)

项目状态:
---------
目录: $(pwd)
Git 状态: $(git status | head -1)

验证结果:
---------
总测试数: $(($PASSED_TESTS + $FAILED_TESTS))
通过: $PASSED_TESTS
失败: $FAILED_TESTS

具体结果:
---------
EOF

    for result in "${RESULTS[@]}"; do
        echo "$result" >> $REPORT_FILE
    done

    cat >> $REPORT_FILE <<EOF

风险评估:
---------
EOF

    if [ $FAILED_TESTS -eq 0 ]; then
        cat >> $REPORT_FILE <<EOF
低风险 - 所有优化均正确应用
EOF
    elif [ $FAILED_TESTS -le 3 ]; then
        cat >> $REPORT_FILE <<EOF
中等风险 - 有 $FAILED_TESTS 个优化未完全正确应用
EOF
    else
        cat >> $REPORT_FILE <<EOF
高风险 - 有 $FAILED_TESTS 个优化未正确应用
EOF
    fi

    cat >> $REPORT_FILE <<EOF

建议:
-----
EOF

    if [ $FAILED_TESTS -gt 0 ]; then
        cat >> $REPORT_FILE <<EOF
1. 修复验证失败的项目
2. 重新生成硬件参数
3. 重启虚拟机测试
4. 重新运行检测脚本
EOF
    fi

    cat >> $REPORT_FILE <<EOF

---
本报告由 verify-al-khaser-optimization.sh 自动生成
EOF

    print_message $GREEN "报告已保存到: $REPORT_FILE"
}

# 主函数
main() {
    print_message $BLUE "al-khaser_x64 优化验证脚本"
    print_message $BLUE "虚拟机反检测项目 - 专业级验证工具"
    echo "=============================="
    echo ""

    # 执行所有验证
    test_smbios_config
    echo ""

    test_input_devices
    echo ""

    test_storage_devices
    echo ""

    test_pci_devices
    echo ""

    test_hyperv_detection
    echo ""

    test_wmi_sensors
    echo ""

    test_hardware_generator
    echo ""

    test_file_integrity
    echo ""

    test_script_permissions
    echo ""

    # 显示总结
    echo "=========================================="
    print_message $CYAN "验证总结"
    echo "------------------------------------------"
    print_message $GREEN "通过测试: $PASSED_TESTS"
    if [ $FAILED_TESTS -gt 0 ]; then
        print_message $RED "失败测试: $FAILED_TESTS"
    fi
    if [ $PASSED_TESTS -gt 0 ]; then
        local pass_rate=$(echo "scale=2; $PASSED_TESTS * 100 / ($PASSED_TESTS + $FAILED_TESTS)" | bc)
        print_message $YELLOW "成功率: $pass_rate%"
    fi
    echo "=========================================="
    echo ""

    # 风险评估
    if [ $FAILED_TESTS -eq 0 ]; then
        print_message $GREEN "✅ 低风险 - 所有优化均已正确应用"
    elif [ $FAILED_TESTS -le 3 ]; then
        print_message $YELLOW "⚠️  中等风险 - 有 $FAILED_TESTS 个优化需要修复"
    else
        print_message $RED "❌ 高风险 - 有 $FAILED_TESTS 个优化未正确应用"
    fi
    echo ""

    # 生成报告
    generate_report
}

# 执行脚本
if [ "$1" == "--generate-report" ]; then
    main > $REPORT_FILE
    echo "报告已生成到: $REPORT_FILE"
else
    main
fi