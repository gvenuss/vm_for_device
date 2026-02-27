#!/bin/bash

################################################################################
# 虚拟机配置更新管理脚本
# 用途: 自动化管理虚拟机配置的备份、恢复、验证和更新
# 提供安全的配置变更和一致性检查
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

# 配置常量
BACKUP_DIR="./config-backups"
CONFIG_FILES=("create-windows-vm.sh" "generate-hardware-params.sh" "test-al-khaser-detection.ps1")
VERSION_FILE="vm-config-version.txt"

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

# 执行命令并检查结果
execute_command() {
    local command=$1
    local description=$2
    local quiet=${3:-false}

    if [ "$quiet" = false ]; then
        print_message $CYAN "正在 $description..."
    fi

    local output=$(eval "$command" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        if [ "$quiet" = false ]; then
            print_message $GREEN "✅ $description"
        fi
        return 0
    else
        if [ "$quiet" = false ]; then
            print_message $RED "❌ $description 失败"
            print_detail "错误信息: $output"
        fi
        return 1
    fi
}

# 创建备份目录
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_message $GREEN "✅ 备份目录已创建"
    fi
}

# 检查配置是否有变化
check_for_changes() {
    print_message $CYAN "检查配置文件是否有变化..."

    local has_changes=false

    for config_file in "${CONFIG_FILES[@]}"; do
        if [ -f "$config_file" ]; then
            if git status | grep -q "$config_file"; then
                has_changes=true
                print_message $YELLOW "⚠️ $config_file 有未提交的变更"
            fi
        fi
    done

    if ! $has_changes; then
        print_message $GREEN "✅ 所有配置文件均已提交到 git"
    fi

    echo ""
    return $([ "$has_changes" = true ] && echo 1 || echo 0)
}

# 备份当前配置
backup_current_config() {
    print_message $CYAN "备份当前配置..."
    create_backup_dir

    local timestamp=$(date "+%Y%m%d-%H%M%S")
    local backup_dir="$BACKUP_DIR/config-$timestamp"

    mkdir -p "$backup_dir"

    local backup_count=0
    for config_file in "${CONFIG_FILES[@]}"; do
        if [ -f "$config_file" ]; then
            cp "$config_file" "$backup_dir/"
            backup_count=$((backup_count + 1))
        fi
    done

    echo "$timestamp" > "$backup_dir/backup-info.txt"

    # 保存 git 信息
    git rev-parse HEAD > "$backup_dir/git-commit.txt" 2>/dev/null

    print_message $GREEN "✅ 配置已备份到: $backup_dir"
    echo ""

    return 0
}

