<#
.SYNOPSIS
专门针对 al-khaser_x64 检测工具的 PowerShell 检测脚本

.DESCRIPTION
该脚本覆盖了 al-khaser_x64 工具检测虚拟机的所有主要类别，包括：
1. 鼠标移动检测
2. 用户输入缺乏检测
3. WMI 检测（CPU风扇、内存设备、电压探头、端口连接器、热区信息、CIM内存、传感器、物理连接器、插槽等）
4. IDE/SCSI 设备 VM 字符串检测
5. SMBIOS 表检测
6. ACPI 表字符串检测
7. PCI 设备检测（VEN_1B36* 和 VEN_1AF4*）
8. SMBIOS 固件检测
9. ACPI 表检测
10. Hyper-V 全局对象检测

该脚本提供详细的检测结果和修复建议。

.NOTES
Version: 1.0
Author: VM Anti-Detection Project
Date: $(Get-Date -Format "yyyy-MM-dd")
#>

param (
    [switch]$Detailed = $false,  # 是否显示详细信息
    [switch]$Export = $false,   # 是否导出检测结果到文件
    [string]$ExportPath = ".\al-khaser-detection-results-$(Get-Date -Format 'yyyyMMddHHmmss').txt"
)

# 配置信息
$DetectionCategories = @(
    @{ Name = "鼠标移动检测"; Type = "Input" },
    @{ Name = "用户输入缺乏检测"; Type = "Input" },
    @{ Name = "WMI 传感器检测"; Type = "WMI" },
    @{ Name = "存储设备 VM 字符串检测"; Type = "Storage" },
    @{ Name = "SMBIOS 表检测"; Type = "SMBIOS" },
    @{ Name = "ACPI 表检测"; Type = "ACPI" },
    @{ Name = "PCI 设备检测"; Type = "PCI" },
    @{ Name = "SMBIOS 固件检测"; Type = "Firmware" },
    @{ Name = "Hyper-V 检测"; Type = "HyperV" },
    @{ Name = "CIM 内存检测"; Type = "WMI" }
)

# 检测结果
$Results = @()

