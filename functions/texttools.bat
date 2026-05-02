@ECHO OFF & CHCP 65001 > NUL
SETLOCAL ENABLEDELAYEDEXPANSION

REM ============================================================================
REM  functions\texttools.bat —— 文本工具子模块
REM ----------------------------------------------------------------------------
REM  当前提供的功能：
REM    1) 文本统计   —— 字符数、非空字符数、词数、句数
REM    2) Base64     —— UTF-8 编码 / 解码
REM    3) URL        —— 百分号编码 / 解码
REM    4) AES        —— AES-256-CBC 加密 / 解密（PBKDF2 密钥派生）
REM    5) 哈希计算   —— MD5 / SHA1 / SHA256 / SHA512
REM    6) 查找替换   —— 普通字符串 / 正则表达式
REM    7) 废话生成   —— 随机官方废话生成器
REM    8) UUID 生成  —— 批量生成随机 GUID
REM
REM  设计要点：
REM    * 用户输入通过环境变量 _ps_xxx 传入 PowerShell（$env:_ps_xxx），
REM      避免特殊字符注入命令行。
REM    * FOR /F 内的 PowerShell 字符串中，'' 代表一个单引号（转义约定）。
REM    * 所有 PowerShell 调用使用 -NoProfile 跳过用户配置。
REM ============================================================================

REM ── 共享工具脚本 ────────────────────────────────────────────────────────
SET "ui=%~dp0..\scripts\ui.bat"
SET "wait=%~dp0..\scripts\wait.bat"

REM ── ANSI 颜色变量初始化（局部作用域） ───────────────────────────────────
CALL "%ui%" init

REM ============================================================================
REM  MENU —— 文本工具子菜单
REM ============================================================================
:MENU
COLOR 07 & CLS
TITLE WindowsPowerKits - 文本工具

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!文本工具!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具!R!                                                           !CYAN!│!R!
ECHO  !CYAN!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!1!R!  文本统计        字符数、词数、句数统计                                   !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!2!R!  Base64 编解码   UTF-8 编码 / 解码                                      !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!3!R!  URL 编解码      百分号编码 / 解码                                      !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!4!R!  AES 加解密      AES-256-CBC 加密 / 解密                               !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!5!R!  哈希计算        MD5 / SHA1 / SHA256 / SHA512                         !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!6!R!  查找替换        字符串或正则查找替换                                   !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!7!R!  废话生成        随机生成官方废话（图一乐）                             !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!8!R!  UUID 生成       批量生成随机 UUID / GUID                              !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !DIM!9  返回!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
SET "ch="
SET /P "ch=   ❯ "
ECHO.

IF "!ch!"=="1" GOTO STATS
IF "!ch!"=="2" GOTO BASE64
IF "!ch!"=="3" GOTO URL
IF "!ch!"=="4" GOTO AES
IF "!ch!"=="5" GOTO HASH
IF "!ch!"=="6" GOTO FINDREPLACE
IF "!ch!"=="7" GOTO NONSENSE
IF "!ch!"=="8" GOTO UUID
IF "!ch!"=="9" (
    CALL "%ui%" dim "返回主菜单..."
    CALL "%wait%" 300
    ENDLOCAL & EXIT /B 0
)
CALL "%ui%" warn "无效选项，请重新输入"
CALL "%wait%" 400
GOTO MENU

REM ============================================================================
REM  STATS —— 文本统计
REM ============================================================================
:STATS
CLS
TITLE WindowsPowerKits - 文本统计

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!文本统计!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  文本统计!R!                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
ECHO  !DIM!请输入要统计的文本（单行）：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.

IF NOT DEFINED _input (
    CALL "%ui%" warn "输入为空"
    CALL "%wait%" 500
    GOTO STATS
)

SET "_ps_text=!_input!"
SET "_chars=" & SET "_charns=" & SET "_words=" & SET "_sents="

