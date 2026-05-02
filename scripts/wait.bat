@ECHO OFF
REM ============================================================================
REM  wait.bat —— 毫秒级精确延时工具
REM ----------------------------------------------------------------------------
REM  用法:
REM    CALL "%wait%" <毫秒数>
REM
REM  说明:
REM    * 委托 PowerShell 的 Start-Sleep -Milliseconds 实现亚秒级精度，
REM      规避 cmd 内置 TIMEOUT/ping 仅能秒级延时的限制。
REM    * 未传入参数时默认延时 1000 ms。
REM    * 使用 -NoProfile / -NonInteractive 跳过用户配置和交互提示，
REM      最小化 PowerShell 启动开销。
REM ============================================================================

SETLOCAL
SET "_ms=%~1"
IF "%_ms%"=="" SET "_ms=1000"
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -Command "Start-Sleep -Milliseconds %_ms%"
ENDLOCAL & EXIT /B 0
