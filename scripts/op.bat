@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CHCP 65001 >NUL 2>&1

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
SET "BG_BLUE=!ESC![44m"

SET "TYPE=%~1"
SET "MSG=%~2"

IF /I "%TYPE%"=="info"  GOTO do_info
IF /I "%TYPE%"=="ok"    GOTO do_ok
IF /I "%TYPE%"=="warn"  GOTO do_warn
IF /I "%TYPE%"=="err"   GOTO do_err
IF /I "%TYPE%"=="title" GOTO do_title
IF /I "%TYPE%"=="dim"   GOTO do_dim
IF /I "%TYPE%"=="step"  GOTO do_step
IF /I "%TYPE%"=="done"  GOTO do_done
IF /I "%TYPE%"=="fail"  GOTO do_fail
IF /I "%TYPE%"=="hr"    GOTO do_hr
GOTO do_usage

:do_info
ECHO  !CYAN![i]!R! %MSG%
GOTO end

:do_ok
ECHO  !GREEN![+]!R! !WHITE!%MSG%!R!
GOTO end

:do_warn
ECHO  !YELLOW![!]!R! !YELLOW!%MSG%!R!
GOTO end

:do_err
ECHO  !RED![x]!R! !RED!!BOLD!%MSG%!R!
GOTO end

:do_title
ECHO.
ECHO  !BOLD!!MAGENTA!^>^> %MSG% ^<^<!R!
ECHO.
GOTO end

:do_dim
ECHO  !DIM!%MSG%!R!
GOTO end

:do_step
ECHO  !BLUE![-]!R! %MSG%
GOTO end

:do_done
ECHO.
ECHO  !BG_GREEN!!WHITE! DONE !R! !GREEN!!BOLD!%MSG%!R!
ECHO.
GOTO end

:do_fail
ECHO.
ECHO  !BG_RED!!WHITE! FAIL !R! !RED!!BOLD!%MSG%!R!
ECHO.
GOTO end

:do_hr
ECHO  !DIM!──────────────────────────────────────────!R!
GOTO end

:do_usage
ECHO.
ECHO  !BOLD!op.bat!R! ^| 彩色输出工具
ECHO.
ECHO  !CYAN!用法:!R!   call op.bat ^<类型^> [消息]
ECHO.
ECHO  !CYAN!类型:!R!
ECHO    !CYAN!info!R!    [i] 普通信息
ECHO    !GREEN!ok!R!      [+] 成功
ECHO    !YELLOW!warn!R!    [!] 警告
ECHO    !RED!err!R!     [x] 错误
ECHO    !MAGENTA!title!R!  ^>^> 标题 ^<^<
ECHO    !DIM!dim!R!     灰色文本
ECHO    !BLUE!step!R!   [-] 步骤
ECHO    !GREEN!done!R!   DONE 横幅
ECHO    !RED!fail!R!   FAIL 横幅
ECHO    hr      分隔线
ECHO.
GOTO end

:end
ENDLOCAL
