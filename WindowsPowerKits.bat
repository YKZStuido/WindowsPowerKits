@ECHO OFF & CHCP 65001 > NUL
SETLOCAL ENABLEDELAYEDEXPANSION

REM ============================================================================
REM  WindowsPowerKits.bat —— 主入口
REM ----------------------------------------------------------------------------
REM  职责：
REM    1. 解析命令行启动参数（--bypass_system_version / --bypass_terimal_type）
REM    2. 校验运行环境：Windows 10 (Build ≥ 10240) + Windows Terminal
REM    3. 校验依赖文件存在
REM    4. 渲染主菜单并将选项分发到 functions\ 下的子模块
REM
REM  环境：
REM    必须在 Windows Terminal 中以 UTF-8 (CHCP 65001) 运行；
REM    依赖 ANSI 转义序列实现彩色输出。
REM ============================================================================

:INIT
COLOR 07 & CLS
CD /D "%~dp0"

REM ── 共享工具与子模块路径 ────────────────────────────────────────────────
SET "ui=.\scripts\ui.bat"
SET "wait=.\scripts\wait.bat"
SET "system=.\functions\system.bat"
SET "ver=0.2.0"

REM ── 启动参数解析 ────────────────────────────────────────────────────────
REM   --bypass_system_version  绕过系统版本检测
REM   --bypass_terimal_type    绕过 Windows Terminal 检测
REM   注意：--bypass_terimal_type 拼写已沿用历史命名，保持向后兼容
SET "_bypass_sv=0"
SET "_bypass_tt=0"
:PARSE_ARGS
IF "%~1"=="" GOTO DONE_ARGS
IF /I "%~1"=="--bypass_system_version" SET "_bypass_sv=1"
IF /I "%~1"=="--bypass_terimal_type"   SET "_bypass_tt=1"
SHIFT
GOTO PARSE_ARGS
:DONE_ARGS

REM ── 在主作用域注入 ANSI 颜色变量（ESC/R/BOLD/RED/...）────────────────────
REM   ui.bat 的 init 子命令不使用 SETLOCAL，因此变量会回填到本作用域。
REM   依赖检查必须在 init 之前完成，因为 init 之后才能调用其它子命令。
IF NOT EXIST "%ui%"     GOTO ERR_UI
IF NOT EXIST "%wait%"   GOTO ERR_WAIT
IF NOT EXIST "%system%" GOTO ERR_SYS
CALL "%ui%" init

TITLE WindowsPowerKits - 初始化

REM ── 系统版本检测（Windows 10 Build ≥ 10240）─────────────────────────────
REM   通过注册表读取 CurrentBuild。若读取失败或值非数字，退化为 0。
SET "_build="
FOR /F "tokens=*" %%B IN ('powershell -NoProfile -Command "(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild"') DO SET "_build=%%B"
SET "_buildnum=0"
IF DEFINED _build SET /A "_buildnum=_build" 2>NUL

SET "_sv_ok=1"
IF !_buildnum! LSS 10240 SET "_sv_ok=0"
IF "!_sv_ok!"=="0" IF "!_bypass_sv!"=="0" GOTO ERR_OS

REM ── 终端环境检测（Windows Terminal 设置 WT_SESSION）─────────────────────
SET "_tt_ok=1"
IF NOT DEFINED WT_SESSION SET "_tt_ok=0"
IF "!_tt_ok!"=="0" IF "!_bypass_tt!"=="0" GOTO ERR_WT

REM ── 检测结果报告（无重复消息：每项只输出一次）───────────────────────────
IF "!_sv_ok!"=="1" (
    CALL "%ui%" ok   "系统检测通过  (Build !_buildnum!)"
) ELSE (
    CALL "%ui%" warn "系统版本检测已绕过  ^(Build !_buildnum! ^< 10240^)"
)
IF "!_tt_ok!"=="1" (
    CALL "%ui%" ok   "终端检测通过  (Windows Terminal)"
) ELSE (
    CALL "%ui%" warn "终端类型检测已绕过  ^(非 Windows Terminal^)"
)
CALL "%ui%" ok "依赖检查通过"
CALL "%ui%" ok "初始化完成"
CALL "%wait%" 150
GOTO MAIN_MENU

REM ── 错误跳转表 ──────────────────────────────────────────────────────────
:ERR_OS
CALL :ERROR UNSUPPORTED_OS "此工具需要 Windows 10+ 的系统，或使用 --bypass_system_version 绕过"
GOTO :EOF
:ERR_WT
CALL :ERROR UNSUPPORTED_TERMINAL "请在 Windows 终端 中运行此工具，或使用 --bypass_terimal_type 绕过"
GOTO :EOF
:ERR_UI
CALL :ERROR FILE_NOT_FOUND "找不到文件: %ui%"
GOTO :EOF
:ERR_WAIT
CALL :ERROR FILE_NOT_FOUND "找不到文件: %wait%"
GOTO :EOF
:ERR_SYS
CALL :ERROR FILE_NOT_FOUND "找不到文件: %system%"
GOTO :EOF

