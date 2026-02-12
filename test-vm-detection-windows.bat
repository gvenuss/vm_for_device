@echo off
REM ################################################################################
REM 虚拟化检测测试脚本 (Windows)
REM 用途: 在虚拟机内运行，检测是否能被识别为虚拟机
REM ################################################################################

echo ==========================================
echo   虚拟化检测测试工具 (Windows)
echo ==========================================
echo.

set DETECTED=0
set TOTAL_TESTS=0

echo 1. 系统信息检测
echo ----------------------------

REM 检查系统制造商
for /f "tokens=2 delims==" %%a in ('wmic computersystem get manufacturer /value ^| find "="') do set SYS_MANUFACTURER=%%a
echo 系统制造商: %SYS_MANUFACTURER%
echo %SYS_MANUFACTURER% | findstr /i "qemu bochs virtual vmware virtualbox xen kvm" >nul
if %errorlevel%==0 (
    echo [X] 失败: 包含虚拟化关键字
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

REM 检查系统型号
for /f "tokens=2 delims==" %%a in ('wmic computersystem get model /value ^| find "="') do set SYS_MODEL=%%a
echo 系统型号: %SYS_MODEL%
echo %SYS_MODEL% | findstr /i "qemu bochs virtual vmware virtualbox xen kvm" >nul
if %errorlevel%==0 (
    echo [X] 失败: 包含虚拟化关键字
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

echo 2. BIOS 信息检测
echo ----------------------------

REM 检查 BIOS 制造商
for /f "tokens=2 delims==" %%a in ('wmic bios get manufacturer /value ^| find "="') do set BIOS_MANUFACTURER=%%a
echo BIOS 制造商: %BIOS_MANUFACTURER%
echo %BIOS_MANUFACTURER% | findstr /i "qemu bochs virtual vmware virtualbox xen kvm seabios" >nul
if %errorlevel%==0 (
    echo [X] 失败: 包含虚拟化关键字
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

REM 检查 BIOS 版本
for /f "tokens=2 delims==" %%a in ('wmic bios get version /value ^| find "="') do set BIOS_VERSION=%%a
echo BIOS 版本: %BIOS_VERSION%
echo %BIOS_VERSION% | findstr /i "qemu bochs virtual vmware virtualbox vbox" >nul
if %errorlevel%==0 (
    echo [X] 失败: 包含虚拟化关键字
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

REM 检查 BIOS 序列号
for /f "tokens=2 delims==" %%a in ('wmic bios get serialnumber /value ^| find "="') do set BIOS_SERIAL=%%a
echo BIOS 序列号: %BIOS_SERIAL%
echo %BIOS_SERIAL% | findstr /i "0 none" >nul
if %errorlevel%==0 (
    echo [X] 失败: 序列号无效或为空
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

echo 3. 主板信息检测
echo ----------------------------

REM 检查主板制造商
for /f "tokens=2 delims==" %%a in ('wmic baseboard get manufacturer /value ^| find "="') do set BOARD_MANUFACTURER=%%a
echo 主板制造商: %BOARD_MANUFACTURER%
echo %BOARD_MANUFACTURER% | findstr /i "qemu bochs virtual vmware virtualbox xen kvm" >nul
if %errorlevel%==0 (
    echo [X] 失败: 包含虚拟化关键字
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

REM 检查主板产品名
for /f "tokens=2 delims==" %%a in ('wmic baseboard get product /value ^| find "="') do set BOARD_PRODUCT=%%a
echo 主板产品: %BOARD_PRODUCT%
echo %BOARD_PRODUCT% | findstr /i "qemu bochs virtual vmware virtualbox xen kvm" >nul
if %errorlevel%==0 (
    echo [X] 失败: 包含虚拟化关键字
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

echo 4. CPU 信息检测
echo ----------------------------

REM 检查 CPU 名称
for /f "tokens=2 delims==" %%a in ('wmic cpu get name /value ^| find "="') do set CPU_NAME=%%a
echo CPU 名称: %CPU_NAME%
echo %CPU_NAME% | findstr /i "qemu virtual" >nul
if %errorlevel%==0 (
    echo [X] 失败: 包含虚拟化关键字
    set /a DETECTED+=1
) else (
    echo [√] 通过
)
set /a TOTAL_TESTS+=1
echo.

echo 5. 硬盘信息检测
echo ----------------------------

REM 检查硬盘型号
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get model /value ^| find "="') do (
    echo 硬盘型号: %%a
    echo %%a | findstr /i "qemu vbox virtual vmware" >nul
    if !errorlevel!==0 (
        echo [X] 失败: 包含虚拟化关键字
        set /a DETECTED+=1
    ) else (
        echo [√] 通过
    )
    set /a TOTAL_TESTS+=1
    goto :disk_done
)
:disk_done
echo.

REM 检查硬盘序列号
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get serialnumber /value ^| find "="') do (
    echo 硬盘序列号: %%a
    echo %%a | findstr /i "qm vb" >nul
    if !errorlevel!==0 (
        echo [X] 失败: 可能是虚拟硬盘
        set /a DETECTED+=1
    ) else (
        echo [√] 通过
    )
    set /a TOTAL_TESTS+=1
    goto :serial_done
)
:serial_done
echo.

echo 6. 网卡信息检测
echo ----------------------------

REM 检查网卡 MAC 地址
echo 网卡 MAC 地址:
wmic nic where "MACAddress is not null" get name,macaddress /format:list | findstr /v "^$"
wmic nic where "MACAddress is not null" get macaddress /format:list | findstr "52:54:00" >nul
if %errorlevel%==0 (
    echo [X] 失败: 检测到 QEMU 默认 MAC 前缀 (52:54:00)
    set /a DETECTED+=1
) else (
    echo [√] 通过: 未检测到 QEMU 默认 MAC 前缀
)
set /a TOTAL_TESTS+=1
echo.

echo 7. 注册表检测
echo ----------------------------

REM 检查虚拟化相关注册表项
reg query "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemManufacturer 2>nul | findstr /i "qemu vmware virtualbox" >nul
if %errorlevel%==0 (
    echo [X] 失败: 注册表中发现虚拟化标识
    set /a DETECTED+=1
) else (
    echo [√] 通过: 注册表未发现虚拟化标识
)
set /a TOTAL_TESTS+=1
echo.

echo 8. 服务检测
echo ----------------------------

REM 检查虚拟化相关服务
sc query | findstr /i "qemu vmware vbox guest" >nul
if %errorlevel%==0 (
    echo [X] 失败: 检测到虚拟化相关服务
    set /a DETECTED+=1
) else (
    echo [√] 通过: 未检测到虚拟化相关服务
)
set /a TOTAL_TESTS+=1
echo.

echo ==========================================
echo   检测结果汇总
echo ==========================================
echo.
echo 总测试数: %TOTAL_TESTS%
echo 检测到虚拟化: %DETECTED%
set /a PASSED=%TOTAL_TESTS%-%DETECTED%
echo 通过测试: %PASSED%
echo.

if %DETECTED%==0 (
    echo [√] 优秀! 未检测到明显的虚拟化特征
    echo 该虚拟机配置较好地隐藏了虚拟化标识
) else if %DETECTED% LEQ 3 (
    echo [!] 警告: 检测到少量虚拟化特征
    echo 建议检查并优化失败的测试项
) else (
    echo [X] 注意: 检测到较多虚拟化特征
    echo 该虚拟机容易被识别，建议重新配置
)

echo.
pause
