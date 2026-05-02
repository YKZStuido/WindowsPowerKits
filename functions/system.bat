@ECHO OFF & CHCP 65001 > NUL
SETLOCAL ENABLEDELAYEDEXPANSION

SET "op=%~dp0..\scripts\op.bat"
SET "wait=%~dp0..\scripts\wait.bat"

IF NOT DEFINED ESC (
    FOR /F %%a IN ('powershell -NoProfile -Command "[char]27"') DO SET "ESC=%%a"
)
SET "R=!ESC![0m"
SET "BOLD=!ESC![1m"
SET "DIM=!ESC![2m"
SET "RED=!ESC![31m"
SET "GREEN=!ESC![32m"
SET "YELLOW=!ESC![33m"
SET "BLUE=!ESC![34m"
SET "MAGENTA=!ESC![35m"
SET "CYAN=!ESC![36m"
SET "WHITE=!ESC![97m"
SET "BG_RED=!ESC![41m"
SET "BG_GREEN=!ESC![42m"

:MENU
COLOR 07 & CLS
TITLE WindowsPowerKits - 系统工具

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!系统工具!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  系统工具!R!                                                           !CYAN!│!R!
ECHO  !CYAN!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!1!R!  系统概括        查看计算机、OS、CPU、内存、磁盘、网络信息               !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !DIM!9  返回!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
ECHO  !DIM!  ────────────────────────────────────────────────────────────────────────────────!R!
SET /P "ch=   ❯ "
ECHO.

IF "!ch!" EQU "1" (
    GOTO OVERVIEW
) ELSE IF "!ch!" EQU "9" (
    CALL "%op%" dim "返回主菜单..."
    CALL "%wait%" 300
    ENDLOCAL & EXIT /B 0
) ELSE (
    CALL "%op%" warn "无效选项，请重新输入"
    CALL "%wait%" 400
    GOTO MENU
)

:OVERVIEW
CLS
TITLE WindowsPowerKits - 系统概括

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!系统概括!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  系统工具  ❯  系统概括!R!                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.

ECHO  !CYAN!┌─ !BOLD!基本信息!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !CYAN![i]!R!  计算机名  !DIM!:!R!  !WHITE!!BOLD!%COMPUTERNAME%!R!
ECHO   !CYAN![i]!R!  当前用户  !DIM!:!R!  !WHITE!!BOLD!%USERNAME%!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

ECHO  !CYAN!┌─ !BOLD!系统 / 处理器 + 显卡!R!!CYAN! ───────────────────────────────────────────────────────┐!R!
SET "_val="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption.Trim()"') DO SET "_val=%%A"
ECHO   !CYAN![i]!R!  操作系统  !DIM!:!R!  !WHITE!%_val%!R!
SET "_val="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).Name.Trim()"') DO SET "_val=%%A"
ECHO   !CYAN![i]!R!  处理器    !DIM!:!R!  !WHITE!%_val%!R!
SET "_val="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController | Where-Object {$_.Name -notmatch 'Remote|Virtual|Basic'} | Select-Object -First 1).Name.Trim()"') DO SET "_val=%%A"
IF NOT DEFINED _val FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name.Trim()"') DO SET "_val=%%A"
ECHO   !CYAN![i]!R!  显卡      !DIM!:!R!  !WHITE!%_val%!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

ECHO  !CYAN!┌─ !BOLD!内存 / 磁盘!R!!CYAN! ────────────────────────────────────────────────────────────────┐!R!
SET "_ramtotal=" & SET "_ramfree="
FOR /F %%A IN ('powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize/1024)"') DO SET "_ramtotal=%%A"
FOR /F %%A IN ('powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"') DO SET "_ramfree=%%A"
SET /A "_ramused=_ramtotal-_ramfree" 2>NUL
ECHO   !CYAN![i]!R!  内存      !DIM!:!R!  总计 !WHITE!!BOLD!%_ramtotal% MB!R!   已用 !YELLOW!%_ramused% MB!R!   可用 !GREEN!%_ramfree% MB!R!
FOR /F "delims=" %%L IN ('powershell -NoProfile -Command "Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -ne $null} | ForEach-Object { $t=[math]::Round(($_.Used+$_.Free)/1GB,1); $u=[math]::Round($_.Used/1GB,1); $f=[math]::Round($_.Free/1GB,1); $_.Name+[char]124+$t+[char]124+$u+[char]124+$f }"') DO (
    FOR /F "tokens=1,2,3,4 delims=|" %%a IN ("%%L") DO (
        ECHO   !CYAN![i]!R!  磁盘 %%a:  !DIM!:!R!  总计 !WHITE!!BOLD!%%b GB!R!   已用 !YELLOW!%%c GB!R!   可用 !GREEN!%%d GB!R!
    )
)
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

ECHO  !CYAN!┌─ !BOLD!网络 + 网络适配器!R!!CYAN! ──────────────────────────────────────────────────────────┐!R!
SET "_ip="
FOR /F "tokens=2 delims=:" %%A IN ('ipconfig ^| findstr /I "IPv4"') DO (
    IF NOT DEFINED _ip (
        SET "_cand=%%A"
        FOR /F "tokens=* delims= " %%B IN ("!_cand!") DO (
            IF NOT "%%B"=="127.0.0.1" SET "_ip=%%B"
        )
    )
)
IF NOT DEFINED _ip SET "_ip=获取失败"
ECHO   !CYAN![i]!R!  IP 地址   !DIM!:!R!  !WHITE!!BOLD!%_ip%!R!
FOR /F "delims=" %%L IN ('powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $ip=(Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress; if(-not $ip){$ip='N/A'}; $_.Name+[char]124+$ip }"') DO (
    FOR /F "tokens=1,2 delims=|" %%a IN ("%%L") DO (
        ECHO   !CYAN![i]!R!  适配器    !DIM!:!R!  !WHITE!%%a!R!  !DIM!IPv4:!R! !GREEN!%%b!R!
    )
)
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL & GOTO MENU