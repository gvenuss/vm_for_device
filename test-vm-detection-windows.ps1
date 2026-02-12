################################################################################
# 虚拟化检测测试脚本 (Windows PowerShell)
# 用途: 在虚拟机内运行，检测是否能被识别为虚拟机
# 使用: 以管理员身份运行 PowerShell，执行 .\test-vm-detection-windows.ps1
################################################################################

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  虚拟化检测测试工具 (PowerShell)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Detected = 0
$TotalTests = 0

function Test-VirtualizationFeature {
    param(
        [string]$TestName,
        [string]$Value,
        [string[]]$Keywords,
        [string]$Details = ""
    )

    $script:TotalTests++
    $isVirtual = $false

    foreach ($keyword in $Keywords) {
        if ($Value -match $keyword) {
            $isVirtual = $true
            break
        }
    }

    if ($isVirtual) {
        Write-Host "[X] $TestName" -ForegroundColor Red
        if ($Details) { Write-Host "    $Details" -ForegroundColor Gray }
        Write-Host "    值: $Value" -ForegroundColor Gray
        $script:Detected++
    } else {
        Write-Host "[√] $TestName" -ForegroundColor Green
        if ($Details) { Write-Host "    $Details" -ForegroundColor Gray }
    }
}

# 虚拟化关键字列表
$VirtKeywords = @("qemu", "bochs", "virtual", "vmware", "virtualbox", "xen", "kvm", "vbox", "seabios")

Write-Host "1. 系统信息检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# 系统制造商
$SysInfo = Get-WmiObject Win32_ComputerSystem
Test-VirtualizationFeature -TestName "系统制造商" -Value $SysInfo.Manufacturer -Keywords $VirtKeywords -Details $SysInfo.Manufacturer

# 系统型号
Test-VirtualizationFeature -TestName "系统型号" -Value $SysInfo.Model -Keywords $VirtKeywords -Details $SysInfo.Model

Write-Host ""
Write-Host "2. BIOS 信息检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# BIOS 信息
$BiosInfo = Get-WmiObject Win32_BIOS
Test-VirtualizationFeature -TestName "BIOS 制造商" -Value $BiosInfo.Manufacturer -Keywords $VirtKeywords -Details $BiosInfo.Manufacturer
Test-VirtualizationFeature -TestName "BIOS 版本" -Value $BiosInfo.Version -Keywords $VirtKeywords -Details $BiosInfo.Version

