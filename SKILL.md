---
name: multi-agent-task-handoff
description: 多 agent 任务接力协议：接手/接盘/交接项目、写交接卡、收工/压卡、工程化/补全 handoff 文档、自检/修复/摸底宿主能力；交接文件固定在项目目录的 handoff/ 下。
when_to_use: 开始或结束一个任务、接盘别人留下的项目、把工作交接给另一个 agent、或需要检查/修复交接文档与宿主能力时。
argument-hint: "[--workspace <PATH>] [--nosave] [--help | --resume | --suspend [ID] [--local | --commit | --push] | --doc | --check | --fix | --probe [--static | --live] | --printpath [--host NAME | --target DIR]]"
---

# 多 agent 任务交接

## 术语

- **项目 / 项目目录**：宿主打开的那个目录/仓库（Claude 项目、Qoder 工作区、WorkBuddy 空间、OpenCode/ZCode/Codex 项目）；项目目录指其绝对路径，**唯一写入根**，来自宿主已打开的目录，或无项目时新建的目录。
- **工作区根**：`AGENT_WORKSPACE` 容器；只用来新建项目目录，**不是写入目标**。
- **当前目录**：`pwd`；可 `cd`，不改变项目。
- 任务文档只在 `<项目目录>/handoff/`；不写工作区根，不往子目录铺；宿主差异与项目目录来源查 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`，SKILL 只举例，不写宿主专属规则。

## 用法

一次只用一个命令；`--workspace` 可与一个命令同用，`--nosave` 只跟 `--workspace`。

| 参数 | 作用 |
|---|---|
| 无 / `--resume` | 接盘：读 PROMPT → CONTEXT，核锚点、跑验证 |
| `--suspend [ID] [--local \| --commit \| --push]` | 压卡（按需）+ 收工 + 写 PROMPT + 对齐副本（仅源仓库）；有 ID 发指针 |
| `--doc` | 补全 `handoff/` 三档 |
| `--check` | 只读检查 |
| `--fix` | 检查 + 修可自动修复项 |
| `--probe [--static \| --live]` | 检查 + 实测能力；`--live` 实际建会话/发送/读回 |
| `--printpath [--host NAME \| --target DIR]` | 只读路径诊断：config / workspace / 能力表 / 源仓库 / 宿主 / 副本清单 |
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

1. 读：`handoff/PROMPT.md` → `handoff/CONTEXT.md`（冲突以 CONTEXT 为准）→ 跨任务规则；三档再读 `handoff/README.md` / `handoff/DESIGN.md`；读「MEMORY 提炼」。
2. 核：cwd 与 PROMPT 项目目录一致；HEAD / 工作树 / 副本状态与锚点一致；不一致先报告并说明取舍，不静默按过期状态开工（fork/worktree 回主项目或注明）。
3. 跑：PROMPT 的验证命令；失败先诊断，不静默继续。
4. 接：读「下一步」「在飞文件」「勿动文件」；参考 ID 信息不足时按能力表读回。
5. 报：向用户汇报当前状态、下一步、验证结果与阻塞。
6. 旧根 `CONTEXT.md` 或根 `README/DESIGN` 带协议标记 → 提示 `--check` / `--fix`，不静默迁移。

## --suspend

1. 确保 `handoff/CONTEXT.md`；≤100 行、记录 ≤10 条且坑 ≤10 类时报“无需压卡”，否则按第 2 条压卡。
2. 压卡顺序：
   - ①「已完成」逐版本流水 → 搬入 `COMPACT_BACKUP.md`，只留当前状态；②「交接记录」>10 条 → 最旧搬入。
   - ③「坑与约束」合并同类、删协议复述，≤10 类；④「下一步」「在飞文件」删已完成/失效项；⑤「MEMORY 提炼」只留影响下一家的规则。
3. 再写本次「现在/下一步/坑/交接记录」；报告 before/after 行数与搬出的条目。
4. 覆盖写 `handoff/PROMPT.md`：项目目录、读卡顺序、文档表、锚点、验证命令、下一步 1–3 条、勿动文件、已决策、参考 ID、规则指针；文件头注明自动生成。
5. 有 ID：发短指针“请读 `<项目目录>/handoff/PROMPT.md` 接盘”；目标读不到文件时才附全文。
6. 无 ID：写完就停，报告路径。
7. 默认挡位读 `scripts/handoff.sh --gear suspend`（local / commit / push），显式参数覆盖；local 不操作 git，`--commit` 只提交 `handoff/` 下的文件，`--push` 隐含 commit 并调 `scripts/handoff.sh --push`（网络错误 3 次 / 3 秒；Windows 再按 HTTP/1.1 + OpenSSL 回退 3 次），失败留本地并报告。收工末尾，若当前项目是本 skill 的源仓库（仓库根同时有 `.git` 与 `SKILL.md`）跑 `scripts/handoff.sh --syncall` 对齐副本；普通项目不是 skill 源仓库，安装副本没有 `.git`，都跳过并说明（有提交/推送时放在其后；幂等，只补落后）。不装钩子；写卡与指针按实际推送结果记「已推送 / 待推送」，未确认不写已推送。
8. memory：按能力表「memory 读取」定位宿主 memory；读 `MEMORY.md` 指针 + 相关条目；只把“会影响下一家”的规则/偏好写入 `CONTEXT.md` 的「MEMORY 提炼」章（无则写「无」）；不复制原文、不写回、不搬运；冲突以 CONTEXT/DESIGN/git 为准。
9. 不强制结束会话；可当 checkpoint 用。

## --doc

1. 确保 `handoff/CONTEXT.md`；补 `handoff/README.md` + `handoff/DESIGN.md`；CONTEXT 写 `模式：三档`。
2. 路径固定 `handoff/`，无 `docs/` 兜底；目标已存在且非本协议生成 → 停。
3. 已有协议文件只更新文档表/日期/链接，不重写正文。
4. 根 `README.md` / `DESIGN.md` 可能是项目文档；根 `CONTEXT.md` / `COMPACT_BACKUP.md` 是旧布局任务文档；`--doc` 都不自动搬，迁移按 `--fix` 规则。
5. 不跑完整能力矩阵；只查写权限、git 状态、文档冲突；在项目 `.gitignore` 追加 `handoff/PROMPT.md`（git 仓、未忽略、用户同意）。

## 迁移规则（`--fix` 用）

- 只迁**符合模版的同名任务文档**：`CONTEXT.md`、`README.md`、`DESIGN.md`、`COMPACT_BACKUP.md`（`PROMPT.md` 由 `--suspend` 生成，不算迁移源）。
- 旧名 `压卡备份.md` / `COMPACTION_BACKUP.md` 不自动识别；确认后 `git mv` 为 `COMPACT_BACKUP.md`。
- **任何客制化名文档一律不迁**（`实施方案` / `架构设计` / 其他复合名），留在根，由 `CONTEXT.md` 的 `## 文档` 表用 `../` 链接指过去。
- 判定任务文档：root `CONTEXT.md` 存在且带 `模式：单档/三档`，或文档带模版特征（`## 文档` 表 + `最近更新`）。
- 不符合模版的产品 `README` / `DESIGN`（如 3178）不动，是项目文档。
- 单档：只迁 `CONTEXT` + `COMPACT_BACKUP`；README/DESIGN 是项目文档，不迁。
- 迁移前出清单，确认再动；有 git 用 `git mv`；`../` 链接改同级。

