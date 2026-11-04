---
name: multi-agent-task-handoff
description: 多 agent 任务接力协议：接手/接盘/交接项目、写交接卡、收工/压卡、工程化/补全 handoff 文档、自检/修复/摸底宿主能力；交接文件固定在项目目录的 handoff/ 下。
when_to_use: 开始或结束一个任务、接盘别人留下的项目、把工作交接给另一个 agent/会话、或需要检查/修复交接文档与宿主能力时。
argument-hint: "[--help | --resume | --suspend [ID] [--commit] [--push] | --doc | --check | --fix | --probe [--live] | --printpath]"
---

# 多 agent 任务交接

## 术语

- **项目**：宿主打开的那个目录/仓库（Claude 项目、Qoder 工作区、WorkBuddy 空间、OpenCode/ZCode/Codex 项目）。
- **项目目录**：项目的绝对路径，**唯一写入根**；来自宿主已打开的目录，或无项目时新建的目录。
- **工作区根**：`AGENT_WORKSPACE` 容器；只用来新建项目目录，**不是写入目标**。
- **当前目录**：`pwd`；可 `cd`，不改变项目。
- 任务文档只在 `<项目目录>/handoff/`；不写工作区根，不往子目录铺。
- 宿主差异与项目目录来源查 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；SKILL 不写宿主分支。

## 用法

一次只用一个命令；`--workspace` / `--nosave` 是全局选项，可与一个命令同用。

| 参数 | 作用 |
|---|---|
| 无 / `--resume` | 接盘：读 PROMPT → CONTEXT，核锚点、跑验证 |
| `--suspend [ID] [--commit] [--push]` | 压卡（按需）+ 收工 + 写 PROMPT；有 ID 发指针 |
| `--doc` | 补全 `handoff/` 三档 |
| `--check` | 只读检查 |
| `--fix` | 检查 + 修可自动修复项 |
| `--probe [--live]` | 检查 + 实测能力；`--live` 实际建会话/发送/读回 |
| `--printpath` | 只读路径诊断：config / workspace / 项目目录 / 能力表 / 安装副本 / 钩子 |
| `--workspace <PATH> [--nosave]` | 指定工作区根；默认写回 `config.toml` |
| `--help` | 输出完整帮助 |

中文别名：接盘/接手、压卡/收工/交接、工程化/工程/建档、自检/更新、修复、摸底/探测、帮助。

## 路径与配置

1. `$AGENT_CONFIG`：Linux/macOS `${XDG_CONFIG_HOME:-$HOME/.config}/multi-agent-task-handoff`；Windows `%APPDATA%\multi-agent-task-handoff`；可用 `AGENT_CONFIG` 覆盖。
2. 工作区根：本次 `--workspace` > `AGENT_WORKSPACE` > `config.toml` 的 `[paths].workspace` > `$HOME/agent_workspace`。
3. `--workspace <PATH>` 默认写回 `[paths].workspace`；`--nosave` 只本次。路径含空格加引号。
4. 能力表：`$AGENT_CONFIG/AGENT_CAPABILITIES.md`；跨任务规则：项目目录 → 父目录 → `$AGENT_CONFIG/PROJECT_RULES.md`。
5. 配置只解析简单 `key = "value"`；不 `source`，不依赖 Python。

## 确定项目目录

1. 宿主给出打开目录（Claude `workDir` / OpenChamber checkout 等）→ 用它。
2. 否则用会话启动时的 `pwd`。
3. 打开的目录等于工作区根 / `$HOME` / 盘根 / 临时目录 → 不算项目：
   - 报默认/配置的工作区根与来源，问是否修改；
   - 确认后建 `<工作区根>/<项目名>/`，项目名默认取 cwd 名或 `task-YYYYMMDD-HHMM`；
   - 未确认前不建目录、不写文件。
4. 不按 git 根自动上溯；要子仓级文档，就在子仓打开会话。
5. 不搬运活会话；建会话/打开目录按能力表，能自动则确认后做，否则给手动卡。

## --resume

1. 读 `handoff/PROMPT.md`；没有再读 `handoff/CONTEXT.md`；冲突以 CONTEXT 为准。
2. 读跨任务规则；三档时读 `handoff/README.md` / `handoff/DESIGN.md`。
3. 核状态锚点，跑验证命令；有参考 ID 且信息不足时按能力表读回。
4. 旧根 `CONTEXT.md` 或根 `README/DESIGN` 带协议标记 → 提示 `--check` / `--fix`，不静默迁移。

## --suspend

1. 确保 `handoff/CONTEXT.md`；只在 >100 行或 >10 条记录时压卡；没超报“无需压卡”。
2. 先压卡，再写本次「现在/下一步/坑/交接记录」；报告 before/after。
3. 覆盖写 `handoff/PROMPT.md`：项目目录、读卡顺序、文档表、锚点、验证命令、下一步 1–3 条、勿动文件、已决策、旧 ID、规则指针；文件头注明自动生成。
4. 有 ID：发短指针“请读 `<项目目录>/handoff/PROMPT.md` 接盘”；目标读不到文件时才附全文。
5. 无 ID：写完就停，报告路径。
6. 默认不操作 git；`--commit` 只提交 `handoff/` 下的文件；`--push` 隐含 commit；失败留本地并报告。
7. memory：按能力表「memory 读取」定位宿主 memory；读 `MEMORY.md` 指针 + 相关条目；只把“会影响下一家”的事实提升到 CONTEXT/DESIGN；不复制原文、不写回、不搬运；冲突以 CONTEXT/DESIGN/git 为准。
8. 不强制结束会话；可当 checkpoint 用。

