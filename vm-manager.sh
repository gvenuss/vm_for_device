#!/bin/bash

################################################################################
# QEMU 虚拟机管理工具
# 用途: 简化虚拟机的日常管理操作
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_CONFIG_DIR="$SCRIPT_DIR/vm-configs"
VM_DISK_DIR="$SCRIPT_DIR/vm-disks"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 创建必要的目录
mkdir -p "$VM_CONFIG_DIR"
mkdir -p "$VM_DISK_DIR"

print_header() {
    echo -e "${BLUE}=========================================="
    echo -e "  QEMU 虚拟机管理工具"
    echo -e "==========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# 列出所有虚拟机
list_vms() {
    print_header
    echo "可用的虚拟机磁盘:"
    echo "----------------------------"

    if [ -z "$(ls -A $VM_DISK_DIR 2>/dev/null)" ]; then
        print_warning "未找到任何虚拟机磁盘"
        echo ""
        echo "使用 '$0 create' 创建新虚拟机"
        return
    fi

    local index=1
    for disk in "$VM_DISK_DIR"/*.qcow2; do
        if [ -f "$disk" ]; then
            local filename=$(basename "$disk")
            local size=$(qemu-img info "$disk" | grep "virtual size" | cut -d: -f2 | xargs)
            echo "$index. $filename ($size)"
            index=$((index + 1))
        fi
    done
    echo ""
}

# 创建新虚拟机
create_vm() {
    print_header
    echo "创建新虚拟机"
    echo "----------------------------"
    echo ""

    read -p "虚拟机名称: " vm_name
    if [ -z "$vm_name" ]; then
        print_error "虚拟机名称不能为空"
        return 1
    fi

    read -p "磁盘大小 (例如: 100G): " disk_size
    if [ -z "$disk_size" ]; then
        disk_size="100G"
        print_info "使用默认大小: $disk_size"
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 已存在"
        return 1
    fi

    echo ""
    print_info "正在创建虚拟磁盘..."
    qemu-img create -f qcow2 "$disk_path" "$disk_size"

    if [ $? -eq 0 ]; then
        print_success "虚拟机 '$vm_name' 创建成功"
        echo ""
        print_info "磁盘路径: $disk_path"
        print_info "使用 '$0 start $vm_name' 启动虚拟机"
    else
        print_error "创建失败"
        return 1
    fi
}

# 启动虚拟机
start_vm() {
    local vm_name=$1

    if [ -z "$vm_name" ]; then
        print_error "请指定虚拟机名称"
        echo "用法: $0 start <vm_name>"
        return 1
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ ! -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 不存在"
        return 1
    fi

    print_header
    echo "启动虚拟机: $vm_name"
    echo "----------------------------"
    echo ""

    # 检测加速器
    local accel="tcg"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -e /dev/kvm ]; then
            accel="kvm"
            print_info "使用 KVM 硬件加速"
        else
            print_warning "KVM 不可用，使用软件模拟"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        accel="hvf"
        print_info "使用 macOS Hypervisor Framework 加速"
    fi

    # 生成随机硬件参数
    local uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local serial="SYS$(date +%Y%m%d)$(shuf -i 100-999 -n 1 2>/dev/null || echo $RANDOM)"
    local mac="00:1B:21:$(openssl rand -hex 3 | sed 's/../&:/g;s/:$//')"

    echo ""
    print_info "UUID: $uuid"
    print_info "序列号: $serial"
    print_info "MAC: $mac"
    echo ""
    print_info "正在启动虚拟机..."
    echo ""

    # 启动 QEMU
    qemu-system-x86_64 \
      -name "$vm_name" \
      -machine type=q35,accel=$accel \
      -cpu host,kvm=off \
      -smp 4 \
      -m 4096 \
      -smbios type=1,manufacturer="ASUS",product="ROG STRIX B550-F",serial="$serial",uuid="$uuid" \
      -drive file="$disk_path",if=virtio,format=qcow2 \
      -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::3389-:3389 \
      -device e1000,netdev=net0,mac=$mac \
      -vga virtio \
      -display gtk \
      -device intel-hda -device hda-duplex \
      -boot order=c
}

# 查看虚拟机信息
info_vm() {
    local vm_name=$1

    if [ -z "$vm_name" ]; then
        print_error "请指定虚拟机名称"
        echo "用法: $0 info <vm_name>"
        return 1
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ ! -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 不存在"
        return 1
    fi

    print_header
    echo "虚拟机信息: $vm_name"
    echo "----------------------------"
    echo ""

    qemu-img info "$disk_path"
    echo ""

    # 显示快照信息
    local snapshots=$(qemu-img snapshot -l "$disk_path" 2>/dev/null | tail -n +3)
    if [ -n "$snapshots" ]; then
        echo "快照列表:"
        echo "$snapshots"
    else
        print_info "无快照"
    fi
}

# 创建快照
snapshot_create() {
    local vm_name=$1
    local snapshot_name=$2

    if [ -z "$vm_name" ] || [ -z "$snapshot_name" ]; then
        print_error "请指定虚拟机名称和快照名称"
        echo "用法: $0 snapshot-create <vm_name> <snapshot_name>"
        return 1
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ ! -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 不存在"
        return 1
    fi

    print_info "正在创建快照 '$snapshot_name'..."
    qemu-img snapshot -c "$snapshot_name" "$disk_path"

    if [ $? -eq 0 ]; then
        print_success "快照创建成功"
    else
        print_error "快照创建失败"
        return 1
    fi
}

# 恢复快照
snapshot_restore() {
    local vm_name=$1
    local snapshot_name=$2

    if [ -z "$vm_name" ] || [ -z "$snapshot_name" ]; then
        print_error "请指定虚拟机名称和快照名称"
        echo "用法: $0 snapshot-restore <vm_name> <snapshot_name>"
        return 1
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ ! -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 不存在"
        return 1
    fi

    print_warning "警告: 这将恢复到快照 '$snapshot_name' 的状态，当前数据将丢失"
    read -p "确认恢复? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "已取消"
        return 0
    fi

    print_info "正在恢复快照 '$snapshot_name'..."
    qemu-img snapshot -a "$snapshot_name" "$disk_path"

    if [ $? -eq 0 ]; then
        print_success "快照恢复成功"
    else
        print_error "快照恢复失败"
        return 1
    fi
}

# 删除快照
snapshot_delete() {
    local vm_name=$1
    local snapshot_name=$2

    if [ -z "$vm_name" ] || [ -z "$snapshot_name" ]; then
        print_error "请指定虚拟机名称和快照名称"
        echo "用法: $0 snapshot-delete <vm_name> <snapshot_name>"
        return 1
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ ! -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 不存在"
        return 1
    fi

    print_info "正在删除快照 '$snapshot_name'..."
    qemu-img snapshot -d "$snapshot_name" "$disk_path"

    if [ $? -eq 0 ]; then
        print_success "快照删除成功"
    else
        print_error "快照删除失败"
        return 1
    fi
}

# 删除虚拟机
delete_vm() {
    local vm_name=$1

    if [ -z "$vm_name" ]; then
        print_error "请指定虚拟机名称"
        echo "用法: $0 delete <vm_name>"
        return 1
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ ! -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 不存在"
        return 1
    fi

    print_warning "警告: 这将永久删除虚拟机 '$vm_name' 及其所有数据"
    read -p "确认删除? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "已取消"
        return 0
    fi

    rm -f "$disk_path"
    print_success "虚拟机 '$vm_name' 已删除"
}

# 调整磁盘大小
resize_vm() {
    local vm_name=$1
    local new_size=$2

    if [ -z "$vm_name" ] || [ -z "$new_size" ]; then
        print_error "请指定虚拟机名称和新大小"
        echo "用法: $0 resize <vm_name> <new_size>"
        echo "示例: $0 resize myvm +50G"
        return 1
    fi

    local disk_path="$VM_DISK_DIR/${vm_name}.qcow2"

    if [ ! -f "$disk_path" ]; then
        print_error "虚拟机 '$vm_name' 不存在"
        return 1
    fi

    print_info "正在调整磁盘大小..."
    qemu-img resize "$disk_path" "$new_size"

    if [ $? -eq 0 ]; then
        print_success "磁盘大小调整成功"
        echo ""
        qemu-img info "$disk_path" | grep "virtual size"
    else
        print_error "磁盘大小调整失败"
        return 1
    fi
}

# 显示帮助
show_help() {
    print_header
    echo "用法: $0 <command> [arguments]"
    echo ""
    echo "命令:"
    echo "  list                          列出所有虚拟机"
    echo "  create                        创建新虚拟机"
    echo "  start <vm_name>               启动虚拟机"
    echo "  info <vm_name>                查看虚拟机信息"
    echo "  delete <vm_name>              删除虚拟机"
    echo "  resize <vm_name> <size>       调整磁盘大小"
    echo ""
    echo "快照管理:"
    echo "  snapshot-create <vm> <name>   创建快照"
    echo "  snapshot-restore <vm> <name>  恢复快照"
    echo "  snapshot-delete <vm> <name>   删除快照"
    echo ""
    echo "示例:"
    echo "  $0 create"
    echo "  $0 start myvm"
    echo "  $0 snapshot-create myvm backup1"
    echo "  $0 resize myvm +50G"
    echo ""
}

# 主程序
main() {
    local command=$1
    shift

    case "$command" in
        list)
            list_vms
            ;;
        create)
            create_vm
            ;;
        start)
            start_vm "$@"
            ;;
        info)
            info_vm "$@"
            ;;
        delete)
            delete_vm "$@"
            ;;
        resize)
            resize_vm "$@"
            ;;
        snapshot-create)
            snapshot_create "$@"
            ;;
        snapshot-restore)
            snapshot_restore "$@"
            ;;
        snapshot-delete)
            snapshot_delete "$@"
            ;;
        help|--help|-h|"")
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
