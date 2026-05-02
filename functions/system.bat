@ECHO OFF & CHCP 65001 > NUL
SETLOCAL ENABLEDELAYEDEXPANSION

REM ============================================================================
REM  functions\system.bat —— 系统工具子模块
REM ----------------------------------------------------------------------------
REM  当前提供的功能：
REM    1) 系统概括 —— 计算机/用户、操作系统、CPU、GPU、内存、磁盘、网络
REM
REM  设计要点：
REM    * 通过 %~dp0 重新声明工具脚本路径，因为父批处理的 %ui% / %wait% 在
REM      CALL 后并不能保证仍指向正确位置（依赖当前工作目录）。
REM    * 由于 SETLOCAL 会切断父作用域的环境变量继承，颜色相关 ANSI 变量
REM      必须在本文件中重新初始化。
REM    * 一切 PowerShell 调用使用 -NoProfile 跳过用户配置，提升启动速度并
REM      避免被自定义 profile 干扰输出。
REM ============================================================================

REM ── 共享工具脚本 ────────────────────────────────────────────────────────
SET "ui=%~dp0..\scripts\ui.bat"
SET "wait=%~dp0..\scripts\wait.bat"

REM ── ANSI 颜色变量初始化（局部作用域） ───────────────────────────────────
REM   通过 ui.bat 的 init 子命令注入 ESC/R/BOLD/RED/GREEN/... 等。
REM   因本文件已 SETLOCAL，ui init 设置的变量也只在本作用域有效，
REM   不会泄漏给调用方，符合模块化预期。
CALL "%ui%" init

REM ============================================================================
REM  MENU —— 系统工具子菜单
REM ============================================================================
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
SET "ch="
SET /P "ch=   ❯ "
ECHO.

IF "!ch!"=="1" (
    GOTO OVERVIEW
) ELSE IF "!ch!"=="9" (
    CALL "%ui%" dim "返回主菜单..."
    CALL "%wait%" 300
    ENDLOCAL & EXIT /B 0
) ELSE (
    CALL "%ui%" warn "无效选项，请重新输入"
    CALL "%wait%" 400
    GOTO MENU
)

REM ============================================================================
REM  OVERVIEW —— 系统概括
REM    依次输出 4 个分组：
REM      a) 基本信息 (计算机名 / 当前用户)
REM      b) 系统 + 处理器 + 显卡
REM      c) 内存 + 磁盘
REM      d) 网络 + 网络适配器
REM    采用 80 列宽 ┌──┐ / └──┘ 区段框；标题嵌入上边框。
REM ============================================================================
:OVERVIEW
CLS
TITLE WindowsPowerKits - 系统概括

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!系统概括!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  系统工具  ❯  系统概括!R!                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.

REM ── (a) 基本信息 ────────────────────────────────────────────────────────
ECHO  !CYAN!┌─ !BOLD!基本信息!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !CYAN![i]!R!  计算机名  !DIM!:!R!  !WHITE!!BOLD!%COMPUTERNAME%!R!
ECHO   !CYAN![i]!R!  当前用户  !DIM!:!R!  !WHITE!!BOLD!%USERNAME%!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

REM ── (b) 系统 / 处理器 + 显卡 ────────────────────────────────────────────
REM    每项查询都先把 _val 清空，再用 FOR /F 捕获 PowerShell 单行输出。
REM    PowerShell 调用统一加 .Trim() 去除首尾空白，避免对齐错乱。
ECHO  !CYAN!┌─ !BOLD!系统 / 处理器 + 显卡!R!!CYAN! ───────────────────────────────────────────────────────┐!R!

SET "_val="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption.Trim()"') DO SET "_val=%%A"
IF NOT DEFINED _val SET "_val=未知"
ECHO   !CYAN![i]!R!  操作系统  !DIM!:!R!  !WHITE!!_val!!R!

SET "_val="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).Name.Trim()"') DO SET "_val=%%A"
IF NOT DEFINED _val SET "_val=未知"
ECHO   !CYAN![i]!R!  处理器    !DIM!:!R!  !WHITE!!_val!!R!

