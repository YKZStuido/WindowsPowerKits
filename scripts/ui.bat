@ECHO OFF
REM ============================================================================
REM  ui.bat — WindowsPowerKits 统一界面 / 彩色输出工具
REM ----------------------------------------------------------------------------
REM  本文件取代旧的 op.bat，集中实现：
REM    1. ANSI 颜色变量初始化（init 子命令，向调用方作用域注入变量）
REM    2. 彩色状态信息输出（info / ok / warn / err / step / title 等）
REM    3. 大幅状态横幅（done / fail）与分隔线（hr）
REM    4. 80 字符宽统一边框绘制（boxtop / boxmid / boxbot）
REM    5. 标准错误对话框（errbox）
REM
REM  调用约定：
REM    CALL "%ui%" <子命令> [参数1] [参数2]
REM
REM  设计要点：
REM    * "init" 子命令必须先于 SETLOCAL 处理，因为它需要把颜色变量
REM      泄漏到调用方作用域（CALL 后变量才能继承）。
REM    * 其余子命令均运行在 SETLOCAL 局部作用域中，自身的 SET 不会
REM      影响调用方，避免污染父批处理环境。
REM    * 所有边框字符使用 Unicode（需 UTF-8 / CHCP 65001）。
REM    * 颜色与边框依赖 ANSI 转义序列，需在 Windows Terminal 等
REM      支持 VT 序列的终端中渲染。
REM ============================================================================

CHCP 65001 >NUL 2>&1
SET "_ui_cmd=%~1"

REM ── init 必须在 SETLOCAL 之前分流：让 SET 命令影响父作用域 ──────────────
IF /I "%_ui_cmd%"=="init" GOTO :do_init

REM 其余子命令进入隔离作用域，避免污染调用方的环境变量
SETLOCAL ENABLEDELAYEDEXPANSION

REM ── 局部 ANSI 颜色初始化（与 init 等价，但只在本作用域有效）────────────
FOR /F %%a IN ('powershell -NoProfile -Command "[char]27"') DO SET "ESC=%%a"
SET "R=!ESC![0m"
SET "BOLD=!ESC![1m"     & SET "DIM=!ESC![2m"
SET "RED=!ESC![31m"     & SET "GREEN=!ESC![32m"  & SET "YELLOW=!ESC![33m"
SET "BLUE=!ESC![34m"    & SET "MAGENTA=!ESC![35m" & SET "CYAN=!ESC![36m"
SET "WHITE=!ESC![97m"
SET "BG_RED=!ESC![41m"  & SET "BG_GREEN=!ESC![42m"

REM 透传参数：MSG 为主消息文本，ARG2 为附加参数（错误对话框使用）
SET "MSG=%~2"
SET "ARG2=%~3"

REM ── 子命令分发表 ────────────────────────────────────────────────────────
REM    输出类型（兼容旧 op.bat 的全部子命令）
IF /I "%_ui_cmd%"=="info"   GOTO :do_info
IF /I "%_ui_cmd%"=="ok"     GOTO :do_ok
IF /I "%_ui_cmd%"=="warn"   GOTO :do_warn
IF /I "%_ui_cmd%"=="err"    GOTO :do_err
IF /I "%_ui_cmd%"=="title"  GOTO :do_title
IF /I "%_ui_cmd%"=="dim"    GOTO :do_dim
IF /I "%_ui_cmd%"=="step"   GOTO :do_step
IF /I "%_ui_cmd%"=="done"   GOTO :do_done
IF /I "%_ui_cmd%"=="fail"   GOTO :do_fail
IF /I "%_ui_cmd%"=="hr"     GOTO :do_hr

REM    边框 / 区段绘制
IF /I "%_ui_cmd%"=="boxtop" GOTO :do_boxtop
IF /I "%_ui_cmd%"=="boxmid" GOTO :do_boxmid
IF /I "%_ui_cmd%"=="boxbot" GOTO :do_boxbot

REM    错误对话框
IF /I "%_ui_cmd%"=="errbox" GOTO :do_errbox

GOTO :do_usage

REM ===========================================================================
REM  init —— 把颜色变量注入调用方作用域
REM  注意：本分支严格禁止 SETLOCAL，否则变量随 ENDLOCAL 一并丢弃。
REM ===========================================================================
:do_init
FOR /F %%a IN ('powershell -NoProfile -Command "[char]27"') DO SET "ESC=%%a"
SET "R=%ESC%[0m"
SET "BOLD=%ESC%[1m"
SET "DIM=%ESC%[2m"
SET "RED=%ESC%[31m"
SET "GREEN=%ESC%[32m"
SET "YELLOW=%ESC%[33m"
SET "BLUE=%ESC%[34m"
SET "MAGENTA=%ESC%[35m"
SET "CYAN=%ESC%[36m"
SET "WHITE=%ESC%[97m"
SET "BG_RED=%ESC%[41m"
SET "BG_GREEN=%ESC%[42m"
EXIT /B 0

REM ===========================================================================
REM  状态消息（单行输出）
REM ===========================================================================

REM info —— 通用提示信息：青色 [i] 图标 + 默认色文本
:do_info
ECHO  !CYAN![i]!R! %MSG%
GOTO :end

REM ok —— 成功提示：绿色 [+] 图标 + 高亮白色文本
:do_ok
ECHO  !GREEN![+]!R! !WHITE!%MSG%!R!
GOTO :end

