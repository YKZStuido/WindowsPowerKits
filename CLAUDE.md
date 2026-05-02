# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在此仓库中工作时提供指引。

## 重要：文件编码

**所有 `.bat` 脚本必须使用 UTF-8 编码和 CRLF 换行保存。** 编码错误或仅使用 LF 换行的文件在 Windows 上将无法执行。此要求适用于仓库中的每一个文件。

## 运行工具

```bat
WindowsPowerKits.bat
WindowsPowerKits.bat --bypass_system_version
WindowsPowerKits.bat --bypass_terimal_type
WindowsPowerKits.bat --bypass_system_version --bypass_terimal_type
```

本项目无需构建步骤，`.bat` 文件可直接运行。测试需要在安装了 Windows Terminal 和 PowerShell 的 Windows 环境中进行。

## 架构

本项目是一个菜单驱动的 BAT/PowerShell 混合工具套件。

**入口文件：** `WindowsPowerKits.bat`
- 解析 `--bypass_system_version` 和 `--bypass_terimal_type` 启动参数
- 通过注册表（`HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion`）检测 Windows 构建版本是否 ≥ 10240
- 检查 `WT_SESSION` 环境变量以确认是否在 Windows Terminal 中运行
- 在启动前校验所有依赖文件是否存在
- 通过 `CALL` 将菜单选择路由到各功能模块

**共享工具（在 `WindowsPowerKits.bat` 顶部设置，供各模块使用）：**
- `scripts/op.bat` — 彩色输出工具；调用方式为 `CALL "%op%" <类型> "消息"`。类型包括：`info`、`ok`、`warn`、`err`、`title`、`dim`、`step`、`done`、`fail`、`hr`
- `scripts/wait.bat` — 毫秒级延时工具；调用方式为 `CALL "%wait%" <毫秒数>`

**功能模块**位于 `functions/` 目录下。每个模块需要：
- 使用 `%~dp0` 重新声明 `%op%` 和 `%wait%` 的路径（因为父作用域的 `%op%` 在 `CALL` 后不会被继承）
- 重新初始化 ANSI 颜色变量，因为 `ESC` 及颜色变量不能可靠继承
- 使用 `ENDLOCAL & EXIT /B 0` 返回调用方

## ANSI 颜色规范

所有脚本在顶部使用以下方式初始化 ANSI 转义码：
```bat
FOR /F %%a IN ('powershell -NoProfile -Command "[char]27"') DO SET "ESC=%%a"
SET "R=!ESC![0m"
SET "BOLD=!ESC![1m"  & SET "DIM=!ESC![2m"
SET "RED=!ESC![31m"  & SET "GREEN=!ESC![32m"  & SET "YELLOW=!ESC![33m"
SET "BLUE=!ESC![34m" & SET "MAGENTA=!ESC![35m" & SET "CYAN=!ESC![36m"
SET "WHITE=!ESC![97m"
```

在代码块内使用这些颜色变量时，必须启用 `SETLOCAL ENABLEDELAYEDEXPANSION` 并使用 `!VAR!` 语法（而非 `%VAR%`）。

## 添加新功能模块

1. 创建 `functions/<名称>.bat` — 复制标准文件头（ECHO OFF、CHCP 65001、SETLOCAL ENABLEDELAYEDEXPANSION、相对 `%~dp0` 重新声明 `%op%`/`%wait%`、重新初始化 ANSI 变量）
2. 在 `WindowsPowerKits.bat` 的 `:MAIN_MENU` 中添加新编号的菜单项
3. 在菜单选择的 `IF/ELSE IF` 块中添加对应的 `CALL "%<名称>%"` 分支
4. 在 `WindowsPowerKits.bat` 顶部（紧靠 `system`、`op`、`wait` 附近）声明新模块的路径变量
5. 添加依赖文件存在性检查（`IF NOT EXIST "%<名称>%" GOTO ERR_<名称>`）及对应的 `:ERR_<名称>` 标签

## 界面布局规范

菜单使用 80 字符宽的 Unicode 制表符边框，并通过 ANSI 颜色变量渲染：
- 外框：`╭ ╮ ╰ ╯ │ ├ ┤ ─`，使用 `!CYAN!` 颜色
- 内部章节标题：`┌ ┐ └ ┘ │`，使用 `!CYAN!` 颜色
- 面包屑导航：`主页  ❯  模块  ❯  子页`，使用 `!DIM!` 颜色
- 用户输入提示符：`SET /P "ch=   ❯ "`
- 菜单选项：带颜色的编号（`!GREEN!1!R!`）后接标签；禁用项/返回项使用 `!DIM!`