## --doc

1. 确保 `handoff/CONTEXT.md`；补 `handoff/README.md` + `handoff/DESIGN.md`；CONTEXT 写 `模式：三档`。
2. 路径固定 `handoff/`，无 `docs/` 兜底；目标已存在且非本协议生成 → 停。
3. 已有协议文件只更新文档表/日期/链接，不重写正文。
4. 根 `README.md` / `DESIGN.md` / `CONTEXT.md` / `压卡备份.md` 视为项目文档，不自动搬；迁移按 `--fix` 规则。
5. 不跑完整能力矩阵；只查写权限、git 状态、文档冲突。
6. `--doc` 在项目 `.gitignore` 追加 `handoff/PROMPT.md`（git 仓、未忽略、用户同意）。

## 迁移规则（`--fix` 用）

- 只迁**符合模版的同名任务文档**：`CONTEXT.md`、`README.md`、`DESIGN.md`、`压卡备份.md`（`PROMPT.md` 由 `--suspend` 生成，不算迁移源）。
- **任何客制化名文档一律不迁**（`实施方案` / `架构设计` / 其他复合名），留在根，由 `CONTEXT.md` 的 `## 文档` 表用 `../` 链接指过去。
- 判定任务文档：root `CONTEXT.md` 存在且 `模式：三档`，或文档带模版特征（`## 文档` 表 + `最近更新`）。
- 不符合模版的产品 `README` / `DESIGN`（如 3178）不动，是项目文档。
- 单档：只迁 `CONTEXT` + `压卡备份`；README/DESIGN 是项目文档，不迁。
- 迁移前出清单，确认再动；有 git 用 `git mv`；`../` 链接改同级。

## --check / --fix

- `--check` 只读：安装版本、布局、config/workspace、能力表日期、`sync-paths`、git 钩子（`core.hooksPath`）、memory gitignore、`.github/README.md` 链接与 drift、PROMPT 是否过期、工作区文档（AGENTS/PROJECT_RULES 是否存在、是否指向 `$AGENT_CONFIG` 与 `handoff/`、是否残留旧路径）；不改文件。
- `--fix`：先跑同一套检查，再修可自动修复项；冲突/不可逆项询问。
- 可修：安装副本快进（分叉停）、根 CONTEXT/压卡备份迁入 `handoff/`、协议标记的 README/DESIGN 迁入 `handoff/`、`.github/README.md` 重新生成、`core.hooksPath` 不是 `.githooks` 时恢复（仅当 `.githooks/post-commit` 存在）、缺失的 AGENTS/PROJECT_RULES 确认后从模板播种；已存在的不改写，只报过期。
- 安装副本对齐跑 `<skill 目录>/install.sh --syncall`：只从源仓库运行（安装副本没有 HEAD，会被拒绝），只补落后副本，已最新跳过。
- 默认不提交；由 `--suspend --commit` 一起提交。
- 无 `handoff/` 且无旧文档 → 提示 `--doc`，不自动建。

## --probe [--live]

- `--probe`：先检查，再做低成本实测（工作区根来源、会话列表、memory 路径、文件读写、git/CLI、config 解析）；更新能力表。
- `--probe --live`：先检查，再实际建会话/发送/读回；需确认；可能留测试会话，报告并尝试删除。
- 结果只记可用/不可用，不写会话 ID。

## --printpath

只读诊断，不写文件。优先运行 `<skill 目录>/install.sh --printpath`（宿主注入的 base directory；Windows 用 Git Bash 的 sh）；没有 shell 时按 `$AGENT_CONFIG`、`config.toml`、默认值自行解析。

输出用表格，缺项标 ⚠️/❌：

| 项 | 值 | 状态 |
|---|---|---|
| 配置目录 |  | — |
| 配置文件 |  | ✅ 已存在 / ⚠️ 不存在 |
| 工作区根 |  | 来源: config.toml / env / 默认 |
| 项目目录 |  | — |
| 能力表 |  | ✅ 存在 / ⚠️ 不存在 |
| 安装注册表 |  | N 条 / 缺失 |
| 源仓库 |  | — |
| Git 钩子 | .githooks | ✅ 已启用 / ⚠️ 未指向 |
| 安装副本 |  | ✅ 当前 / ⚠️ 落后 |

## --help

输出同安装目录的 `assets/HELP.txt`；找不到时输出本文件的用法表和边界。

## GitHub

- `handoff/README.md` 是任务 README 源；根 README 不新建为任务 README。
- 有 GitHub remote 就生成 `.github/README.md`；无 remote 不生成；已存在且非本协议生成 → 停。
- 生成物文件头注明自动生成，链接用 `/handoff/...`；不碰根 README，不用 symlink。

## 边界

- 一个项目一个写者；交接后旧会话停写。
- 冲突停，不覆盖、不换路径。
- 文件迁移默认不做；用户明确要求才复制顶层非隐藏文件。
- 会话不搬运；用新会话 + PROMPT 指针。
- 不装常驻钩子、不写全局规则、不起后台服务、不调用模型。
- 敏感信息不提交；PROMPT 默认 gitignore。
- 宿主差异进能力表；SKILL 不写宿主分支。

## 自动化失效时

先只读探测；分四类：✅ 能自动（做完验证）/ 🟡 需确认（给清单）/ 🔴 只能手动（手动卡：卡点、步骤、验证）/ ⛔ 不支持（给替代）。不伪造成功；用户完成后复验再继续。
