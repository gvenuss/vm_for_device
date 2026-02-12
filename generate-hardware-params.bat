@echo off
REM ################################################################################
REM 硬件参数随机生成器 (Windows)
REM 用途: 生成随机但真实的硬件参数，用于虚拟机配置
REM ################################################################################

setlocal enabledelayedexpansion

echo ==========================================
echo   QEMU 虚拟机硬件参数随机生成器
echo ==========================================
echo.

REM 生成随机 UUID
for /f %%i in ('powershell -Command "[guid]::NewGuid().ToString()"') do set UUID=%%i

REM 生成随机序列号
set SYSTEM_SERIAL=SYS%date:~0,4%%date:~5,2%%date:~8,2%%RANDOM%
set BOARD_SERIAL=MB%date:~0,4%%date:~5,2%%date:~8,2%%RANDOM%
set CHASSIS_SERIAL=CH%date:~0,4%%date:~5,2%%date:~8,2%%RANDOM%

REM 生成随机日期 (过去一年内)
for /f %%i in ('powershell -Command "(Get-Date).AddDays(-%RANDOM% %% 365).ToString('MM/dd/yyyy')"') do set BIOS_DATE=%%i

REM 主板制造商列表
set MANUFACTURERS[0]=ASUS
set MANUFACTURERS[1]=MSI
set MANUFACTURERS[2]=Gigabyte
set MANUFACTURERS[3]=ASRock
set MANUFACTURERS[4]=Dell Inc.
set MANUFACTURERS[5]=HP
set MANUFACTURERS[6]=Lenovo

set /a RAND_MFG=%RANDOM% %% 7
call set MANUFACTURER=%%MANUFACTURERS[!RAND_MFG!]%%

REM 根据制造商选择产品型号
if "%MANUFACTURER%"=="ASUS" (
    set PRODUCTS[0]=ROG STRIX B550-F GAMING
    set PRODUCTS[1]=TUF GAMING X570-PLUS
    set PRODUCTS[2]=PRIME Z690-P
    set PRODUCTS[3]=ROG MAXIMUS Z690 HERO
    set PRODUCT_COUNT=4
) else if "%MANUFACTURER%"=="MSI" (
    set PRODUCTS[0]=MAG B550 TOMAHAWK
    set PRODUCTS[1]=MPG Z690 CARBON WIFI
    set PRODUCTS[2]=B450 TOMAHAWK MAX
    set PRODUCTS[3]=X570-A PRO
    set PRODUCT_COUNT=4
) else if "%MANUFACTURER%"=="Gigabyte" (
    set PRODUCTS[0]=B550 AORUS ELITE
    set PRODUCTS[1]=Z690 AORUS MASTER
    set PRODUCTS[2]=X570 AORUS ULTRA
    set PRODUCTS[3]=B450M DS3H
    set PRODUCT_COUNT=4
) else if "%MANUFACTURER%"=="ASRock" (
    set PRODUCTS[0]=B550M Steel Legend
    set PRODUCTS[1]=Z690 Taichi
    set PRODUCTS[2]=X570 Phantom Gaming 4
    set PRODUCTS[3]=B450M Pro4
    set PRODUCT_COUNT=4
) else if "%MANUFACTURER%"=="Dell Inc." (
    set PRODUCTS[0]=OptiPlex 7090
    set PRODUCTS[1]=Precision 3650
    set PRODUCTS[2]=XPS 8950
    set PRODUCTS[3]=Inspiron 3880
    set PRODUCT_COUNT=4
) else if "%MANUFACTURER%"=="HP" (
    set PRODUCTS[0]=EliteDesk 800 G8
    set PRODUCTS[1]=ProDesk 600 G6
    set PRODUCTS[2]=Z2 Tower G9
    set PRODUCTS[3]=Pavilion Desktop
    set PRODUCT_COUNT=4
) else (
    set PRODUCTS[0]=ThinkCentre M90t
    set PRODUCTS[1]=IdeaCentre 5i
    set PRODUCTS[2]=Legion T7
    set PRODUCTS[3]=ThinkStation P350
    set PRODUCT_COUNT=4
)

set /a RAND_PROD=%RANDOM% %% !PRODUCT_COUNT!
call set PRODUCT=%%PRODUCTS[!RAND_PROD!]%%