# 列出可用备份
list_available_backups() {
    print_message $CYAN "列出可用备份..."
    create_backup_dir

    if [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        print_message $YELLOW "⚠️ 未找到备份"
        return 1
    fi

    print_message $GREEN "可用备份:"
    echo "------------------------"

    local backups=($(find $BACKUP_DIR -name "config-*" -type d | sort))
    for backup in "${backups[@]}"; do
        local timestamp=$(basename "$backup" | cut -d '-' -f2)
        local date=$(echo "$timestamp" | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3 \4:\5:\6/')
        local backup_size=$(du -sh "$backup" | cut -f1)

        print_detail "$date ($backup_size) - $backup"
    done

    echo ""
    return 0
}

# 恢复配置
restore_config() {
    local backup_name=$1
    if [ -z "$backup_name" ]; then
        print_message $RED "❌ 请提供备份名称"
        return 1
    fi

    print_message $CYAN "恢复配置: $backup_name..."
    create_backup_dir

    local backup_dir="$BACKUP_DIR/config-$backup_name"
    if [ ! -d "$backup_dir" ]; then
        print_message $RED "❌ 备份不存在: $backup_dir"
        return 1
    fi

    # 先备份当前配置
    backup_current_config

    # 恢复配置文件
    local restore_count=0
    for config_file in "${CONFIG_FILES[@]}"; do
        if [ -f "$backup_dir/$config_file" ]; then
            cp "$backup_dir/$config_file" "./"
            restore_count=$((restore_count + 1))
        fi
    done

    # 恢复执行权限
    for config_file in "${CONFIG_FILES[@]}"; do
        if [ "$(echo $config_file | grep -E '\.sh$')" ]; then
            chmod +x "$config_file"
        fi
    done

    print_message $GREEN "✅ 配置已从 $backup_dir 恢复"
    echo ""

    # 更新版本信息
    echo "$backup_name" > "$VERSION_FILE"

    return 0
}

# 验证配置的一致性
verify_config_consistency() {
    print_message $CYAN "验证配置一致性..."

    local has_issues=false

    # 检查所有配置文件是否存在
    for config_file in "${CONFIG_FILES[@]}"; do
        if [ ! -f "$config_file" ]; then
            print_message $RED "❌ 缺少配置文件: $config_file"
            has_issues=true
        fi
    done

    # 检查脚本执行权限
    for config_file in "${CONFIG_FILES[@]}"; do
        if [ "$(echo $config_file | grep -E '\.sh$')" ]; then
            if [ ! -x "$config_file" ]; then
                print_message $YELLOW "⚠️ 脚本需要执行权限: $config_file"
                has_issues=true
            fi
        fi
    done

    if ! $has_issues; then
        print_message $GREEN "✅ 配置一致性验证通过"
    fi

    echo ""
    return $([ "$has_issues" = true ] && echo 1 || echo 0)
}

# 生成新的硬件参数
generate_new_hardware_params() {
    print_message $CYAN "生成新的硬件参数..."

    if [ -x "generate-hardware-params.sh" ]; then
        local temp_file=$(mktemp)
        local params=$(./generate-hardware-params.sh 2>&1 | grep -A 30 "# 硬件信息自定义" | head -30)

        if [ -n "$params" ]; then
            echo "$params" > "$temp_file"
            print_message $GREEN "✅ 硬件参数已生成"
            print_message $CYAN "新参数已保存到: $temp_file"
            print_message $CYAN "请检查并手动更新到 create-windows-vm.sh"
        else
            print_message $RED "❌ 硬件参数生成失败"
        fi
    else
        print_message $RED "❌ 硬件参数生成器不可执行"
    fi

    echo ""
}

# 更新配置到 git
update_config_to_git() {
    print_message $CYAN "更新配置到 git..."

    local commit_msg=${1:-"更新虚拟机配置 - $(date "+%Y-%m-%d %H:%M:%S")"}

    if [ -n "$(git status | grep -E 'Untracked|Changes not staged')" ]; then
        # 检查是否有新文件
        local new_files=$(git status | grep -E 'Untracked' | awk '{print $2}')
        if [ -n "$new_files" ]; then
            git add $new_files
        fi

        # 提交更改
        git add "${CONFIG_FILES[@]}"
        git commit -m "$commit_msg"
    else
        print_message $GREEN "✅ 没有需要提交的更改"
    fi

    echo ""
}

# 检查 git 连接
check_git_connection() {
    print_message $CYAN "检查 git 连接..."

    if git remote -v > /dev/null 2>&1; then
        print_message $GREEN "✅ Git 远程仓库配置正常"
        return 0
    else
        print_message $RED "❌ Git 远程仓库配置失败"
        return 1
    fi
}

# 显示当前状态
show_current_status() {
    print_message $CYAN "显示当前配置状态..."
    create_backup_dir

    echo "--- 项目信息 ---"
    echo "Git 分支: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unknown")"
    echo "最后提交: $(git log --oneline | head -1 2>/dev/null || echo "Unknown")"
    echo ""

    echo "--- 备份信息 ---"
    if [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo "无备份"
    else
        local latest_backup=$(ls -td $BACKUP_DIR/config-* | head -1 2>/dev/null)
        if [ -n "$latest_backup" ]; then
            local backup_size=$(du -sh $latest_backup | cut -f1)
            echo "最后备份: $latest_backup ($backup_size)"
            echo "备份总数: $(find $BACKUP_DIR -name "config-*" -type d | wc -l)"
        fi
    fi
    echo ""

    echo "--- 当前版本 ---"
    if [ -f "$VERSION_FILE" ]; then
        local current_version=$(cat $VERSION_FILE)
        echo "配置版本: $current_version"
    fi

    echo ""
}

# 主菜单
show_main_menu() {
    clear
    print_message $BLUE "al-khaser_x64 配置管理脚本"
    print_message $BLUE "虚拟机反检测项目 - 专业级配置管理"
    echo "=========================================="
    echo ""

    show_current_status

    echo "选择操作:"
    echo "------------------------"
    echo "1. 检查配置变更"
    echo "2. 备份当前配置"
    echo "3. 恢复配置"
    echo "4. 列出备份"
    echo "5. 验证配置一致性"
    echo "6. 生成新的硬件参数"
    echo "7. 更新到 git"
    echo "8. 显示 git 状态"
    echo "0. 退出"
    echo ""
}

# 菜单导航
navigate_menu() {
    local choice

    show_main_menu

    while :; do
        read -p "请输入您的选择: " choice
        echo ""

        case $choice in
            1)
                check_for_changes
                ;;
            2)
                backup_current_config
                ;;
            3)
                if [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
                    print_message $YELLOW "⚠️ 未找到备份"
                    backup_current_config
                fi
                local available_backups=$(ls -1 $BACKUP_DIR | grep -oP 'config-\K[^/]*' | sort | tail -5)
                print_message $CYAN "最近的可用备份:"
                for backup in $available_backups; do
                    echo "  - $backup"
                done
                read -p "请输入要恢复的备份时间戳: " timestamp
                if [ -n "$timestamp" ]; then
                    restore_config "$timestamp"
                fi
                ;;
            4)
                list_available_backups
                ;;
            5)
                verify_config_consistency
                ;;
            6)
                generate_new_hardware_params
                ;;
            7)
                read -p "请输入提交信息 (可选): " commit_msg
                update_config_to_git "$commit_msg"
                ;;
            8)
                git status
                echo ""
                ;;
            0)
                print_message $BLUE "脚本执行完毕"
                exit 0
                ;;
            *)
                print_message $YELLOW "⚠️ 无效选择，请重试"
                ;;
        esac

        read -p "按回车键继续..."
        show_main_menu
    done
}