FOR /F "tokens=1,2,3,4 delims=|" %%a IN ('powershell -NoProfile -Command "$t=$env:_ps_text; $c=$t.Length; $cns=($t -replace ''\s'','''' ).Length; $w=if($t.Trim()){($t.Trim() -split ''\s+'').Count}else{0}; $s=($t -split ''[.!?！。？]+''^|Where-Object{$_.Trim()}).Count; [string]$c+[char]124+[string]$cns+[char]124+[string]$w+[char]124+[string]$s"') DO (
    SET "_chars=%%a"
    SET "_charns=%%b"
    SET "_words=%%c"
    SET "_sents=%%d"
)

IF NOT DEFINED _chars SET "_chars=0"
IF NOT DEFINED _charns SET "_charns=0"
IF NOT DEFINED _words SET "_words=0"
IF NOT DEFINED _sents SET "_sents=0"

ECHO  !CYAN!┌─ !BOLD!统计结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !CYAN![i]!R!  字符总数      !DIM!:!R!  !WHITE!!BOLD!!_chars!!R!
ECHO   !CYAN![i]!R!  非空字符数    !DIM!:!R!  !WHITE!!BOLD!!_charns!!R!
ECHO   !CYAN![i]!R!  词数          !DIM!:!R!  !WHITE!!BOLD!!_words!!R!
ECHO   !CYAN![i]!R!  句数          !DIM!:!R!  !WHITE!!BOLD!!_sents!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO MENU

REM ============================================================================
REM  BASE64 —— Base64 编解码子菜单
REM ============================================================================
:BASE64
CLS
TITLE WindowsPowerKits - Base64 编解码

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!Base64 编解码!R!                                                               !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  Base64 编解码!R!                                         !CYAN!│!R!
ECHO  !CYAN!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!1!R!  编码   将文本转换为 Base64 字符串                                        !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!2!R!  解码   将 Base64 字符串还原为文本                                       !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !DIM!9  返回!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
SET "ch="
SET /P "ch=   ❯ "
ECHO.

IF "!ch!"=="1" GOTO BASE64_ENC
IF "!ch!"=="2" GOTO BASE64_DEC
IF "!ch!"=="9" GOTO MENU
CALL "%ui%" warn "无效选项"
CALL "%wait%" 400
GOTO BASE64

:BASE64_ENC
ECHO  !DIM!请输入要编码的文本：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO BASE64_ENC)
SET "_ps_text=!_input!"
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($env:_ps_text))"') DO SET "_result=%%A"
ECHO  !CYAN!┌─ !BOLD!编码结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !GREEN!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO BASE64

:BASE64_DEC
ECHO  !DIM!请输入要解码的 Base64 字符串：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO BASE64_DEC)
SET "_ps_text=!_input!"
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "try{[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:_ps_text))}catch{''[ERROR] 无效的 Base64 字符串''}"') DO SET "_result=%%A"
ECHO  !CYAN!┌─ !BOLD!解码结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !WHITE!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO BASE64

REM ============================================================================
REM  URL —— URL 编解码子菜单
REM ============================================================================
:URL
CLS
TITLE WindowsPowerKits - URL 编解码

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!URL 编解码!R!                                                                  !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  URL 编解码!R!                                           !CYAN!│!R!
ECHO  !CYAN!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!1!R!  编码   将文本转换为 URL 百分号编码                                      !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!2!R!  解码   将百分号编码还原为文本                                           !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !DIM!9  返回!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
SET "ch="
SET /P "ch=   ❯ "
ECHO.

IF "!ch!"=="1" GOTO URL_ENC
IF "!ch!"=="2" GOTO URL_DEC
IF "!ch!"=="9" GOTO MENU
CALL "%ui%" warn "无效选项"
CALL "%wait%" 400
GOTO URL

:URL_ENC
ECHO  !DIM!请输入要编码的文本：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO URL_ENC)
SET "_ps_text=!_input!"
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "[Uri]::EscapeDataString($env:_ps_text)"') DO SET "_result=%%A"
ECHO  !CYAN!┌─ !BOLD!编码结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !GREEN!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO URL

:URL_DEC
ECHO  !DIM!请输入要解码的 URL 编码字符串：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO URL_DEC)
SET "_ps_text=!_input!"
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "try{[Uri]::UnescapeDataString($env:_ps_text)}catch{''[ERROR] 解码失败''}"') DO SET "_result=%%A"
ECHO  !CYAN!┌─ !BOLD!解码结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !WHITE!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO URL

REM ============================================================================
REM  AES —— AES-256-CBC 加解密子菜单
REM ============================================================================
:AES
CLS
TITLE WindowsPowerKits - AES 加解密

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!AES 加解密!R!                                                                  !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  AES 加解密!R!                                           !CYAN!│!R!
ECHO  !CYAN!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!1!R!  加密   使用密码加密文本（输出 Base64）                                  !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!2!R!  解密   使用密码解密 Base64 密文                                        !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !DIM!算法：AES-256-CBC  密钥派生：PBKDF2 (10000 次)!R!                            !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !DIM!9  返回!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
SET "ch="
SET /P "ch=   ❯ "
ECHO.

IF "!ch!"=="1" GOTO AES_ENC
IF "!ch!"=="2" GOTO AES_DEC
IF "!ch!"=="9" GOTO MENU
CALL "%ui%" warn "无效选项"
CALL "%wait%" 400
GOTO AES

:AES_ENC
ECHO  !DIM!请输入要加密的文本：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO AES_ENC)
ECHO  !DIM!请输入加密密码：!R!
SET "_pass="
SET /P "_pass=   ❯ "
ECHO.
IF NOT DEFINED _pass (CALL "%ui%" warn "密码不能为空" & CALL "%wait%" 400 & GOTO AES_ENC)

SET "_ps_text=!_input!"
SET "_ps_pass=!_pass!"
CALL "%ui%" step "正在加密..."
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "$k=(New-Object Security.Cryptography.Rfc2898DeriveBytes($env:_ps_pass,[Text.Encoding]::UTF8.GetBytes(''WPKSalt01''),10000)).GetBytes(32); $iv=New-Object byte[] 16; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($iv); $a=[Security.Cryptography.Aes]::Create(); $a.Key=$k; $a.IV=$iv; $enc=$a.CreateEncryptor().TransformFinalBlock([Text.Encoding]::UTF8.GetBytes($env:_ps_text),0,$env:_ps_text.Length); [Convert]::ToBase64String($iv+$enc)"') DO SET "_result=%%A"

IF NOT DEFINED _result (
    CALL "%ui%" fail "加密失败"
    CALL "%wait%" 600
    GOTO AES
)
ECHO  !CYAN!┌─ !BOLD!加密结果 (Base64)!R!!CYAN! ──────────────────────────────────────────────────────┐!R!
ECHO   !GREEN!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO AES

:AES_DEC
ECHO  !DIM!请输入要解密的 Base64 密文：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO AES_DEC)
ECHO  !DIM!请输入解密密码：!R!
SET "_pass="
SET /P "_pass=   ❯ "
ECHO.
IF NOT DEFINED _pass (CALL "%ui%" warn "密码不能为空" & CALL "%wait%" 400 & GOTO AES_DEC)

SET "_ps_text=!_input!"
SET "_ps_pass=!_pass!"
CALL "%ui%" step "正在解密..."
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "try{$k=(New-Object Security.Cryptography.Rfc2898DeriveBytes($env:_ps_pass,[Text.Encoding]::UTF8.GetBytes(''WPKSalt01''),10000)).GetBytes(32); $b=[Convert]::FromBase64String($env:_ps_text); $iv=$b[0..15]; $enc=$b[16..($b.Length-1)]; $a=[Security.Cryptography.Aes]::Create(); $a.Key=$k; $a.IV=$iv; [Text.Encoding]::UTF8.GetString($a.CreateDecryptor().TransformFinalBlock($enc,0,$enc.Length))}catch{''[ERROR] 解密失败，请检查密码或密文''}"') DO SET "_result=%%A"

ECHO  !CYAN!┌─ !BOLD!解密结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !WHITE!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO AES

REM ============================================================================
REM  HASH —— 哈希计算
REM ============================================================================
:HASH
CLS
TITLE WindowsPowerKits - 哈希计算

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!哈希计算!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  哈希计算!R!                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
ECHO  !DIM!请输入要计算哈希的文本（UTF-8 编码）：!R!
SET "_input="
SET /P "_input=   ❯ "
ECHO.
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO HASH)

SET "_ps_text=!_input!"
CALL "%ui%" step "正在计算..."
CALL "%wait%" 200

SET "_md5=" & SET "_sha1=" & SET "_sha256=" & SET "_sha512="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "$b=[Text.Encoding]::UTF8.GetBytes($env:_ps_text); [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash($b)).Replace(''-'','''').ToLower()"') DO SET "_md5=%%A"
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "$b=[Text.Encoding]::UTF8.GetBytes($env:_ps_text); [BitConverter]::ToString([Security.Cryptography.SHA1]::Create().ComputeHash($b)).Replace(''-'','''').ToLower()"') DO SET "_sha1=%%A"
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "$b=[Text.Encoding]::UTF8.GetBytes($env:_ps_text); [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($b)).Replace(''-'','''').ToLower()"') DO SET "_sha256=%%A"
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "$b=[Text.Encoding]::UTF8.GetBytes($env:_ps_text); [BitConverter]::ToString([Security.Cryptography.SHA512]::Create().ComputeHash($b)).Replace(''-'','''').ToLower()"') DO SET "_sha512=%%A"