REM BIOS 信息
set BIOS_VERSIONS[0]=F10
set BIOS_VERSIONS[1]=F15
set BIOS_VERSIONS[2]=F20
set BIOS_VERSIONS[3]=F23
set BIOS_VERSIONS[4]=1.20
set BIOS_VERSIONS[5]=2.10
set BIOS_VERSIONS[6]=3.05
set BIOS_VERSIONS[7]=A05
set BIOS_VERSIONS[8]=A10

set /a RAND_BIOS=%RANDOM% %% 9
call set BIOS_VERSION=%%BIOS_VERSIONS[!RAND_BIOS!]%%

if "%MANUFACTURER%"=="Dell Inc." (
    set BIOS_VENDOR=Dell Inc.
) else if "%MANUFACTURER%"=="HP" (
    set BIOS_VENDOR=HP
) else if "%MANUFACTURER%"=="Lenovo" (
    set BIOS_VENDOR=Lenovo
) else (
    set BIOS_VENDOR=American Megatrends Inc.
)

REM 硬盘信息
set HDD_BRANDS[0]=WDC
set HDD_BRANDS[1]=Samsung
set HDD_BRANDS[2]=Seagate
set HDD_BRANDS[3]=Crucial
set HDD_BRANDS[4]=Kingston

set /a RAND_HDD=%RANDOM% %% 5
call set HDD_BRAND=%%HDD_BRANDS[!RAND_HDD!]%%

if "!HDD_BRAND!"=="WDC" (
    set HDD_MODEL=WDC WD10EZEX-08WN4A0
    set HDD_SERIAL=WD-WCAV%RANDOM%%RANDOM%
) else if "!HDD_BRAND!"=="Samsung" (
    set HDD_MODEL=Samsung SSD 870 EVO 500GB
    set HDD_SERIAL=S5H2N%RANDOM%%RANDOM%
) else if "!HDD_BRAND!"=="Seagate" (
    set HDD_MODEL=ST1000DM010-2EP102
    set HDD_SERIAL=ZN1%RANDOM%%RANDOM%
) else if "!HDD_BRAND!"=="Crucial" (
    set HDD_MODEL=CT500MX500SSD1
    set HDD_SERIAL=2038%RANDOM%%RANDOM%
) else (
    set HDD_MODEL=SA400S37480G
    set HDD_SERIAL=50026B%RANDOM%%RANDOM%
)

REM 生成 WWN
for /f %%i in ('powershell -Command "0x50014ee{0:x9} -f (Get-Random -Maximum 999999999)"') do set HDD_WWN=%%i

REM 网卡信息
set NIC_VENDORS[0]=Intel:00:1B:21
set NIC_VENDORS[1]=Realtek:00:E0:4C
set NIC_VENDORS[2]=Broadcom:00:10:18
set NIC_VENDORS[3]=Qualcomm:00:03:7F

set /a RAND_NIC=%RANDOM% %% 4
call set NIC_VENDOR=%%NIC_VENDORS[!RAND_NIC!]%%

for /f "tokens=1,2 delims=:" %%a in ("!NIC_VENDOR!") do (
    set NIC_NAME=%%a
    set NIC_OUI=%%b
)

REM 生成随机 MAC 地址后三字节
for /f %%i in ('powershell -Command "'{0:X2}:{1:X2}:{2:X2}' -f (Get-Random -Max 256),(Get-Random -Max 256),(Get-Random -Max 256)"') do set MAC_SUFFIX=%%i
set MAC_ADDRESS=!NIC_OUI!:!MAC_SUFFIX!

REM 显示结果
echo 1. 系统信息 (SMBIOS Type 1)
echo ----------------------------
echo UUID: %UUID%
echo 序列号: %SYSTEM_SERIAL%
echo 制造商: %MANUFACTURER%
echo 产品型号: %PRODUCT%
echo.

echo 2. BIOS 信息 (SMBIOS Type 0)
echo ----------------------------
echo BIOS 厂商: %BIOS_VENDOR%
echo BIOS 版本: %BIOS_VERSION%
echo BIOS 日期: %BIOS_DATE%
echo.

echo 3. 主板信息 (SMBIOS Type 2)
echo ----------------------------
echo 主板序列号: %BOARD_SERIAL%
echo.