# 主函数
main() {
    # 检查是否在项目根目录
    if [ ! -f "create-windows-vm.sh" ]; then
        print_message $RED "❌ 请在项目根目录运行此脚本"
        return 1
    fi

    # 显示主菜单
    navigate_menu
}

# 处理参数
if [ $# -eq 0 ]; then
    main
else
    case $1 in
        "--check")
            check_for_changes
            ;;
        "--backup")
            backup_current_config
            ;;
        "--restore")
            if [ $# -eq 2 ]; then
                restore_config "$2"
            else
                print_message $RED "❌ 请提供备份时间戳"
                exit 1
            fi
            ;;
        "--list")
            list_available_backups
            ;;
        "--verify")
            verify_config_consistency
            ;;
        "--generate")
            generate_new_hardware_params
            ;;
        "--update")
            update_config_to_git
            ;;
        "--status")
            show_current_status
            ;;
        "--help"|"-h")
            cat <<EOF
使用说明:
  $0                        - 显示主菜单
  $0 --check              - 检查配置变更
  $0 --backup             - 备份当前配置
  $0 --restore <timestamp> - 恢复配置
  $0 --list               - 列出可用备份
  $0 --verify             - 验证配置一致性
  $0 --generate           - 生成新的硬件参数
  $0 --update             - 更新到 git
  $0 --status             - 显示当前状态
  $0 --help               - 显示此帮助

示例:
  $0 --check
  $0 --backup
  $0 --restore 20230101-103045
  $0 --list
EOF
            ;;
        *)
            print_message $RED "❌ 未知参数: $1"
            print_message $YELLOW "请使用 --help 查看帮助"
            exit 1
            ;;
    esac
fi