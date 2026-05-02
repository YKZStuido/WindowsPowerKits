# WindowsPowerKits

WindowsPowerKits 是一款综合性的 Windows 系统工具套件，适用于 Windows 10/11。

## 系统要求

| 要求 | 说明 |
|------|------|
| 操作系统 | Windows 10 Build 10240 及以上 |
| 终端 | [Windows Terminal](https://aka.ms/terminal) |

## 快速开始

在 Windows Terminal 中运行：

```bat
WindowsPowerKits.bat
```

## 启动参数

| 参数 | 说明 |
|------|------|
| `--bypass_system_version` | 绕过系统版本检测（低于 Build 10240 时输出警告后继续运行） |
| `--bypass_terimal_type` | 绕过终端类型检测（非 Windows Terminal 时输出警告后继续运行） |

> **注意**：绕过参数仅用于兼容性测试或特殊场景，正常使用建议满足系统要求。

**示例：**

```bat
REM 绕过系统版本检测
WindowsPowerKits.bat --bypass_system_version

REM 绕过终端类型检测
WindowsPowerKits.bat --bypass_terimal_type

REM 同时绕过两项检测
WindowsPowerKits.bat --bypass_system_version --bypass_terimal_type
```

## 功能列表

| 编号 | 功能 | 说明 |
|------|------|------|
| 1 | 系统工具 | 系统信息、维护相关操作 |
| 9 | 退出 | 退出程序 |

## 项目结构

```
WindowsPowerKits/
├── WindowsPowerKits.bat    主入口文件
├── functions/
│   └── system.bat          系统工具功能模块
├── scripts/
│   ├── op.bat              格式化输出工具脚本
│   └── wait.bat            延时工具脚本
└── README.md               说明文档
```

## 技术说明

- 脚本使用 BAT 与 PowerShell 混合实现，执行效率高
- 支持 ANSI 转义码彩色输出（需要 Windows Terminal 或兼容终端）
- 编码：UTF-8 (CHCP 65001)
