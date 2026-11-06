---
name: multi-agent-task-handoff
description: 多 agent 任务接力协议：接手/接盘/交接项目、写交接卡、收工/压卡、工程化/补全 handoff 文档、自检/修复/摸底宿主能力；README 固定在项目根，交接文件在 handoff/，设计/方案类在 docs/。
when_to_use: 开始或结束一个任务、接盘别人留下的项目、把工作交接给另一个 agent、或需要检查/修复交接文档与宿主能力时。
argument-hint: "[--workspace <PATH>] [--nosave] [--help | --resume | --suspend [--local | --commit | --push] | --post <message> [--new | --next <ID | 会话名>] | --doc | --check | --fix | --probe [--static | --live] | --printpath [--host NAME | --target DIR]]"
---

# 多 agent 任务交接

## 术语

- **项目 / 项目目录**：宿主打开的那个目录/仓库（Claude 项目、Qoder 工作区、WorkBuddy 空间、OpenCode/ZCode/Codex 项目）；项目目录指其绝对路径，**唯一写入根**，来自宿主已打开的目录，或无项目时新建的目录。
- **工作区根**：`AGENT_WORKSPACE` 容器；只用来新建项目目录，**不是写入目标**。
- **当前目录**：`pwd`；可 `cd`，不改变项目。
- 交接文档只在 `<项目目录>/handoff/`；README 固定在项目根，设计/方案/指导类在 `docs/`。宿主差异与项目目录来源查 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`，SKILL 只举例，不写宿主专属规则。

## 文档布局与标记

统一布局：根 `README.md`（必需，`scope=root`，GitHub 首页直接显示）；`docs/`（设计/方案/指导类，以及任何 `scope=docs` 的自定义文档）；`handoff/`（`CONTEXT.md` 必需，`PROMPT.md`、`COMPACT_BACKUP.md` 及交接附件）。

- 标记写在文件末行：`<!-- multi-agent-task-handoff: scope=root|docs|handoff -->`；无标记 = 项目自有，协议只读；`--check` 校验 scope 与所在目录一致。
- 不生成 `.github/README.md` 或 `docs/README.md`；根 README 就是 GitHub 首页。
- 包文件（`SKILL.md`、`scripts/`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`）必须在根，不受布局影响。

## 用法

一次只用一个命令；`--workspace` 可与一个命令同用，`--nosave` 只跟 `--workspace`。

| 参数 | 作用 |
|---|---|
| 无 / `--resume` | 接盘：读 PROMPT → CONTEXT，核锚点、跑验证 |
| `--suspend [--local \| --commit \| --push]` | 压卡（按需）+ 收工 + 写 PROMPT + 对齐副本（仅源仓库） |
| `--post <message> [--new \| --next <ID \| 会话名>]` | 同 agent 热交接：把 message 投给另一个会话；不写卡、不动 git |
| `--doc` | 文档整理：建档、分类、迁移、补标记；拿不准给选项 |
| `--check` | 只读检查 |
| `--fix` | 检查 + 修非文档整理项；不碰增删迁移 |
| `--probe [--static \| --live]` | 检查 + 实测能力；`--live` 实际建会话/发送/读回 |
| `--printpath [--host NAME \| --target DIR]` | 只读路径诊断：config / workspace / 能力表 / 源仓库 / 宿主 / 副本清单 |
| `--workspace <PATH> [--nosave]` | 指定工作区根；默认写回 `config.toml` |
| `--help` | 输出完整帮助 |

中文别名：接盘/接手、压卡/收工/交接、投递/热交接、工程化/工程/建档、自检/更新、修复、摸底/探测、帮助。`--help` 输出同安装目录的 `assets/HELP.txt`；找不到时输出本文件的用法表和边界。

## 路径与配置

1. `$AGENT_CONFIG`：Linux/macOS `${XDG_CONFIG_HOME:-$HOME/.config}/multi-agent-task-handoff`；Windows `%APPDATA%\multi-agent-task-handoff`；可用 `AGENT_CONFIG` 覆盖。
2. 工作区根：本次 `--workspace` > `AGENT_WORKSPACE` > `config.toml` 的 `[paths].workspace` > `$HOME/agent_workspace`。
3. `--workspace <PATH>` 默认写回 `[paths].workspace`；`--nosave` 只本次。路径含空格加引号。
4. 能力表：`$AGENT_CONFIG/AGENT_CAPABILITIES.md`；跨任务规则：项目目录 → 父目录 → `$AGENT_CONFIG/PROJECT_RULES.md`。
5. 配置只解析简单 `key = "value"`；不 `source`，不依赖 Python。`[defaults].post`（new / next）只由 `--post` 读取。

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