echo 4. 机箱信息 (SMBIOS Type 3)
echo ----------------------------
echo 机箱序列号: %CHASSIS_SERIAL%
echo.

echo 5. 硬盘信息
echo ----------------------------
echo 硬盘品牌: %HDD_BRAND%
echo 硬盘型号: %HDD_MODEL%
echo 硬盘序列号: %HDD_SERIAL%
echo WWN: %HDD_WWN%
echo.

echo 6. 网卡信息
echo ----------------------------
echo 网卡厂商: %NIC_NAME%
echo MAC 地址: %MAC_ADDRESS%
echo.

echo ==========================================
echo   生成的 QEMU 配置参数
echo ==========================================
echo.

echo # SMBIOS 配置
echo -smbios type=0,vendor="%BIOS_VENDOR%",version="%BIOS_VERSION%",date="%BIOS_DATE%" \
echo -smbios type=1,manufacturer="%MANUFACTURER%",product="%PRODUCT%",version="1.0",serial="%SYSTEM_SERIAL%",uuid="%UUID%",sku="SKU-001",family="Desktop" \
echo -smbios type=2,manufacturer="%MANUFACTURER%",product="%PRODUCT%",version="Rev 1.02",serial="%BOARD_SERIAL%",asset="Asset-MB-001",location="Base Board" \
echo -smbios type=3,manufacturer="%MANUFACTURER%",version="1.0",serial="%CHASSIS_SERIAL%",asset="Asset-CH-001" \
echo.
echo # 硬盘配置
echo -drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \
echo -device ide-hd,drive=disk0,serial="%HDD_SERIAL%",model="%HDD_MODEL%",wwn=%HDD_WWN% \
echo.
echo # 网卡配置
echo -netdev user,id=net0 \
echo -device e1000,netdev=net0,mac=%MAC_ADDRESS%
echo.

echo ==========================================
echo   配置已生成完成
echo ==========================================
echo.

REM 保存到文件
set OUTPUT_FILE=vm-config-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.txt
set OUTPUT_FILE=%OUTPUT_FILE: =0%

(
echo # 虚拟机硬件配置
echo # 生成时间: %date% %time%
echo.
echo 系统 UUID: %UUID%
echo 系统序列号: %SYSTEM_SERIAL%
echo 制造商: %MANUFACTURER%
echo 产品型号: %PRODUCT%
echo.
echo BIOS 厂商: %BIOS_VENDOR%
echo BIOS 版本: %BIOS_VERSION%
echo BIOS 日期: %BIOS_DATE%
echo.
echo 主板序列号: %BOARD_SERIAL%
echo 机箱序列号: %CHASSIS_SERIAL%
echo.
echo 硬盘型号: %HDD_MODEL%
echo 硬盘序列号: %HDD_SERIAL%
echo WWN: %HDD_WWN%
echo.
echo 网卡厂商: %NIC_NAME%
echo MAC 地址: %MAC_ADDRESS%
echo.
echo ---
echo.
echo QEMU 配置参数:
echo.
echo -smbios type=0,vendor="%BIOS_VENDOR%",version="%BIOS_VERSION%",date="%BIOS_DATE%" \
echo -smbios type=1,manufacturer="%MANUFACTURER%",product="%PRODUCT%",version="1.0",serial="%SYSTEM_SERIAL%",uuid="%UUID%",sku="SKU-001",family="Desktop" \
echo -smbios type=2,manufacturer="%MANUFACTURER%",product="%PRODUCT%",version="Rev 1.02",serial="%BOARD_SERIAL%",asset="Asset-MB-001",location="Base Board" \
echo -smbios type=3,manufacturer="%MANUFACTURER%",version="1.0",serial="%CHASSIS_SERIAL%",asset="Asset-CH-001" \
echo -drive file=disk.qcow2,if=none,id=disk0,format=qcow2 \
echo -device ide-hd,drive=disk0,serial="%HDD_SERIAL%",model="%HDD_MODEL%",wwn=%HDD_WWN% \
echo -netdev user,id=net0 \
echo -device e1000,netdev=net0,mac=%MAC_ADDRESS%
) > "%OUTPUT_FILE%"

echo 配置已保存到: %OUTPUT_FILE%
echo.

pause