IF NOT DEFINED _md5    SET "_md5=计算失败"
IF NOT DEFINED _sha1   SET "_sha1=计算失败"
IF NOT DEFINED _sha256 SET "_sha256=计算失败"
IF NOT DEFINED _sha512 SET "_sha512=计算失败"

ECHO  !CYAN!┌─ !BOLD!哈希结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !CYAN![i]!R!  !DIM!MD5   !R! !DIM!:!R!  !WHITE!!_md5!!R!
ECHO   !CYAN![i]!R!  !DIM!SHA1  !R! !DIM!:!R!  !WHITE!!_sha1!!R!
ECHO   !CYAN![i]!R!  SHA256 !DIM!:!R!  !GREEN!!_sha256!!R!
ECHO   !CYAN![i]!R!  SHA512 !DIM!:!R!  !YELLOW!!_sha512!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO MENU

REM ============================================================================
REM  FINDREPLACE —— 查找替换子菜单
REM ============================================================================
:FINDREPLACE
CLS
TITLE WindowsPowerKits - 查找替换

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!查找替换!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  查找替换!R!                                              !CYAN!│!R!
ECHO  !CYAN!├──────────────────────────────────────────────────────────────────────────────┤!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!1!R!  普通替换   按字面字符串查找替换                                         !CYAN!│!R!
ECHO  !CYAN!│!R!   !GREEN!2!R!  正则替换   使用正则表达式查找替换                                       !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!│!R!   !DIM!9  返回!R!                                                                    !CYAN!│!R!
ECHO  !CYAN!│!R!                                                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
SET "ch="
SET /P "ch=   ❯ "
ECHO.