1. 读：`handoff/PROMPT.md` → `handoff/CONTEXT.md`（冲突以 CONTEXT 为准）→ 跨任务规则；读「MEMORY 提炼」。产品文档不在读序，任务需要时按 CONTEXT 文档表打开。
2. 核：cwd 与 PROMPT 项目目录一致；HEAD / 工作树 / 副本状态与锚点一致；不一致先报告并说明取舍，不静默按过期状态开工（fork/worktree 回主项目或注明）。
3. 跑：PROMPT 的验证命令；失败先诊断，不静默继续。
4. 接：读「下一步」「在飞文件」「勿动文件」；参考 ID 信息不足时按能力表读回。
5. 报：向用户汇报当前状态、下一步、验证结果与阻塞。
6. 布局不符（根有 `CONTEXT.md`、`handoff/README.md` 等）→ 提示 `--check` / `--doc`，不静默迁移。

## --suspend

1. 确保 `handoff/CONTEXT.md`；≤100 行、记录 ≤10 条且坑 ≤10 类时报“无需压卡”，否则按第 2 条压卡。
2. 压卡顺序：
   - ①「已完成」逐版本流水 → 搬入 `COMPACT_BACKUP.md`，只留当前状态；②「交接记录」>10 条 → 最旧搬入。
   - ③「坑与约束」合并同类、删协议复述，≤10 类；④「下一步」「在飞文件」删已完成/失效项；⑤「MEMORY 提炼」只留影响下一家的规则。
3. 再写本次「现在/下一步/坑/交接记录」；报告 before/after 行数与搬出的条目。
4. 覆盖写 `handoff/PROMPT.md`；写前查 gitignore：git 仓且 `handoff/PROMPT.md` 未忽略时，确认后追加（拒绝或无交互则只报告，不阻塞写卡）；已跟踪只报告，交 `--fix` 处理。内容：项目目录、读卡顺序、交接文档表、锚点、验证命令、下一步 1–3 条、勿动文件、已决策、参考 ID、规则指针；末行带 `scope=handoff`；文件头注明自动生成。
5. 默认挡位读 `scripts/handoff.sh --gear suspend`（local / commit / push），显式参数覆盖；local 不操作 git，`--commit` 提交协议管理文档（`handoff/` 下的文件、带标记的文档及其移动/删除），`--push` 隐含 commit 并调 `scripts/handoff.sh --push`（网络错误 3 次 / 3 秒；Windows 再按 HTTP/1.1 + OpenSSL 回退 3 次），失败留本地并报告。收工末尾，若当前项目是本 skill 的源仓库（仓库根同时有 `.git` 与 `SKILL.md`）跑 `scripts/handoff.sh --syncall` 对齐副本；普通项目不是 skill 源仓库，安装副本没有 `.git`，都跳过并说明（有提交/推送时放在其后；幂等，只补落后）。不装钩子；写卡与指针按实际推送结果记「已推送 / 待推送」，未确认不写已推送。
6. memory：按能力表「memory 读取」定位宿主 memory；读 `MEMORY.md` 指针 + 相关条目；只把“会影响下一家”的规则/偏好写入 `CONTEXT.md` 的「MEMORY 提炼」章（无则写「无」）；不复制原文、不写回、不搬运；冲突以 CONTEXT/DESIGN/git 为准。
7. 不强制结束会话；可当 checkpoint 用。

## --post

1. `<message>` 必填；缺了报错，不猜、不代写。
2. 目标：`--new` 或 `--next <ID | 会话名>` 二选一；都不给时读 `config.toml` 的 `[defaults].post`。配成 `next` 却没有目标时停下问。
3. 解析 `--next`：先按 ID 精确匹配；不中再按会话标题匹配（唯一命中才用，多个命中列出让用户选）。宿主提供会话列表工具（如 `ListSessions`）就直接查，不要让用户手抄 ID；工具的模糊查询可能命中正文，必须按返回项的 `title` 过滤后再判唯一；查到的 `workDir` 必须等于项目目录，不一致就停。
4. `--new` 必须绑定当前项目目录：目录取自 `handoff/PROMPT.md` / `CONTEXT.md`，**不用 `pwd` 推导**（当前会话可能在 worktree）。建会话前查能力表「新建会话并绑定目录 / 落 worktree」；已知落 worktree 的宿主不走 `--new`，改给手动卡（主项目 UI 新建 → agent 用会话列表工具找到它 → `--next`）。建后核对目录，不合格就停：不投递、报告残留。
5. 投递按能力表「投递与读回手段」；不支持跨会话的宿主报 ⛔ 并给替代，不伪造成功。
6. 可酌情追加项目目录、HEAD、PROMPT 路径，必须可见标注，不混进用户原文；不写 `handoff/`、不改文档、不动 git；报告实际结果（成功 / 失败原因 / 目标会话标识），不写进仓库文件。

## --doc

