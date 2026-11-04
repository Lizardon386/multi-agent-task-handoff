> **自动生成，源文件在 handoff/README.md；不要手改。** 最近同步：2026-11-04

# multi-agent-task-handoff（任务交接）· 使用说明

> 换会话、换 agent、隔天回来，任务还能接着干：把状态写进项目目录的 `handoff/`，下一个 agent 读卡即可接手。
> 一个 skill、一个目录、一份交接卡；不装常驻服务，不绑定宿主，不复制聊天历史。
> 本文件是 `handoff/README.md`，任务/产品 README 的唯一源；GitHub 首页由它生成。
> 最近更新：2026-11-03

## 文档

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](/handoff/README.md) | 使用者 | 这是什么、怎么跑、限制 |
| [DESIGN.md](/handoff/DESIGN.md) | 评审 / 开发 | 目标、架构、流程、决策 |
| [CONTEXT.md](/handoff/CONTEXT.md) | 接手 agent | 完整文档表、当前状态、下一步、坑 |

完整文档表（含 PROMPT、SKILL、HELP、压卡备份）见 [CONTEXT.md](/handoff/CONTEXT.md)。

## 1. 这是什么

会话是易失的。换一个会话、换一个 agent、隔一天回来，上一个会话想过什么、试过什么、卡在哪，全都没了。通常只能翻聊天记录，或者靠人复述。

这个 skill 只做一件事：**把“现在到哪了”写成一份任何 agent 都能读的文件**，放在项目目录的 `handoff/` 里。下一位进来，读它，就能接着干。

适合：

- 一个任务会跨越多次会话，或者要在 agent 之间转手；
- 需要留下“为什么这么定、下一步做什么、哪些别动”；
- 想让交接这件事可检查、可迁移，而不是靠记忆。

不适合：

- 纯问答、一次性脚本；
- 已经有完善工单/项目管理流程，且不需要 agent 读上下文的场景。

## 2. 快速开始

### 2.1 前置

- 任一支持的宿主：Claude Code / Qoder / OpenCode(OpenChamber) / ZCode / Codex / WorkBuddy；
- 能跑 shell 的环境（Windows Git Bash、Linux、macOS 均可）；
- git 可选：有 git 用 commit 作锚点，没有就用时间戳。

### 2.2 最小步骤

```bash
git clone https://github.com/Lizardon386/multi-agent-task-handoff.git
cd multi-agent-task-handoff
bash install.sh --dry-run     # 看会装到哪
bash install.sh               # 只装当前宿主
```

Windows 也可以直接双击根目录的 `安装.bat`：它自动找 git/bash 并调用 `install.sh`，识别不出宿主时会提示你选择。

然后在你的项目目录里对新会话说：

```text
接手
```

第一次会创建 `handoff/CONTEXT.md`；收工时说「收工」，会写卡并生成交接指针。

触发方式按宿主选一种：

- 支持斜杠命令：`/multi-agent-task-handoff <参数>`
- 支持 skill 工具：直接说「接手 / 收工 / 修复」，或从 skill 列表里选
- 都不支持：把 `SKILL.md` 的路径交给 agent，让它按文件协议执行

参数可省略（默认 `--resume`）；完整列表见 `--help`。

## 3. 使用说明

| 场景 | 说法 / 命令 | 会发生什么 |
|---|---|---|
| 新任务开工 | `--doc` | 在 `<项目目录>/handoff/` 建 CONTEXT，需要时补 README/DESIGN |
| 接手别人的任务 | `接手` / `--resume` | 读 PROMPT → CONTEXT，核锚点、跑验证 |
| 本轮收工 | `收工` / `--suspend` | 按需压卡、写 CONTEXT、覆盖 PROMPT |
| 交给指定会话 | `--suspend <ID>` | 写卡后只发一段指针，不贴全文 |
| 体检/修复 | `--check` / `--fix` | 检查安装、布局、配置、链接；`--fix` 修可自动项 |
| 摸底宿主能力 | `--probe` | 实测当前 agent 并更新能力表；`--live` 会实际建会话 |
| 路径诊断 | `--printpath` | 表格输出 config、工作区根、项目目录、能力表、安装副本、钩子 |

一次只用一个命令。安装、配置、GitHub 首页、旧布局迁移的细节见 [DESIGN.md](/handoff/DESIGN.md) 和 [SKILL.md](/SKILL.md)。

## 4. 产物与目录

```text
<项目目录>/handoff/
├─ CONTEXT.md      # 交接卡：状态、下一步、坑、记录
├─ README.md       # 任务说明（本文的源）
├─ DESIGN.md       # 设计取舍（需要时）
├─ PROMPT.md       # 交接指针，自动生成，默认 gitignore
└─ 压卡备份.md      # 压卡搬出的历史
```

| 产物 | 位置 | 用途 |
|---|---|---|
| 交接卡 | `handoff/CONTEXT.md` | 下一位 agent 的入口 |
| 交接指针 | `handoff/PROMPT.md` | 发送给新会话的短消息源 |
| 历史归档 | `handoff/压卡备份.md` | 卡超限时把日志搬出 |
| 能力缓存 | `$AGENT_CONFIG/AGENT_CAPABILITIES.md` | 宿主差异与实测结论 |
| 机器配置 | `$AGENT_CONFIG/config.toml` | 工作区根等偏好 |
| 安装注册表 | `$AGENT_CONFIG/sync-paths` | 本机已安装的宿主副本，提交后自动同步 |

项目自己的 `README.md`、`docs/`、源码都不动；任务文档只在 `handoff/`。

## 5. 限制与注意事项

- 不自动捕获会话；必须显式触发一次。
- 不在项目目录装钩子，不写全局规则，不起后台服务。
- 一个项目同一时间一个写者；交接后旧会话停写。
- memory 只读提升，不复制、不写回。
- `PROMPT.md` 默认 gitignore；敏感信息不提交。
- 会话不搬运；跨会话用“新会话 + PROMPT 指针”。
- 没有 `handoff/` 也不会自动建：先跑 `--doc`。

## 许可

[MIT](/LICENSE) © 2026 Lizardon386
