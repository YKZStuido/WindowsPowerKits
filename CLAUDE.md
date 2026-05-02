# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Critical: File Encoding

**All `.bat` scripts MUST be saved with UTF-8 encoding and CRLF line endings.** Files with wrong encoding or LF-only line endings will fail to execute on Windows. This applies to every file in the repo.

## Running the Tool

```bat
WindowsPowerKits.bat
WindowsPowerKits.bat --bypass_system_version
WindowsPowerKits.bat --bypass_terimal_type
WindowsPowerKits.bat --bypass_system_version --bypass_terimal_type
```

There is no build step — the `.bat` files run directly. Testing requires a Windows machine with Windows Terminal and PowerShell available.

## Architecture

The project is a menu-driven BAT/PowerShell hybrid toolkit.

**Entry point:** `WindowsPowerKits.bat`
- Parses `--bypass_system_version` and `--bypass_terimal_type` flags
- Checks Windows build ≥ 10240 via registry (`HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion`)
- Checks `WT_SESSION` env var to verify Windows Terminal
- Verifies all dependency files exist before proceeding
- Routes menu selections to function modules via `CALL`

**Shared utilities (set at top of `WindowsPowerKits.bat`, inherited by modules):**
- `scripts/op.bat` — colored output; call as `CALL "%op%" <type> "message"`. Types: `info`, `ok`, `warn`, `err`, `title`, `dim`, `step`, `done`, `fail`, `hr`
- `scripts/wait.bat` — millisecond delay; call as `CALL "%wait%" <ms>`

**Function modules** live in `functions/`. Each module:
- Re-declares its own path to `%op%` and `%wait%` relative to `%~dp0` (since `%op%` from the parent scope isn't inherited after `CALL`)
- Re-initializes ANSI color variables because `ESC` and color vars are not reliably inherited
- Returns to the caller with `ENDLOCAL & EXIT /B 0`

## ANSI Color Convention

All scripts initialize ANSI escape codes at the top using:
```bat
FOR /F %%a IN ('powershell -NoProfile -Command "[char]27"') DO SET "ESC=%%a"
SET "R=!ESC![0m"
SET "BOLD=!ESC![1m"  & SET "DIM=!ESC![2m"
SET "RED=!ESC![31m"  & SET "GREEN=!ESC![32m"  & SET "YELLOW=!ESC![33m"
SET "BLUE=!ESC![34m" & SET "MAGENTA=!ESC![35m" & SET "CYAN=!ESC![36m"
SET "WHITE=!ESC![97m"
```

This requires `SETLOCAL ENABLEDELAYEDEXPANSION` and `!VAR!` syntax (not `%VAR%`) when using these color vars inside blocks.

## Adding a New Feature Module

1. Create `functions/<name>.bat` — copy the header pattern (ECHO OFF, CHCP 65001, SETLOCAL ENABLEDELAYEDEXPANSION, re-declare `%op%`/`%wait%` relative to `%~dp0`, re-init ANSI vars)
2. Add a menu entry in `WindowsPowerKits.bat` `:MAIN_MENU` with a new number
3. Add a `CALL "%<name>%"` branch in the `IF/ELSE IF` menu selection block
4. Declare the new module path variable near the top of `WindowsPowerKits.bat` (alongside `system`, `op`, `wait`)
5. Add a dependency existence check (`IF NOT EXIST "%<name>%" GOTO ERR_<NAME>`) with a matching `:ERR_<NAME>` label

## UI Layout Convention

Menus use 80-character-wide Unicode box-drawing borders rendered with ANSI color vars:
- Outer border: `╭ ╮ ╰ ╯ │ ├ ┤ ─` in `!CYAN!`
- Section headers inside use `┌ ┐ └ ┘ │` in `!CYAN!`
- Breadcrumb trail shown as `主页  ❯  模块  ❯  子页` in `!DIM!`
- User input prompt: `SET /P "ch=   ❯ "`
- Menu options: colored number (`!GREEN!1!R!`) followed by label; disabled/back options in `!DIM!`