1. 确定项目目录；扫描根 `*.md`、`docs/**`、`handoff/**`、`.github/*.md`，记录标记与角色候选。
2. 已有标记 → 校验 scope 与目录，不符则移动。
3. 无标记但已在角色固定位置（根 `README.md`、`handoff/CONTEXT.md`）或已在 `docs/` → 确认归属后补对应 scope。
4. 无标记但有 V1/V2/V3 三档特征 → 补标记并迁移。特征两条同时满足：①文件名符合模板（CONTEXT / README / DESIGN / COMPACT_BACKUP，含旧名 压卡备份.md、COMPACTION_BACKUP.md）；②标题含项目目录名，含义一致即可（如 color-duel 的「变色对决」）。
5. 无标记也无三档 → 按模板生成缺失角色：README、CONTEXT 必生成；DESIGN 仅在有设计取舍且用户确认时生成。
6. 角色映射：README → 根 `README.md`；方案设计类（DESIGN、架构设计、实施方案等）与指导类（INTEGRATION_GUIDE、接入/开发指南等）→ `docs/<原名>.md`；CONTEXT 与其他交接 → `handoff/`。
7. 根目录其他 `.md`：判为方案设计类或指导类的一律列入迁移；判不准的列出候选让用户选，不自行决定；用户不选就跳过。非文档产物不动。
8. 冲突停：目标已存在且不是同一份、根 README 与 `docs/README` 同时存在、某角色有多份候选 → 出选择题，未获选择前不覆盖、不改名、不合并。
9. 迁移用 `git mv`（git 仓）或 `mv`（非 git）；只移动，不复制。
10. 同批修正相对链接、CONTEXT 文档表、跨目录引用；文档从根进 `docs/` 后内部相对链接加 `../`；指向被移动文件的仓库内绝对 GitHub URL 同步改。
11. 补标记、更新日期与 CONTEXT 文档表；git 仓且未忽略时确认后把 `handoff/PROMPT.md` 加入 `.gitignore`。
12. 先输出动作清单（源 → 目标、新建、删除、改链、待选项），确认后执行；结束输出 before/after 与未处理项。

## --check / --fix

- `--check` 只读：安装副本 commit（`.skill-version`）与源仓库 HEAD、文档布局（scope 与目录、角色缺失/重复、V3 残留、CONTEXT 文档表断链）、config/workspace、能力表日期、`sync-paths`、`handoff/PROMPT.md` 是否未忽略或已跟踪、项目内 memory 是否 gitignore、PROMPT 是否过期、工作区文档（AGENTS/PROJECT_RULES 是否存在、是否指向 `$AGENT_CONFIG` 与 `handoff/`、是否残留旧路径）、CONTEXT 行数/记录数/坑类别是否超限；源仓库（根有 `SKILL.md` + `scripts/`）额外核对 SKILL 正文与 scripts/HELP/模板的命令、参数、路径、输出是否一致（只报告）；`--save` 是脚本层维护命令，不进 SKILL/HELP 命令表，缺失不报；不改文件。缺 README/DESIGN 不算错误，只提示可跑 `--doc`。
- `--fix`：先跑同一套检查，再修非文档整理项：安装副本对齐（从源仓库跑 `--syncall`）、`git rm --cached` 取消 PROMPT 跟踪、补 `.gitignore` 规则、配置/能力表缺失项；文档布局、分类、标记、链接、文档表一律只报告「需跑 `--doc`」，不创建、不删除、不移动、不改链。
- 安装副本对齐只从源仓库跑 `scripts/handoff.sh --syncall`：安装副本没有 HEAD，会被拒绝；按 commit 只补落后，已最新跳过；整体重装，副本内改动会被覆盖。
- 默认不提交；由 `--suspend --commit` 一起提交。
- 无 `handoff/` 且无旧文档 → 提示 `--doc`，不自动建。

## --probe [--static | --live]

- `--probe`：默认挡位读 `scripts/handoff.sh --gear probe`（static / live），显式参数覆盖；先检查，再做低成本实测（工作区根来源、会话列表、memory 路径、文件读写、git/CLI、config 解析）；更新能力表。
- `--probe --live`：先检查，再实际建会话/发送/读回；需确认；可能留测试会话，报告并尝试删除。实测 `--post --new` 时必须记录新会话是否落 worktree；落 worktree 记 🟡/⛔，不能只记「建会话成功」。
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

## 边界

- 一个项目一个写者；交接后旧 agent 停写。
- 冲突停，不覆盖、不换路径。
- 文件迁移默认不做；用户明确要求才复制顶层非隐藏文件。
- 活会话不搬运；换 agent 用新会话 + PROMPT 指针；同 agent 热交接用 `--post`。
- 不装钩子、不写宿主全局规则、不起后台服务、不内嵌模型调用；`--probe --live` 只经宿主会话实测。
- 工作区 `AGENTS.md` 只做入口指针；不承载协议正文，不触发机械动作。
- 敏感信息不提交；PROMPT 默认 gitignore。
- 宿主差异进能力表；SKILL 只举例，不写宿主专属规则。
- `--doc` 是唯一做文档增删迁移的命令；其他命令只修改已有文档。
- 自动化失效时先只读探测；分四类：✅ 能自动（做完验证）/ 🟡 需确认（给清单）/ 🔴 只能手动（手动卡：卡点、步骤、验证）/ ⛔ 不支持（给替代）。不伪造成功；用户完成后复验再继续。
