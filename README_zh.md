# Brain System

Shebang：`#!/bin/sh` | 纯 POSIX，无 Bash 扩展。

> Awk = 数据库，管道 = 总线，纯文本 = 真理

## 概述

Brain 是一个完全基于 POSIX Shell 和 Awk 构建的个人知识管理系统。它不依赖数据库、无需编译步骤、没有外部运行时依赖。其架构设计旨在确保长期稳定性，保证在任何兼容 POSIX 的环境中运行数十年。

## 目录结构

```text
brain/
├── bin/               # 可执行脚本与核心逻辑
├── atoms/             # 事实来源（Markdown 笔记）
├── inbox/             # 待处理队列
├── cache/             # 自动生成的临时索引
│   ├── meta.tsv       # 笔记元数据（UID、标题、日期、类型、状态、路径）
│   ├── links.tsv      # 笔记关系的有向图
│   └── tags.tsv       # 标签的倒排索引
└── conflicts.report   # 格式错误或冲突记录的日志
```

## 安装

```sh
git clone <repository-url> ~/brain
cd ~/brain
chmod +x bin/*
echo 'export PATH="$HOME/brain/bin:$PATH"' >> ~/.profile
source ~/.profile
```

### 命令参考 (Command Reference)

| 命令 | 功能说明 |
| :--- | :--- |
| **`brain`** | 启动基于 FZF 的交互式 TUI 界面。<br>*(快捷键: `Enter`:编辑, `Ctrl-D`:归档, `Ctrl-N`:快速新建, `Ctrl-V`:剪藏, `Alt-I`:提拔最新, `Ctrl-Y`:复制链接, `Ctrl-A`:多选拼合, `Ctrl-P`:大纲拼合)* |
| **`brain-add`** | 使用当前 FZF 搜索框中的查询字符串，快速创建新笔记。 |
| **`brain-new`** | 生成空白笔记模板，并直接在 `$EDITOR` 中打开。 |
| **`brain-clip`** | 读取系统剪贴板内容，并将其保存为 `inbox/` 目录下的新笔记。 |
| **`brain-archive`** | 将笔记状态更新为 `archived`（归档），使其从默认查询列表中隐藏。 |
| **`brain-promote`** | 将笔记从 `inbox/` 安全迁移至 `atoms/`，内置严格的 UID 冲突检测机制。 |
| **`brain-promote-latest`** | 自动提拔 `inbox/` 中最近修改的最新笔记。 |
| **`brain-context <uid>`** | 显示特定笔记的入链与出链，并包含目标笔记的实时状态（`[OK]` / `[ARCHIVED]` / `[DEAD]`）。 |
| **`brain-search <kw>`** | 使用 AND 逻辑，在 `atoms/` 目录中执行全文深度搜索。 |
| **`brain-tag <tag>`** | 检索所有关联了指定标签的笔记。 |
| **`brain-list`** | 输出所有活跃笔记的纯文本列表（包含 UID 和标题）。 |
| **`brain-list-raw`** | 输出原始、已排序的 TSV 数据（已过滤 `archived`），专供 FZF 消费（内部/核心组件）。 |
| **`brain-index`** | 从 `atoms/` 目录原子化地重建所有缓存索引（`meta`, `links`, `tags`）。 |
| **`brain-copy-link`** | 将标准化的链接模板（如 `+link: <UID> updates`）静默复制到系统剪贴板。 |
| **`brain-compile-selected`** | 将 FZF 中手动多选的多篇笔记，拼接并渲染为单一、纯净的阅读视图（`Ctrl-A`）。 |
| **`brain-compile-outlinks`** | 严格按照 `+link` 的书写顺序，将当前笔记的所有出链笔记拼接并渲染为长文视图（`Ctrl-P`）。 |

## 笔记规范

笔记必须遵循以下 Frontmatter 结构：

```markdown
---
uid: U-20260615T012230042
title: Your title
date: 2026-06-15 01:22:30
type: note
status: live
+tag: inbox
+link: U-xxxxxxxxxxx updates
---

正文内容。
```

**约束条件：**
- `uid`：必须与文件名完全匹配（不含 `.md` 扩展名）。
- `status`：必须为 `live` 或 `archived`。
- 格式错误的文件将被索引器跳过，并记录在 `conflicts.report` 中。

## 设计决策

### 为什么选择 POSIX `sh`
Bash 特有的功能会引入可移植性风险。系统严格遵守 POSIX 标准，以确保与 `dash`、`busybox` 和传统 Unix 环境的兼容性。
- 不使用 `$RANDOM`：使用进程 ID (`$$`) 作为伪随机生成的种子。
- 不使用 `$'\t'`：通过 `printf '\t'` 生成制表符。
- 不使用 `pipefail`：错误处理依赖于 `set -e`。
- 不使用未加引号的 `echo`：所有变量输出均使用 `printf '%s\n'` 以防止反斜杠解析。

### 安全态势
该架构在设计上缓解了常见的 Shell 脚本漏洞：
- 避免对用户输入进行动态求值，从而防止命令注入。
- 使用 `printf` 替代 Here-document，避免注入风险。
- 通过严格的变量处理消除引号和转义陷阱。
- 在提拔过程中通过显式的冲突检查阻止 UID 覆盖。
- 通过对临时文件使用原子化的 `mv` 操作防止索引死锁。

## 不可妥协的约束

以下行为是有意为之的设计选择，不会被更改：
1. **搜索逻辑**：`brain-search` 使用 AND 逻辑，而非 OR。
2. **数据清理**：标题中的制表符会自动转换为空格。
3. **接口**：系统严格基于 CLI/TUI。没有计划或支持 GUI 或移动应用程序。
4. **文件可变性**：索引器读取源文件但从不修改它们。状态更改（如归档）由专用的、可审计的脚本处理。

## 运行

```sh
brain
```

Awk。Shell。文件系统。
这就是所需的全部。
