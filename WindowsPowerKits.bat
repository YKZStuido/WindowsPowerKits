@ECHO OFF & CHCP 65001 > NUL
SETLOCAL ENABLEDELAYEDEXPANSION

:INIT
COLOR 07 & CLS
CD %~dp0

SET "op=.\scripts\op.bat"
SET "wait=.\scripts\wait.bat"
SET "system=.\functions\system.bat"
SET "ver=0.1.1"

FOR /F %%a IN ('powershell -NoProfile -Command "[char]27"') DO SET "ESC=%%a"
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

TITLE WindowsPowerKits - 初始化

REM ── 系统版本检测 (需要 Windows 10 Build 10240+) ──
FOR /F "tokens=*" %%B IN ('powershell -NoProfile -Command "(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild"') DO SET "_build=%%B"
IF NOT DEFINED _build GOTO ERR_OS
SET /A "_buildnum=_build" 2>NUL
IF !_buildnum! LSS 10240 GOTO ERR_OS

REM ── 终端环境检测 (需要 Windows Terminal) ──
IF NOT DEFINED WT_SESSION GOTO ERR_WT

REM ── 依赖文件检测 ──
IF NOT EXIST "%op%"     GOTO ERR_OP
IF NOT EXIST "%wait%"   GOTO ERR_WAIT
IF NOT EXIST "%system%" GOTO ERR_SYS

CALL "%op%" ok  "系统检测通过  (Build !_buildnum!)"
CALL "%op%" ok  "终端检测通过  (Windows Terminal)"
CALL "%op%" ok  "依赖检查通过"
CALL "%op%" ok  "初始化完成"
CALL "%wait%" 150
GOTO MAIN_MENU

:ERR_OS
CALL :ERROR UNSUPPORTED_OS "此工具需要 Windows 10 (Build 10240) 或更高版本"
GOTO :EOF
:ERR_WT
CALL :ERROR UNSUPPORTED_TERMINAL "请在 Windows Terminal 中运行此工具"
GOTO :EOF
:ERR_OP
CALL :ERROR FILE_NOT_FOUND "找不到文件: %op%"
GOTO :EOF
:ERR_WAIT
CALL :ERROR FILE_NOT_FOUND "找不到文件: %wait%"
GOTO :EOF
:ERR_SYS
CALL :ERROR FILE_NOT_FOUND "找不到文件: %system%"
GOTO :EOF

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
SET /P "ch=   ❯ "

ECHO.

IF "!ch!" EQU "1" (
    CALL "%system%"
    GOTO MAIN_MENU
) ELSE IF "!ch!" EQU "9" (
    ECHO  !DIM!再见！!R!
    EXIT /B 0
) ELSE (
    CALL "%op%" warn "无效选项，请重新输入"
    CALL "%wait%" 500
    GOTO MAIN_MENU
)

:ERROR
COLOR 07 & CLS
TITLE WindowsPowerKits - 错误
SET "_ec=%~1"
SET "_em=%~2"
SET "_sp=                                                                       "
SET "_ec_line=!_ec!!_sp!"
SET "_em_line=!_em!!_sp!"
ECHO.
ECHO  !RED!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !RED!│!R!  !BOLD!!WHITE!错误!R!                                                                        !RED!│!R!
ECHO  !RED!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !RED!│!R!                                                                              !RED!│!R!
ECHO  !RED!│!R!  !RED!!BOLD!!_ec_line:~0,74!!R!  !RED!│!R!
ECHO  !RED!│!R!  !DIM!!_em_line:~0,74!!R!  !RED!│!R!
ECHO  !RED!│!R!                                                                              !RED!│!R!
ECHO  !RED!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
ECHO  !DIM!  按任意键退出...!R!
PAUSE > NUL & EXIT 1