REM warn —— 警告提示：黄色 [!] 图标 + 黄色文本
:do_warn
ECHO  !YELLOW![!]!R! !YELLOW!%MSG%!R!
GOTO :end

REM err —— 错误提示：红色 [x] 图标 + 红色加粗文本
:do_err
ECHO  !RED![x]!R! !RED!!BOLD!%MSG%!R!
GOTO :end

REM title —— 区段标题：上下空行 + 紫色加粗 ">> 标题 <<"
:do_title
ECHO.
ECHO  !BOLD!!MAGENTA!^>^> %MSG% ^<^<!R!
ECHO.
GOTO :end

REM dim —— 弱化辅助文本（灰色）
:do_dim
ECHO  !DIM!%MSG%!R!
GOTO :end

REM step —— 步骤指示：蓝色 [-] 图标 + 默认色文本
:do_step
ECHO  !BLUE![-]!R! %MSG%
GOTO :end

REM ===========================================================================
REM  状态横幅（多行输出，含上下空行）
REM ===========================================================================

REM done —— 成功横幅：绿底白字 " DONE " + 绿色加粗描述
:do_done
ECHO.
ECHO  !BG_GREEN!!WHITE! DONE !R! !GREEN!!BOLD!%MSG%!R!
ECHO.
GOTO :end

REM fail —— 失败横幅：红底白字 " FAIL " + 红色加粗描述
:do_fail
ECHO.
ECHO  !BG_RED!!WHITE! FAIL !R! !RED!!BOLD!%MSG%!R!
ECHO.
GOTO :end

REM hr —— 弱化分隔线（约 42 字符宽）
:do_hr
ECHO  !DIM!──────────────────────────────────────────!R!
GOTO :end

REM ===========================================================================
REM  边框绘制（统一 80 字符宽，青色）
REM
REM  界面规范要求菜单与对话框一律使用 80 列宽度。三种横向边框对应：
REM    boxtop —— 上边框 ╭──...──╮
REM    boxmid —— 中分隔 ├──...──┤
REM    boxbot —— 下边框 ╰──...──╯
REM
REM  共 78 个 ─ 字符 + 两侧角字符 = 80 列；与正文 │ 边框对齐。
REM ===========================================================================

:do_boxtop
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
GOTO :end

:do_boxmid
ECHO  !CYAN!├──────────────────────────────────────────────────────────────────────────────┤!R!
GOTO :end

:do_boxbot
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
GOTO :end

REM ===========================================================================
REM  errbox —— 标准红色错误对话框（自包含）
REM    用法： CALL "%ui%" errbox <错误代码> <错误描述>
REM
REM  对话框宽度固定 80 列。错误代码与描述会被截断到 74 列以保证对齐。
REM  采用空格右填充 + 切片技巧实现等宽渲染。
REM ===========================================================================
:do_errbox
SET "_code=%MSG%"
SET "_desc=%ARG2%"
REM 71 个空格用作右填充，保证 ":~0,74" 切片得到稳定 74 列宽度
SET "_pad=                                                                       "
SET "_code_line=!_code!!_pad!"
SET "_desc_line=!_desc!!_pad!"
ECHO.
ECHO  !RED!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !RED!│!R!  !BOLD!!WHITE!错误!R!                                                                        !RED!│!R!
ECHO  !RED!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !RED!│!R!                                                                              !RED!│!R!
ECHO  !RED!│!R!  !RED!!BOLD!!_code_line:~0,74!!R!  !RED!│!R!
ECHO  !RED!│!R!  !DIM!!_desc_line:~0,74!!R!  !RED!│!R!
ECHO  !RED!│!R!                                                                              !RED!│!R!
ECHO  !RED!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
GOTO :end

REM ===========================================================================
REM  usage —— 未识别子命令时打印用法说明
REM ===========================================================================
:do_usage
ECHO.
ECHO  !BOLD!ui.bat!R! ^| WindowsPowerKits 界面与彩色输出工具
ECHO.
ECHO  !CYAN!用法:!R!   call ui.bat ^<子命令^> [参数1] [参数2]
ECHO.
ECHO  !CYAN!信息输出:!R!
ECHO    !CYAN!info!R!     [i] 普通信息
ECHO    !GREEN!ok!R!       [+] 成功
ECHO    !YELLOW!warn!R!     [!] 警告
ECHO    !RED!err!R!      [x] 错误
ECHO    !MAGENTA!title!R!    ^>^> 区段标题 ^<^<
ECHO    !DIM!dim!R!      灰色辅助文本
ECHO    !BLUE!step!R!     [-] 步骤指示
ECHO    !GREEN!done!R!     DONE 成功横幅
ECHO    !RED!fail!R!     FAIL 失败横幅
ECHO    hr       灰色短分隔线
ECHO.
ECHO  !CYAN!边框 / 对话框 (80 列宽):!R!
ECHO    boxtop   ╭── 上边框 ──╮
ECHO    boxmid   ├── 中分隔 ──┤
ECHO    boxbot   ╰── 下边框 ──╯
ECHO    errbox   完整红色错误对话框 ^<code^> ^<desc^>
ECHO.
ECHO  !CYAN!颜色初始化:!R!
ECHO    init     在调用方作用域定义 ESC/R/BOLD/RED/GREEN/... 等颜色变量
ECHO.
GOTO :end

REM ── 统一退出 ────────────────────────────────────────────────────────────
:end
ENDLOCAL & EXIT /B 0