REM ============================================================================
REM  MAIN_MENU —— 主菜单
REM    采用 80 列宽 Unicode 边框 + 左侧 ASCII Logo + 右侧功能列表的双栏布局。
REM    选项编号绿色显示；返回 / 退出项使用 DIM 弱化。
REM ============================================================================
:MAIN_MENU
COLOR 07 & CLS
TITLE WindowsPowerKits

ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!WindowsPowerKits  !YELLOW!v%ver%!R!                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!by Ya Kezhou!R!                                                                !CYAN!│!R!
ECHO  !CYAN!├──────────────────────────────────┬───────────────────────────────────────────┤!R!
ECHO  !CYAN!│!R!                                  !CYAN!│!R!                                           !CYAN!│!R!
ECHO  !CYAN!│!R!   !BOLD!!WHITE!██╗    ██╗██████╗ ██╗  ██╗!R!     !CYAN!│!R!   !BOLD!!WHITE!功能列表!R!                                !CYAN!│!R!
ECHO  !CYAN!│!R!   !BOLD!!WHITE!██║    ██║██╔══██╗██║ ██╔╝!R!     !CYAN!│!R!                                           !CYAN!│!R!
ECHO  !CYAN!│!R!   !BOLD!!WHITE!██║ █╗ ██║██████╔╝█████╔╝ !R!     !CYAN!│!R!   !GREEN!1!R!  系统工具                             !CYAN!│!R!
ECHO  !CYAN!│!R!   !BOLD!!WHITE!██║███╗██║██╔═══╝ ██╔═██╗ !R!     !CYAN!│!R!                                           !CYAN!│!R!
ECHO  !CYAN!│!R!   !BOLD!!WHITE!╚███╔███╔╝██║     ██║  ██╗!R!     !CYAN!│!R!   !DIM!9  退出!R!                                 !CYAN!│!R!
ECHO  !CYAN!│!R!   !BOLD!!WHITE! ╚══╝╚══╝ ╚═╝     ╚═╝  ╚═╝!R!     !CYAN!│!R!                                           !CYAN!│!R!
ECHO  !CYAN!│!R!                                  !CYAN!│!R!                                           !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────┴───────────────────────────────────────────╯!R!
ECHO.
SET "ch="
SET /P "ch=   ❯ "
ECHO.

REM ── 菜单分发 ────────────────────────────────────────────────────────────
IF "!ch!"=="1" (
    CALL "%system%"
    GOTO MAIN_MENU
) ELSE IF "!ch!"=="9" (
    CALL "%ui%" dim "再见！"
    ENDLOCAL & EXIT /B 0
) ELSE (
    CALL "%ui%" warn "无效选项，请重新输入"
    CALL "%wait%" 500
    GOTO MAIN_MENU
)

REM ============================================================================
REM  ERROR —— 全屏红色错误对话框，按任意键退出
REM    %1 = 错误代码（短）   %2 = 错误描述（长，最长 74 列）
REM
REM  注意：本例程必须自包含，不能依赖 ui.bat。
REM    ERR_UI 路径正是因为 ui.bat 缺失或损坏才会跳转到这里——若错误对话框
REM    再去 CALL ui.bat，将无法显示任何提示，使用户陷入"静默失败"。因此：
REM      1) 颜色变量本地重新初始化（不依赖之前的 ui init）；
REM      2) 边框/对话框完全内联，不调用 ui errbox。
REM    若 PowerShell 也不可用（无法获取 ESC），则降级为纯文本输出。
REM ============================================================================
:ERROR
COLOR 07 & CLS
TITLE WindowsPowerKits - 错误
SET "_ec=%~1"
SET "_em=%~2"

REM ── 自包含 ANSI 颜色初始化（覆盖父作用域已有变量也无妨）────────────────
SET "_ESC="
FOR /F %%a IN ('powershell -NoProfile -Command "[char]27" 2^>NUL') DO SET "_ESC=%%a"
IF DEFINED _ESC (
    SET "_R=!_ESC![0m"
    SET "_BOLD=!_ESC![1m"
    SET "_DIM=!_ESC![2m"
    SET "_RED=!_ESC![31m"
    SET "_WHITE=!_ESC![97m"
) ELSE (
    REM PowerShell 不可用：所有色码留空，退化为纯文本
    SET "_R=" & SET "_BOLD=" & SET "_DIM=" & SET "_RED=" & SET "_WHITE="
)

REM ── 文本切片到 74 列宽（71 个空格右填充以保证对齐）───────────────────
SET "_pad=                                                                       "
SET "_ec_line=!_ec!!_pad!"
SET "_em_line=!_em!!_pad!"

ECHO.
ECHO  !_RED!╭──────────────────────────────────────────────────────────────────────────────╮!_R!
ECHO  !_RED!│!_R!  !_BOLD!!_WHITE!错误!_R!                                                                        !_RED!│!_R!
ECHO  !_RED!├──────────────────────────────────────────────────────────────────────────────┤!_R!
ECHO  !_RED!│!_R!                                                                              !_RED!│!_R!
ECHO  !_RED!│!_R!  !_RED!!_BOLD!!_ec_line:~0,74!!_R!  !_RED!│!_R!
ECHO  !_RED!│!_R!  !_DIM!!_em_line:~0,74!!_R!  !_RED!│!_R!
ECHO  !_RED!│!_R!                                                                              !_RED!│!_R!
ECHO  !_RED!╰──────────────────────────────────────────────────────────────────────────────╯!_R!
ECHO.
ECHO  !_DIM!  按任意键退出...!_R!
PAUSE > NUL
ENDLOCAL & EXIT /B 1