REM   优先选择物理显卡：排除 Remote/Virtual/Basic 显示适配器；若全部被排除
REM   则退化为列表中的第一个（保证至少有显卡名输出）。
SET "_val="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController | Where-Object {$_.Name -notmatch 'Remote|Virtual|Basic'} | Select-Object -First 1).Name.Trim()"') DO SET "_val=%%A"
IF NOT DEFINED _val FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name.Trim()"') DO SET "_val=%%A"
IF NOT DEFINED _val SET "_val=未知"
ECHO   !CYAN![i]!R!  显卡      !DIM!:!R!  !WHITE!!_val!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

REM ── (c) 内存 / 磁盘 ─────────────────────────────────────────────────────
ECHO  !CYAN!┌─ !BOLD!内存 / 磁盘!R!!CYAN! ────────────────────────────────────────────────────────────────┐!R!

REM   Win32_OperatingSystem 给出 KB 单位，除 1024 转 MB。
SET "_ramtotal=" & SET "_ramfree="
FOR /F %%A IN ('powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize/1024)"') DO SET "_ramtotal=%%A"
FOR /F %%A IN ('powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"') DO SET "_ramfree=%%A"
IF NOT DEFINED _ramtotal SET "_ramtotal=0"
IF NOT DEFINED _ramfree  SET "_ramfree=0"
SET /A "_ramused=_ramtotal-_ramfree" 2>NUL
ECHO   !CYAN![i]!R!  内存      !DIM!:!R!  总计 !WHITE!!BOLD!!_ramtotal! MB!R!   已用 !YELLOW!!_ramused! MB!R!   可用 !GREEN!!_ramfree! MB!R!

REM   Get-PSDrive 仅取实际有 Used 的文件系统盘；输出 "<盘符>|<总GB>|<已用GB>|<可用GB>"，
REM   通过 [char]124 安全注入分隔符（避免在 PowerShell 字符串里转义 |）。
FOR /F "delims=" %%L IN ('powershell -NoProfile -Command "Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -ne $null} | ForEach-Object { $t=[math]::Round(($_.Used+$_.Free)/1GB,1); $u=[math]::Round($_.Used/1GB,1); $f=[math]::Round($_.Free/1GB,1); $_.Name+[char]124+$t+[char]124+$u+[char]124+$f }"') DO (
    FOR /F "tokens=1,2,3,4 delims=|" %%a IN ("%%L") DO (
        ECHO   !CYAN![i]!R!  磁盘 %%a:  !DIM!:!R!  总计 !WHITE!!BOLD!%%b GB!R!   已用 !YELLOW!%%c GB!R!   可用 !GREEN!%%d GB!R!
    )
)
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

REM ── (d) 网络 + 网络适配器 ───────────────────────────────────────────────
ECHO  !CYAN!┌─ !BOLD!网络 + 网络适配器!R!!CYAN! ──────────────────────────────────────────────────────────┐!R!

REM   主 IP：扫描 ipconfig 第一条非环回 IPv4。两层 FOR 用于
REM     1) 提取冒号右侧子串
REM     2) 去掉首部空白（tokens=* delims= 自动 trim）
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
ECHO   !CYAN![i]!R!  IP 地址   !DIM!:!R!  !WHITE!!BOLD!!_ip!!R!

REM   适配器明细：仅列 Status=Up 的网卡，附带其 IPv4 地址（无则 N/A）。
FOR /F "delims=" %%L IN ('powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $ip=(Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress; if(-not $ip){$ip='N/A'}; $_.Name+[char]124+$ip }"') DO (
    FOR /F "tokens=1,2 delims=|" %%a IN ("%%L") DO (
        ECHO   !CYAN![i]!R!  适配器    !DIM!:!R!  !WHITE!%%a!R!  !DIM!IPv4:!R! !GREEN!%%b!R!
    )
)
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.

ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO MENU