IF "!ch!"=="1" GOTO FR_PLAIN
IF "!ch!"=="2" GOTO FR_REGEX
IF "!ch!"=="9" GOTO MENU
CALL "%ui%" warn "无效选项"
CALL "%wait%" 400
GOTO FINDREPLACE

:FR_PLAIN
ECHO  !DIM!源文本：!R!
SET "_input="
SET /P "_input=   ❯ "
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO FR_PLAIN)
ECHO  !DIM!查找（字符串）：!R!
SET "_find="
SET /P "_find=   ❯ "
ECHO  !DIM!替换为：!R!
SET "_repl="
SET /P "_repl=   ❯ "
ECHO.
SET "_ps_text=!_input!"
SET "_ps_find=!_find!"
SET "_ps_repl=!_repl!"
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "$env:_ps_text -replace [regex]::Escape($env:_ps_find),$env:_ps_repl"') DO SET "_result=%%A"
IF NOT DEFINED _result SET "_result=(替换后为空字符串)"
ECHO  !CYAN!┌─ !BOLD!替换结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !GREEN!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO FINDREPLACE

:FR_REGEX
ECHO  !DIM!源文本：!R!
SET "_input="
SET /P "_input=   ❯ "
IF NOT DEFINED _input (CALL "%ui%" warn "输入为空" & CALL "%wait%" 400 & GOTO FR_REGEX)
ECHO  !DIM!查找（正则）：!R!
SET "_find="
SET /P "_find=   ❯ "
ECHO  !DIM!替换为（支持 $1 $2 反向引用）：!R!
SET "_repl="
SET /P "_repl=   ❯ "
ECHO.
SET "_ps_text=!_input!"
SET "_ps_find=!_find!"
SET "_ps_repl=!_repl!"
SET "_result="
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "try{$env:_ps_text -replace $env:_ps_find,$env:_ps_repl}catch{''[ERROR] 正则表达式无效: ''+$_.Exception.Message}"') DO SET "_result=%%A"
IF NOT DEFINED _result SET "_result=(替换后为空字符串)"
ECHO  !CYAN!┌─ !BOLD!替换结果!R!!CYAN! ───────────────────────────────────────────────────────────────────┐!R!
ECHO   !GREEN!!_result!!R!
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按任意键返回...!R!
PAUSE > NUL
GOTO FINDREPLACE

