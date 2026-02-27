```
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
```

## 项目概述

这是一个专业的 QEMU 虚拟机反检测配置工具，专注于 Windows 10/11 系统的虚拟化特征隐藏。项目提供完整的虚拟机配置、硬件参数生成、检测验证和维护管理功能。

## 核心架构

### 项目结构
```
vm_for_device/
├── create-windows-vm.sh          # Windows 虚拟机启动脚本（核心配置）
├── generate-hardware-params.sh   # 硬件参数随机生成器（SMBIOS/ACPI 表优化）
├── check-environment.sh          # 环境检查工具
├── vm-manager.sh                 # 虚拟机管理工具
├── test-al-khaser-detection.ps1  # 专门针对 al-khaser 的检测脚本
├── verify-al-khaser-optimization.sh  # 优化验证脚本
├── update-vm-config.sh           # 配置更新管理脚本
├── maintenance-plan.md           # 长期维护计划
├── al-khaser-optimization-report.md  # 详细优化报告
├── test-vm-detection-windows.bat # 基础检测工具
├── test-vm-detection-windows.ps1 # PowerShell 检测脚本
├── verify-optimization.sh        # 旧版验证脚本
└── .gitignore                    # 忽略规则
```

### 关键配置文件

1. **`create-windows-vm.sh`** - 主启动脚本
   - 包含完整的 QEMU 命令行参数
   - 硬件配置（CPU、内存、存储、网卡、显卡等）
   - 虚拟化特征隐藏参数
   - 支持 --config 和 --generate 参数

2. **`generate-hardware-params.sh`** - 硬件参数生成器
   - 生成真实的硬件配置信息（SMBIOS Type 0-4, 17）
   - 支持 OEM 和 DIY 系统类型
   - 包含详细的硬件厂商和产品库

3. **`test-al-khaser-detection.ps1`** - PowerShell 检测脚本
   - 专门针对 al-khaser_x64 的 10 种检测类别
   - 提供详细的检测结果和风险评估
   - 支持 -Detailed 和 -Export 参数

## 常用命令

### 开发环境准备
```bash
# 检查环境
./check-environment.sh

# 确保所有脚本具有执行权限
chmod +x *.sh
```

### 虚拟机管理
```bash
# 启动虚拟机（使用默认配置）
./create-windows-vm.sh

# 生成新配置并启动
./create-windows-vm.sh --generate

# 使用指定配置文件启动
./create-windows-vm.sh --config vm-config-20260225-174505.txt

# 查看虚拟机进程
ps aux | grep qemu

# 停止虚拟机
pkill qemu-system-x86_64
```

### 硬件参数管理
```bash
# 生成新的硬件参数
./generate-hardware-params.sh

# 验证硬件参数匹配
./test_variable_match.sh

# 查看配置历史
cat history_records.txt
```

### 优化验证
```bash
# 验证当前配置
./verify-al-khaser-optimization.sh

# 检查项目文件完整性
./update-vm-config.sh --check

# 备份当前配置
./update-vm-config.sh --backup
```

### 检测和维护
```bash
# 在虚拟机中运行检测（PowerShell）
.\test-al-khaser-detection.ps1

# 运行详细检测并导出报告
.\test-al-khaser-detection.ps1 -Detailed -Export

# 查看维护计划
cat maintenance-plan.md
```

## 开发和维护流程

### 优化流程
1. 修改 `create-windows-vm.sh` 中的配置参数
2. 更新 `generate-hardware-params.sh` 中的硬件库
3. 运行 `verify-al-khaser-optimization.sh` 验证
4. 使用 `update-vm-config.sh` 备份和更新
5. 测试虚拟机启动和检测

### 硬件参数优化
- **SMBIOS 表**：在 `create-windows-vm.sh` 中通过 -smbios 参数配置
- **ACPI 表**：通过 QEMU 机器类型和芯片组配置
- **PCI 设备**：修改设备类型和属性（如 virtio-vga-gl 替代 qxl-vga）
- **CPU 配置**：在 -cpu 参数中添加或修改虚拟化特征隐藏参数

### 验证标准
- 所有 `verify-al-khaser-optimization.sh` 测试通过（28 项）
- `test-al-khaser-detection.ps1` 所有 10 个检测类别均显示"未检测到"
- 虚拟机性能保持在可接受水平

## 常用任务

### 添加新硬件设备
1. 在 `generate-hardware-params.sh` 中添加设备信息到对应的数组
2. 确保设备参数符合真实硬件规范
3. 测试设备配置的兼容性

### 更新检测脚本
1. 修改 `test-al-khaser-detection.ps1` 中的检测类别
2. 添加新的检测模式或特征
3. 在虚拟机中测试脚本功能

### 性能优化
1. 调整 `create-windows-vm.sh` 中的资源分配
2. 优化 QEMU 加速配置
3. 测试不同的硬件设备组合

## 风险评估和应对

### 常见风险
- **检测失败**：通过 `verify-al-khaser-optimization.sh` 定位问题
- **性能下降**：调整资源分配或硬件配置
- **兼容性问题**：测试不同的 QEMU 版本和 Windows 系统

### 回滚策略
1. 使用 `update-vm-config.sh --restore <timestamp>` 恢复配置
2. 检查 `config-backups/` 目录中的备份
3. 重新启动虚拟机并验证

## 参考资源

- 项目文档：`README.md`、`USAGE_GUIDE.md`、`使用指南.md`
- QEMU 官方文档：https://www.qemu.org/documentation/
- SMBIOS 规范：https://www.dmtf.org/standards/smbios
- al-khaser_x64 工具：https://github.com/LordNoteworthy/al-khaser