# BIOS 序列号检查
$TotalTests++
if ([string]::IsNullOrWhiteSpace($BiosInfo.SerialNumber) -or $BiosInfo.SerialNumber -eq "0" -or $BiosInfo.SerialNumber -eq "None") {
    Write-Host "[X] BIOS 序列号" -ForegroundColor Red
    Write-Host "    序列号无效或为空: $($BiosInfo.SerialNumber)" -ForegroundColor Gray
    $Detected++
} else {
    Write-Host "[√] BIOS 序列号" -ForegroundColor Green
    Write-Host "    $($BiosInfo.SerialNumber)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "3. 主板信息检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# 主板信息
$BoardInfo = Get-WmiObject Win32_BaseBoard
Test-VirtualizationFeature -TestName "主板制造商" -Value $BoardInfo.Manufacturer -Keywords $VirtKeywords -Details $BoardInfo.Manufacturer
Test-VirtualizationFeature -TestName "主板产品" -Value $BoardInfo.Product -Keywords $VirtKeywords -Details $BoardInfo.Product

# 主板序列号
$TotalTests++
if ([string]::IsNullOrWhiteSpace($BoardInfo.SerialNumber) -or $BoardInfo.SerialNumber -eq "None") {
    Write-Host "[X] 主板序列号" -ForegroundColor Red
    Write-Host "    序列号无效或为空" -ForegroundColor Gray
    $Detected++
} else {
    Write-Host "[√] 主板序列号" -ForegroundColor Green
    Write-Host "    $($BoardInfo.SerialNumber)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "4. CPU 信息检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# CPU 信息
$CpuInfo = Get-WmiObject Win32_Processor | Select-Object -First 1
Test-VirtualizationFeature -TestName "CPU 名称" -Value $CpuInfo.Name -Keywords @("qemu", "virtual") -Details $CpuInfo.Name

# 检查 Hypervisor 标志
$TotalTests++
try {
    $HypervisorPresent = (Get-WmiObject Win32_ComputerSystem).HypervisorPresent
    if ($HypervisorPresent) {
        Write-Host "[X] Hypervisor 检测" -ForegroundColor Red
        Write-Host "    检测到 Hypervisor 存在" -ForegroundColor Gray
        $Detected++
    } else {
        Write-Host "[√] Hypervisor 检测" -ForegroundColor Green
        Write-Host "    未检测到 Hypervisor" -ForegroundColor Gray
    }
} catch {
    Write-Host "[?] Hypervisor 检测" -ForegroundColor Yellow
    Write-Host "    无法检测 (可能是旧版 Windows)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "5. 硬盘信息检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# 硬盘信息
$DiskInfo = Get-WmiObject Win32_DiskDrive | Select-Object -First 1
Test-VirtualizationFeature -TestName "硬盘型号" -Value $DiskInfo.Model -Keywords $VirtKeywords -Details $DiskInfo.Model

# 硬盘序列号
$TotalTests++
$DiskSerial = $DiskInfo.SerialNumber
if ([string]::IsNullOrWhiteSpace($DiskSerial)) {
    Write-Host "[X] 硬盘序列号" -ForegroundColor Red
    Write-Host "    序列号为空" -ForegroundColor Gray
    $Detected++
} elseif ($DiskSerial -match "QM|VB") {
    Write-Host "[X] 硬盘序列号" -ForegroundColor Red
    Write-Host "    可能是虚拟硬盘: $DiskSerial" -ForegroundColor Gray
    $Detected++
} else {
    Write-Host "[√] 硬盘序列号" -ForegroundColor Green
    Write-Host "    $DiskSerial" -ForegroundColor Gray
}

Write-Host ""
Write-Host "6. 网卡信息检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# 网卡信息
$NetAdapters = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.MACAddress -ne $null }
$QemuMacDetected = $false

foreach ($adapter in $NetAdapters) {
    $TotalTests++
    $mac = $adapter.MACAddress

    # 检查 QEMU 默认 MAC 前缀 (52:54:00)
    if ($mac -match "^52:54:00") {
        Write-Host "[X] MAC 地址 ($($adapter.Name))" -ForegroundColor Red
        Write-Host "    $mac (QEMU 默认前缀)" -ForegroundColor Gray
        $Detected++
        $QemuMacDetected = $true
    } else {
        Write-Host "[√] MAC 地址 ($($adapter.Name))" -ForegroundColor Green
        Write-Host "    $mac" -ForegroundColor Gray
    }
}

if (-not $QemuMacDetected -and $NetAdapters.Count -gt 0) {
    Write-Host "    未检测到 QEMU 默认 MAC 前缀" -ForegroundColor Gray
}

Write-Host ""
Write-Host "7. PCI 设备检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# PCI 设备检测
$PciDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -ne $null }
$VirtDeviceFound = $false

foreach ($device in $PciDevices) {
    if ($device.Name -match "qemu|virtio|bochs|vmware|virtualbox|vbox") {
        if (-not $VirtDeviceFound) {
            Write-Host "[X] PCI 设备" -ForegroundColor Red
            Write-Host "    检测到虚拟化设备:" -ForegroundColor Gray
            $VirtDeviceFound = $true
        }
        Write-Host "    - $($device.Name)" -ForegroundColor Gray
    }
}

$TotalTests++
if ($VirtDeviceFound) {
    $Detected++
} else {
    Write-Host "[√] PCI 设备" -ForegroundColor Green
    Write-Host "    未检测到虚拟化 PCI 设备" -ForegroundColor Gray
}

Write-Host ""
Write-Host "8. 服务检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# 检查虚拟化相关服务
$VirtServices = Get-Service | Where-Object { $_.Name -match "qemu|vmware|vbox|guest" }
$TotalTests++

if ($VirtServices.Count -gt 0) {
    Write-Host "[X] 服务检测" -ForegroundColor Red
    Write-Host "    检测到虚拟化相关服务:" -ForegroundColor Gray
    foreach ($service in $VirtServices) {
        Write-Host "    - $($service.Name): $($service.Status)" -ForegroundColor Gray
    }
    $Detected++
} else {
    Write-Host "[√] 服务检测" -ForegroundColor Green
    Write-Host "    未检测到虚拟化相关服务" -ForegroundColor Gray
}

Write-Host ""
Write-Host "9. 注册表检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# 检查注册表
$RegPaths = @(
    "HKLM:\HARDWARE\DESCRIPTION\System\BIOS",
    "HKLM:\HARDWARE\DESCRIPTION\System\SystemBiosVersion"
)

$RegVirtDetected = $false
foreach ($path in $RegPaths) {
    if (Test-Path $path) {
        $regValues = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        foreach ($prop in $regValues.PSObject.Properties) {
            if ($prop.Value -match "qemu|vmware|virtualbox|bochs|vbox") {
                if (-not $RegVirtDetected) {
                    Write-Host "[X] 注册表检测" -ForegroundColor Red
                    Write-Host "    在注册表中发现虚拟化标识:" -ForegroundColor Gray
                    $RegVirtDetected = $true
                }
                Write-Host "    $path\$($prop.Name): $($prop.Value)" -ForegroundColor Gray
            }
        }
    }
}

$TotalTests++
if ($RegVirtDetected) {
    $Detected++
} else {
    Write-Host "[√] 注册表检测" -ForegroundColor Green
    Write-Host "    注册表未发现虚拟化标识" -ForegroundColor Gray
}

Write-Host ""
Write-Host "10. 进程检测" -ForegroundColor Yellow
Write-Host "----------------------------"

# 检查虚拟化相关进程
$VirtProcesses = Get-Process | Where-Object { $_.Name -match "qemu|vmware|vbox|guest" }
$TotalTests++

if ($VirtProcesses.Count -gt 0) {
    Write-Host "[X] 进程检测" -ForegroundColor Red
    Write-Host "    检测到虚拟化相关进程:" -ForegroundColor Gray
    foreach ($proc in $VirtProcesses) {
        Write-Host "    - $($proc.Name)" -ForegroundColor Gray
    }
    $Detected++
} else {
    Write-Host "[√] 进程检测" -ForegroundColor Green
    Write-Host "    未检测到虚拟化相关进程" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  检测结果汇总" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Passed = $TotalTests - $Detected

Write-Host "总测试数: $TotalTests"
Write-Host "检测到虚拟化: $Detected" -ForegroundColor $(if ($Detected -gt 0) { "Red" } else { "Green" })
Write-Host "通过测试: $Passed" -ForegroundColor $(if ($Passed -eq $TotalTests) { "Green" } else { "Yellow" })
Write-Host ""

if ($Detected -eq 0) {
    Write-Host "[√] 优秀! 未检测到明显的虚拟化特征" -ForegroundColor Green
    Write-Host "该虚拟机配置较好地隐藏了虚拟化标识" -ForegroundColor Green
} elseif ($Detected -le 3) {
    Write-Host "[!] 警告: 检测到少量虚拟化特征" -ForegroundColor Yellow
    Write-Host "建议检查并优化失败的测试项" -ForegroundColor Yellow
} else {
    Write-Host "[X] 注意: 检测到较多虚拟化特征" -ForegroundColor Red
    Write-Host "该虚拟机容易被识别，建议重新配置" -ForegroundColor Red
}

Write-Host ""
Write-Host "提示: 请以管理员身份运行以获得完整的检测结果" -ForegroundColor Cyan
Write-Host ""

# 生成详细报告
$ReportFile = "vm-detection-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$Report = @"
虚拟化检测报告
生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

总测试数: $TotalTests
检测到虚拟化: $Detected
通过测试: $Passed

系统信息:
- 制造商: $($SysInfo.Manufacturer)
- 型号: $($SysInfo.Model)

BIOS 信息:
- 制造商: $($BiosInfo.Manufacturer)
- 版本: $($BiosInfo.Version)
- 序列号: $($BiosInfo.SerialNumber)

主板信息:
- 制造商: $($BoardInfo.Manufacturer)
- 产品: $($BoardInfo.Product)
- 序列号: $($BoardInfo.SerialNumber)

CPU 信息:
- 名称: $($CpuInfo.Name)

硬盘信息:
- 型号: $($DiskInfo.Model)
- 序列号: $($DiskInfo.SerialNumber)

结论:
$(if ($Detected -eq 0) { "未检测到明显的虚拟化特征" }
  elseif ($Detected -le 3) { "检测到少量虚拟化特征，建议优化" }
  else { "检测到较多虚拟化特征，建议重新配置" })
"@

$Report | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "详细报告已保存到: $ReportFile" -ForegroundColor Cyan
Write-Host ""

Read-Host "按 Enter 键退出"