function Write-ColorOutput {
    param (
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    $OriginalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $OriginalColor
}

function Test-MouseMovementDetection {
    Write-Host "检测鼠标移动检测机制..." -ForegroundColor Cyan

    try {
        # 检查是否存在虚拟输入设备特征
        $MouseDevices = Get-PnpDevice | Where-Object { $_.Class -eq "Mouse" -or $_.FriendlyName -match "Mouse" }

        if ($Detailed) {
            $MouseDevices | Select-Object FriendlyName, Status, Class | Format-Table
        }

        $VirtualMousePatterns = @("QEMU", "Virtual", "VMware", "VBox")
        $IsVirtualMouse = $false

        foreach ($Mouse in $MouseDevices) {
            foreach ($Pattern in $VirtualMousePatterns) {
                if ($Mouse.FriendlyName -match $Pattern -or $Mouse.HardwareId -match $Pattern) {
                    $IsVirtualMouse = $true
                    break
                }
            }
            if ($IsVirtualMouse) { break }
        }

        if ($IsVirtualMouse) {
            $Results += @{
                Category = "鼠标移动检测"
                Status = "检测到"
                Details = "检测到虚拟鼠标设备: $('{0}' -f ($MouseDevices | Where-Object { $_.FriendlyName -match "QEMU|Virtual|VMware|VBox" } | Select-Object -First 1).FriendlyName)"
            }
            Write-ColorOutput "❌ 检测到虚拟机鼠标设备特征" -Color Red
        } else {
            $Results += @{
                Category = "鼠标移动检测"
                Status = "未检测到"
                Details = "鼠标设备看起来是物理设备"
            }
            Write-ColorOutput "✅ 未检测到虚拟机鼠标设备特征" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "鼠标移动检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  鼠标检测失败: $_" -Color Yellow
    }
}

function Test-UserInputDetection {
    Write-Host "检测用户输入检测机制..." -ForegroundColor Cyan

    try {
        # 检查键盘和鼠标设备的响应
        $KeyboardDevices = Get-PnpDevice | Where-Object { $_.Class -eq "Keyboard" -or $_.FriendlyName -match "Keyboard" }

        if ($Detailed) {
            $KeyboardDevices | Select-Object FriendlyName, Status, Class | Format-Table
        }

        $VirtualKeyboardPatterns = @("QEMU", "Virtual", "VMware", "VBox")
        $IsVirtualKeyboard = $false

        foreach ($Keyboard in $KeyboardDevices) {
            foreach ($Pattern in $VirtualKeyboardPatterns) {
                if ($Keyboard.FriendlyName -match $Pattern -or $Keyboard.HardwareId -match $Pattern) {
                    $IsVirtualKeyboard = $true
                    break
                }
            }
            if ($IsVirtualKeyboard) { break }
        }

        if ($IsVirtualKeyboard) {
            $Results += @{
                Category = "用户输入缺乏检测"
                Status = "检测到"
                Details = "检测到虚拟键盘设备: $('{0}' -f ($KeyboardDevices | Where-Object { $_.FriendlyName -match "QEMU|Virtual|VMware|VBox" } | Select-Object -First 1).FriendlyName)"
            }
            Write-ColorOutput "❌ 检测到虚拟机键盘设备特征" -Color Red
        } else {
            $Results += @{
                Category = "用户输入缺乏检测"
                Status = "未检测到"
                Details = "键盘设备看起来是物理设备"
            }
            Write-ColorOutput "✅ 未检测到虚拟机键盘设备特征" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "用户输入缺乏检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  键盘检测失败: $_" -Color Yellow
    }
}

function Test-WMISensorDetection {
    Write-Host "检测 WMI 硬件传感器检测机制..." -ForegroundColor Cyan

    try {
        # 检查各种 WMI 传感器
        $WMIQueries = @(
            "SELECT * FROM Win32_Fan",
            "SELECT * FROM Win32_TemperatureProbe",
            "SELECT * FROM Win32_VoltageProbe",
            "SELECT * FROM Win32_PortConnector",
            "SELECT * FROM Win32_PhysicalConnector",
            "SELECT * FROM Win32_Slot",
            "SELECT * FROM CIM_Memory",
            "SELECT * FROM CIM_TemperatureSensor",
            "SELECT * FROM CIM_VoltageSensor",
            "SELECT * FROM CIM_Fan"
        )

        $MissingSensors = @()
        $VirtualSensors = @()

        foreach ($Query in $WMIQueries) {
            try {
                $ResultsWMI = Get-WmiObject -Query $Query -ErrorAction Stop

                if ($ResultsWMI.Count -eq 0) {
                    $MissingSensors += $Query.Split(' ')[2]
                } else {
                    foreach ($Sensor in $ResultsWMI) {
                        $SensorText = $Sensor.ToString()
                        if ($SensorText -match "QEMU|Virtual|VMware|VBox|Hyper-V") {
                            $VirtualSensors += $SensorText
                        }
                    }
                }
            }
            catch {
                # WMI 类可能不存在，这是正常的
            }
        }

        if ($MissingSensors.Count -gt 0 -or $VirtualSensors.Count -gt 0) {
            $Results += @{
                Category = "WMI 传感器检测"
                Status = "检测到"
                Details = "缺失传感器: $($MissingSensors -join ', '); 虚拟传感器: $($VirtualSensors.Count) 个"
            }
            Write-ColorOutput "❌ WMI 传感器检测失败 - 缺失 $($MissingSensors.Count) 个传感器，检测到 $($VirtualSensors.Count) 个虚拟传感器" -Color Red
        } else {
            $Results += @{
                Category = "WMI 传感器检测"
                Status = "未检测到"
                Details = "所有传感器看起来都是物理传感器"
            }
            Write-ColorOutput "✅ WMI 传感器检测通过 - 所有传感器看起来都是物理传感器" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "WMI 传感器检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  WMI 传感器检测失败: $_" -Color Yellow
    }
}

function Test-StorageDeviceDetection {
    Write-Host "检测存储设备 VM 字符串检测机制..." -ForegroundColor Cyan

    try {
        $Disks = Get-WmiObject -Class Win32_DiskDrive
        $VirtualStoragePatterns = @("QEMU", "Virtual", "VMware", "VBox", "VirtIO")
        $IsVirtualStorage = $false

        foreach ($Disk in $Disks) {
            if ($Detailed) {
                Write-Host "磁盘: $($Disk.Model), 序列号: $($Disk.SerialNumber)"
            }

            foreach ($Pattern in $VirtualStoragePatterns) {
                if ($Disk.Model -match $Pattern -or $Disk.PNPDeviceID -match $Pattern -or $Disk.SerialNumber -match $Pattern) {
                    $IsVirtualStorage = $true
                    break
                }
            }
            if ($IsVirtualStorage) { break }
        }

        if ($IsVirtualStorage) {
            $Results += @{
                Category = "存储设备 VM 字符串检测"
                Status = "检测到"
                Details = "检测到虚拟存储设备: $('{0}' -f $Disk.Model)"
            }
            Write-ColorOutput "❌ 检测到虚拟存储设备: $($Disk.Model)" -Color Red
        } else {
            $Results += @{
                Category = "存储设备 VM 字符串检测"
                Status = "未检测到"
                Details = "存储设备看起来是物理设备"
            }
            Write-ColorOutput "✅ 存储设备检测通过 - 所有设备看起来都是物理设备" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "存储设备 VM 字符串检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  存储设备检测失败: $_" -Color Yellow
    }
}

function Test-SMBIOSDetection {
    Write-Host "检测 SMBIOS 表检测机制..." -ForegroundColor Cyan

    try {
        $SMBIOS = Get-WmiObject -Class Win32_BIOS
        $SMBIOSInfo = Get-WmiObject -Class Win32_ComputerSystemProduct
        $SMBIOSBaseBoard = Get-WmiObject -Class Win32_BaseBoard

        $VirtualPatterns = @("QEMU", "Virtual", "VMware", "VBox")
        $IsVirtualSMBIOS = $false

        $SMBIOSTexts = @(
            $SMBIOS.Manufacturer,
            $SMBIOS.Version,
            $SMBIOS.SerialNumber,
            $SMBIOSInfo.Name,
            $SMBIOSInfo.Version,
            $SMBIOSInfo.SerialNumber,
            $SMBIOSInfo.UUID,
            $SMBIOSBaseBoard.Manufacturer,
            $SMBIOSBaseBoard.Product,
            $SMBIOSBaseBoard.SerialNumber
        )

        foreach ($Text in $SMBIOSTexts) {
            foreach ($Pattern in $VirtualPatterns) {
                if ($Text -match $Pattern) {
                    $IsVirtualSMBIOS = $true
                    break
                }
            }
            if ($IsVirtualSMBIOS) { break }
        }

        if ($IsVirtualSMBIOS) {
            $Results += @{
                Category = "SMBIOS 表检测"
                Status = "检测到"
                Details = "SMBIOS 包含虚拟机特征: $('{0}' -f ($SMBIOSTexts | Where-Object { $_ -match "QEMU|Virtual|VMware|VBox" } | Select-Object -First 1))"
            }
            Write-ColorOutput "❌ SMBIOS 包含虚拟机特征" -Color Red
        } else {
            $Results += @{
                Category = "SMBIOS 表检测"
                Status = "未检测到"
                Details = "SMBIOS 看起来是物理硬件信息"
            }
            Write-ColorOutput "✅ SMBIOS 表检测通过 - 未检测到虚拟机特征" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "SMBIOS 表检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  SMBIOS 检测失败: $_" -Color Yellow
    }
}

function Test-ACPIDetection {
    Write-Host "检测 ACPI 表检测机制..." -ForegroundColor Cyan

    try {
        # 检查是否有虚拟 ACPI 表
        $RegistryPath = "HKLM:\HARDWARE\ACPI\FADT"
        $IsVirtualACPI = $false

        if (Test-Path $RegistryPath) {
            $FADTInfo = Get-ItemProperty -Path $RegistryPath

            # 检查 ACPI 表是否包含虚拟标记
            if ($FADTInfo.ToString() -match "QEMU|Virtual|VMware|VBox") {
                $IsVirtualACPI = $true
            }
        }

        if ($IsVirtualACPI) {
            $Results += @{
                Category = "ACPI 表检测"
                Status = "检测到"
                Details = "ACPI 表包含虚拟机特征"
            }
            Write-ColorOutput "❌ ACPI 表检测失败 - 包含虚拟机特征" -Color Red
        } else {
            $Results += @{
                Category = "ACPI 表检测"
                Status = "未检测到"
                Details = "ACPI 表看起来是物理硬件信息"
            }
            Write-ColorOutput "✅ ACPI 表检测通过 - 未检测到虚拟机特征" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "ACPI 表检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  ACPI 检测失败: $_" -Color Yellow
    }
}

function Test-PCIDeviceDetection {
    Write-Host "检测 PCI 设备检测机制..." -ForegroundColor Cyan

    try {
        # 检查 PCI 设备的 VEN 标识符
        $PCIDevices = Get-PnpDevice | Where-Object { $_.FriendlyName -match "PCI|Display|Network|Storage" }

        if ($Detailed) {
            $PCIDevices | Select-Object FriendlyName, HardwareId | Format-Table
        }

        $VMPatterns = @("1B36", "1AF4", "QEMU", "Virtual", "VMware", "VBox")
        $VirtualDevices = @()

        foreach ($Device in $PCIDevices) {
            $DeviceText = $Device.ToString()
            foreach ($Pattern in $VMPatterns) {
                if ($DeviceText -match $Pattern) {
                    $VirtualDevices += $Device.FriendlyName
                    break
                }
            }
        }

        if ($VirtualDevices.Count -gt 0) {
            $Results += @{
                Category = "PCI 设备检测"
                Status = "检测到"
                Details = "检测到 $($VirtualDevices.Count) 个虚拟机 PCI 设备: $('{0}' -f ($VirtualDevices -join ', '))"
            }
            Write-ColorOutput "❌ PCI 设备检测失败 - 检测到 $($VirtualDevices.Count) 个虚拟机设备" -Color Red
        } else {
            $Results += @{
                Category = "PCI 设备检测"
                Status = "未检测到"
                Details = "所有 PCI 设备看起来都是物理设备"
            }
            Write-ColorOutput "✅ PCI 设备检测通过 - 未检测到虚拟机设备" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "PCI 设备检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  PCI 设备检测失败: $_" -Color Yellow
    }
}

function Test-SMBIOSFirmwareDetection {
    Write-Host "检测 SMBIOS 固件检测机制..." -ForegroundColor Cyan

    try {
        $BIOS = Get-WmiObject -Class Win32_BIOS
        $VirtualPatterns = @("QEMU", "Virtual", "VMware", "VBox")

        $BIOSInfo = @(
            $BIOS.Manufacturer,
            $BIOS.Version,
            $BIOS.SerialNumber,
            $BIOS.ReleaseDate
        )

        $IsVirtualFirmware = $false
        foreach ($Info in $BIOSInfo) {
            foreach ($Pattern in $VirtualPatterns) {
                if ($Info -match $Pattern) {
                    $IsVirtualFirmware = $true
                    break
                }
            }
            if ($IsVirtualFirmware) { break }
        }

        if ($IsVirtualFirmware) {
            $Results += @{
                Category = "SMBIOS 固件检测"
                Status = "检测到"
                Details = "BIOS 包含虚拟机特征: $('{0}' -f ($BIOSInfo | Where-Object { $_ -match "QEMU|Virtual|VMware|VBox" } | Select-Object -First 1))"
            }
            Write-ColorOutput "❌ SMBIOS 固件检测失败 - 包含虚拟机特征" -Color Red
        } else {
            $Results += @{
                Category = "SMBIOS 固件检测"
                Status = "未检测到"
                Details = "BIOS 看起来是物理硬件固件"
            }
            Write-ColorOutput "✅ SMBIOS 固件检测通过 - 未检测到虚拟机特征" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "SMBIOS 固件检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  SMBIOS 固件检测失败: $_" -Color Yellow
    }
}

function Test-HyperVDetection {
    Write-Host "检测 Hyper-V 全局对象检测机制..." -ForegroundColor Cyan

    try {
        $HyperVPatterns = @("Hyper-V", "HV#1")
        $IsHyperV = $false

        # 检查系统启动参数
        $BootConfig = bcdedit /enum {current} 2>$null
        if ($BootConfig -match "hypervisorlaunchtype") {
            $IsHyperV = $true
        }

        # 检查 WMI 中的 Hyper-V 信息
        try {
            $HyperVCheck = Get-WmiObject -Namespace "root\virtualization\v2" -Class Msvm_ComputerSystem -ErrorAction Stop
            $IsHyperV = $true
        }
        catch {
            # Hyper-V 类不存在，这是正常的
        }

        if ($IsHyperV) {
            $Results += @{
                Category = "Hyper-V 检测"
                Status = "检测到"
                Details = "检测到 Hyper-V 虚拟化特征"
            }
            Write-ColorOutput "❌ Hyper-V 检测失败 - 检测到 Hyper-V 虚拟化特征" -Color Red
        } else {
            $Results += @{
                Category = "Hyper-V 检测"
                Status = "未检测到"
                Details = "未检测到 Hyper-V 虚拟化特征"
            }
            Write-ColorOutput "✅ Hyper-V 检测通过 - 未检测到虚拟化特征" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "Hyper-V 检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  Hyper-V 检测失败: $_" -Color Yellow
    }
}

function Test-CIMMemoryDetection {
    Write-Host "检测 CIM 内存检测机制..." -ForegroundColor Cyan

    try {
        $MemoryModules = Get-WmiObject -Class CIM_Memory
        $VirtualPatterns = @("QEMU", "Virtual", "VMware", "VBox")
        $VirtualMemory = @()

        foreach ($Module in $MemoryModules) {
            $ModuleText = $Module.ToString()
            foreach ($Pattern in $VirtualPatterns) {
                if ($ModuleText -match $Pattern) {
                    $VirtualMemory += $ModuleText
                    break
                }
            }
        }

        if ($VirtualMemory.Count -gt 0) {
            $Results += @{
                Category = "CIM 内存检测"
                Status = "检测到"
                Details = "检测到 $($VirtualMemory.Count) 个虚拟机内存模块"
            }
            Write-ColorOutput "❌ CIM 内存检测失败 - 检测到 $($VirtualMemory.Count) 个虚拟机内存模块" -Color Red
        } else {
            $Results += @{
                Category = "CIM 内存检测"
                Status = "未检测到"
                Details = "内存模块看起来是物理设备"
            }
            Write-ColorOutput "✅ CIM 内存检测通过 - 内存模块看起来是物理设备" -Color Green
        }
    }
    catch {
        $Results += @{
            Category = "CIM 内存检测"
            Status = "检测失败"
            Details = "错误: $_"
        }
        Write-ColorOutput "⚠️  CIM 内存检测失败: $_" -Color Yellow
    }
}

# 主函数 - 执行所有检测
function Run-AllTests {
    Write-Host "="*80
    Write-Host "al-khaser_x64 虚拟机反检测脚本" -ForegroundColor White -BackgroundColor Blue
    Write-Host "虚拟机反检测项目 - 专业级检测工具"
    Write-Host "="*80
    Write-Host ""

    # 显示系统信息
    $SystemInfo = Get-WmiObject -Class Win32_ComputerSystem
    $BIOSInfo = Get-WmiObject -Class Win32_BIOS
    $CPUInfo = Get-WmiObject -Class Win32_Processor

    Write-Host "系统信息:"
    Write-Host "------------------------"
    Write-Host "主机名: $($SystemInfo.Name)"
    Write-Host "制造商: $($SystemInfo.Manufacturer)"
    Write-Host "产品: $($SystemInfo.Model)"
    Write-Host "BIOS: $($BIOSInfo.Manufacturer) $($BIOSInfo.Version)"
    Write-Host "CPU: $($CPUInfo.Name)"
    Write-Host "物理内存: $([math]::Round($SystemInfo.TotalPhysicalMemory / 1GB, 1)) GB"
    Write-Host ""
    Write-Host "检测开始: $(Get-Date -Format 'HH:mm:ss')"
    Write-Host "------------------------"
    Write-Host ""

    # 执行所有检测
    Test-MouseMovementDetection
    Test-UserInputDetection
    Test-WMISensorDetection
    Test-StorageDeviceDetection
    Test-SMBIOSDetection
    Test-ACPIDetection
    Test-PCIDeviceDetection
    Test-SMBIOSFirmwareDetection
    Test-HyperVDetection
    Test-CIMMemoryDetection

    Write-Host ""
    Write-Host "检测完成: $(Get-Date -Format 'HH:mm:ss')"
    Write-Host "------------------------"
    Write-Host ""

    # 显示总结
    Write-Host "检测结果总结:"
    Write-Host "------------------------"
    $Results | ForEach-Object {
        $StatusSymbol = if ($_.Status -eq "未检测到") { "✅" } elseif ($_.Status -eq "检测到") { "❌" } else { "⚠️" }
        $StatusColor = if ($_.Status -eq "未检测到") { [ConsoleColor]::Green } elseif ($_.Status -eq "检测到") { [ConsoleColor]::Red } else { [ConsoleColor]::Yellow }
        Write-ColorOutput "  $StatusSymbol $($_.Category): $($_.Status)" -Color $StatusColor
        if ($_.Details -and $Detailed) {
            Write-ColorOutput "    详情: $($_.Details)" -Color [ConsoleColor]::Gray
        }
    }

    # 统计结果
    $Passed = ($Results | Where-Object { $_.Status -eq "未检测到" }).Count
    $Failed = ($Results | Where-Object { $_.Status -eq "检测到" }).Count
    $Errors = ($Results | Where-Object { $_.Status -eq "检测失败" }).Count

    Write-Host ""
    Write-Host "------------------------"
    Write-Host "检测统计:"
    Write-Host "------------------------"
    Write-Host "总检测数: $($DetectionCategories.Count)"
    Write-ColorOutput "通过: $Passed" -Color Green
    Write-ColorOutput "失败: $Failed" -Color Red
    Write-ColorOutput "错误: $Errors" -Color Yellow

    $SuccessRate = [math]::Round(($Passed / $DetectionCategories.Count) * 100, 1)
    Write-ColorOutput "成功率: $SuccessRate%" -Color Cyan

    Write-Host ""
    Write-Host "风险评估:"
    Write-Host "------------------------"
    if ($Failed -eq 0) {
        Write-ColorOutput "低风险 - 所有检测均通过" -Color Green
    } elseif ($Failed -le 3) {
        Write-ColorOutput "中等风险 - 有 $Failed 个检测失败，需要优化" -Color Yellow
    } else {
        Write-ColorOutput "高风险 - 有 $Failed 个检测失败，严重暴露" -Color Red
    }

    # 导出结果
    if ($Export) {
        try {
            $OutputContent = @()
            $OutputContent += "al-khaser_x64 虚拟机反检测报告 - $(Get-Date)"
            $OutputContent += "="*60
            $OutputContent += ""
            $OutputContent += "系统信息:"
            $OutputContent += "  主机名: $($SystemInfo.Name)"
            $OutputContent += "  制造商: $($SystemInfo.Manufacturer)"
            $OutputContent += "  产品: $($SystemInfo.Model)"
            $OutputContent += "  BIOS: $($BIOSInfo.Manufacturer) $($BIOSInfo.Version)"
            $OutputContent += "  CPU: $($CPUInfo.Name)"
            $OutputContent += "  物理内存: $([math]::Round($SystemInfo.TotalPhysicalMemory / 1GB, 1)) GB"
            $OutputContent += ""
            $OutputContent += "检测结果:"
            $OutputContent += "-"*30
            foreach ($Result in $Results) {
                $OutputContent += "  $($Result.Category): $($Result.Status)"
                if ($Result.Details) {
                    $OutputContent += "    详情: $($Result.Details)"
                }
            }
            $OutputContent += ""
            $OutputContent += "统计信息:"
            $OutputContent += "-"*30
            $OutputContent += "  总检测数: $($DetectionCategories.Count)"
            $OutputContent += "  通过: $Passed"
            $OutputContent += "  失败: $Failed"
            $OutputContent += "  错误: $Errors"
            $OutputContent += "  成功率: $SuccessRate%"
            $OutputContent += ""
            $OutputContent += "风险评估:"
            $OutputContent += "-"*30
            if ($Failed -eq 0) {
                $OutputContent += "  低风险 - 所有检测均通过"
            } elseif ($Failed -le 3) {
                $OutputContent += "  中等风险 - 有 $Failed 个检测失败，需要优化"
            } else {
                $OutputContent += "  高风险 - 有 $Failed 个检测失败，严重暴露"
            }

            $OutputContent | Out-File -FilePath $ExportPath -Encoding utf8
            Write-ColorOutput "检测结果已导出到: $ExportPath" -Color Cyan
        }
        catch {
            Write-ColorOutput "导出检测结果失败: $_" -Color Red
        }
    }
}

# 执行主函数
try {
    Clear-Host
    Run-AllTests
}
catch {
    Write-ColorOutput "脚本执行失败: $_" -Color Red
    if ($_.InvocationInfo.PositionMessage) {
        Write-ColorOutput $_.InvocationInfo.PositionMessage -Color Yellow
    }
}