## --check / --fix

- `--check` 只读：安装副本 commit（`.skill-version`）与源仓库 HEAD、布局、config/workspace、能力表日期、`sync-paths`、PROMPT 与项目内 memory 是否 gitignore、`.github/README.md` 链接与 drift、PROMPT 是否过期、工作区文档（AGENTS/PROJECT_RULES 是否存在、是否指向 `$AGENT_CONFIG` 与 `handoff/`、是否残留旧路径）、CONTEXT 行数/记录数/坑类别是否超限；源仓库（根有 `SKILL.md` + `scripts/`）额外核对 SKILL 正文与 scripts/HELP/模板的命令、参数、路径、输出是否一致（只报告）；`--save` 是脚本层维护命令，不进 SKILL/HELP 命令表，缺失不报；不改文件。
- `--fix`：先跑同一套检查，再修可自动修复项；冲突/不可逆项询问；SKILL 正文差异只报告，不自动改（语义取舍需人工）。
- 可修：安装副本对齐（从源仓库跑 `--syncall`，见下）、根 CONTEXT/COMPACT_BACKUP 迁入 `handoff/`、协议标记的 README/DESIGN 迁入 `handoff/`、`.github/README.md` 重新生成、缺失的 `AGENTS.md` / `PROJECT_RULES.md` 确认后从 `assets/examples/AGENTS.md` / `assets/PROJECT_RULES.md.tpl` 播种；已存在的不改写，只报过期。
- 安装副本对齐只从源仓库跑 `scripts/handoff.sh --syncall`：安装副本没有 HEAD，会被拒绝；按 commit 只补落后，已最新跳过；整体重装，副本内改动会被覆盖。
- 默认不提交；由 `--suspend --commit` 一起提交。
- 无 `handoff/` 且无旧文档 → 提示 `--doc`，不自动建。

