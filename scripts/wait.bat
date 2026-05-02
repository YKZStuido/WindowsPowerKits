@echo off
:: wait.bat <milliseconds>
:: Silently waits for the specified number of milliseconds.
:: Default: 1000ms if no argument is given.
setlocal
set "_ms=%~1"
if "%_ms%"=="" set "_ms=1000"
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -Command "Start-Sleep -Milliseconds %_ms%"
endlocal