REM ============================================================================
REM  NONSENSE —— 废话生成器
REM ============================================================================
:NONSENSE
CLS
TITLE WindowsPowerKits - 废话生成器

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!废话生成器!R!  !DIM!（图一乐）!R!                                                       !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  废话生成!R!                                              !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
CALL "%ui%" step "正在生成官方废话..."
CALL "%wait%" 600
ECHO.

ECHO  !CYAN!┌─ !BOLD!本次生成的官方废话!R!!CYAN! ──────────────────────────────────────────────────────┐!R!
ECHO.
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "$s=@(''我们'',''各部门'',''相关单位'',''全体同志'',''领导干部'',''广大职工''); $v=@(''充分认识到'',''深刻把握'',''切实强化'',''积极稳妥地推进'',''高度重视'',''务必落实好''); $a=@(''高质量'',''系统化'',''精准化'',''全面性'',''创新型'',''数字化''); $n=@(''发展'',''建设'',''改革'',''创新'',''治理'',''服务'',''保障'',''管理''); $e=@(''确保落实到位。'',''取得显著成效。'',''推动工作再上新台阶。'',''务求实效，真抓实干。'',''为高质量发展贡献力量。'',''真正做实做细做好。''); $i=0; 1..5 ^| ForEach-Object{$i++; [string]$i+''. ''+($s^|Get-Random)+''要''+($v^|Get-Random)+($a^|Get-Random)+($n^|Get-Random)+''+，''+($e^|Get-Random)}"') DO (
    ECHO   !YELLOW!%%A!R!
    ECHO.
)
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按 R 重新生成，按其他键返回...!R!
SET "ch="
SET /P "ch=   ❯ "
ECHO.
IF /I "!ch!"=="R" GOTO NONSENSE
GOTO MENU

REM ============================================================================
REM  UUID —— UUID 生成器
REM ============================================================================
:UUID
CLS
TITLE WindowsPowerKits - UUID 生成

ECHO.
ECHO  !CYAN!╭──────────────────────────────────────────────────────────────────────────────╮!R!
ECHO  !CYAN!│!R!  !BOLD!!WHITE!UUID 生成器!R!                                                                 !CYAN!│!R!
ECHO  !CYAN!│!R!  !DIM!主页  ❯  文本工具  ❯  UUID 生成!R!                                             !CYAN!│!R!
ECHO  !CYAN!╰──────────────────────────────────────────────────────────────────────────────╯!R!
ECHO.
CALL "%ui%" step "正在生成..."
CALL "%wait%" 300
ECHO.

ECHO  !CYAN!┌─ !BOLD!UUID (v4 随机)!R!!CYAN! ────────────────────────────────────────────────────────────┐!R!
SET "_idx=0"
FOR /F "delims=" %%A IN ('powershell -NoProfile -Command "1..8 ^| ForEach-Object{[Guid]::NewGuid().ToString()}"') DO (
    SET /A "_idx+=1"
    ECHO   !CYAN![!_idx!]!R!  !WHITE!%%A!R!
)
ECHO  !CYAN!└──────────────────────────────────────────────────────────────────────────────┘!R!
ECHO.
ECHO  !DIM!  按 R 重新生成，按其他键返回...!R!
SET "ch="
SET /P "ch=   ❯ "
ECHO.
IF /I "!ch!"=="R" GOTO UUID
GOTO MENU