## --probe [--static | --live]

- `--probe`：默认挡位读 `scripts/handoff.sh --gear probe`（static / live），显式参数覆盖；先检查，再做低成本实测（工作区根来源、会话列表、memory 路径、文件读写、git/CLI、config 解析）；更新能力表。
- `--probe --live`：先检查，再实际建会话/发送/读回；需确认；可能留测试会话，报告并尝试删除。
- 结果记可用/不可用与验证方法，不写会话 ID。

## --printpath [--host NAME | --target DIR]

只读诊断，不写文件；输出表格，缺项标 ⚠️/❌。`--host NAME` / `--target DIR` 只用于显式指定宿主或安装目录。优先运行 `<skill 目录>/scripts/handoff.sh --printpath`（宿主注入的 base directory；Windows 用 Git Bash 的 sh）；没有 shell 时按 `$AGENT_CONFIG`、`config.toml`、默认值自行解析。

| 项 | 值 | 状态 |
|---|---|---|
| 配置目录 |  | — |
| 配置文件 |  | ✅ 已存在 / ⚠️ 不存在 |
| 工作区根 |  | 来源: config.toml / env / 默认 |
| 当前安装副本 |  | — |
| 能力表 |  | ✅ 存在（更新日期）/ ⚠️ 不存在 |
| 安装注册表 |  | N 条 / 缺失 |
| 源仓库 |  | — |
| 宿主 |  | 识别来源: env / --host / --target |
| 副本清单 | 逐行 路径 + commit | ✅ 当前 / ⚠️ 落后 / ❌ 缺失 |

## --help

输出同安装目录的 `assets/HELP.txt`；找不到时输出本文件的用法表和边界。

## GitHub

- `handoff/README.md` 是任务 README 源；根 README 不新建为任务 README。
- 有 GitHub remote 就生成 `.github/README.md`；无 remote 不生成；已存在且非本协议生成 → 停。
- 生成物文件头注明自动生成，链接用 `/handoff/...`；不碰根 README，不用 symlink。

## 边界

- 一个项目一个写者；交接后旧 agent 停写。
- 冲突停，不覆盖、不换路径。
- 文件迁移默认不做；用户明确要求才复制顶层非隐藏文件。
- 活会话不搬运；换 agent 用新会话 + PROMPT 指针。
- 不装钩子、不写宿主全局规则、不起后台服务、不内嵌模型调用；`--probe --live` 只经宿主会话实测。
- 工作区 `AGENTS.md` 只做入口指针；不承载协议正文，不触发机械动作。
- 敏感信息不提交；PROMPT 默认 gitignore。
- 宿主差异进能力表；SKILL 只举例，不写宿主专属规则。

## 自动化失效时

先只读探测；分四类：✅ 能自动（做完验证）/ 🟡 需确认（给清单）/ 🔴 只能手动（手动卡：卡点、步骤、验证）/ ⛔ 不支持（给替代）。不伪造成功；用户完成后复验再继续。
