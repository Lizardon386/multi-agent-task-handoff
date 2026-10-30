# Agent 自动化能力表

> **作者实机调研快照，仅供参考。** 路径、账号、宿主版本均为作者本机环境，不代表通用约定；源文件在工作区根，更新以源文件为准（源文件更新 2026-10-30）。

> 用途：记录每个 agent / host / 版本能自动做什么，避免重复探测；表是实测缓存，不是契约。
> 迁移：整表带走（结论 + 验证方法）；换机只重填「本机环境」，按「复验成本」跑必要项，不从头重测。
> 规则：一行一个 agent+host+版本；只就地更新，不追加；没测过留“待测”，不建空行；不写真实会话 ID/凭据。
> 状态：✅ 已验证可用 / 🟡 部分或需确认 / 🔴 只能手动 / ⛔ 不支持 / 待测。
> 复验：版本一致且「最近验证」在 30 天内，只跑低成本项；版本变化或超期，按「验证方法」重跑，先低后中，高成本按需。
> 备注：只写该宿主**独有、无法归列**的事实，单行 ≤120 字；超出说明该拆列。履历（在哪些任务上验过）不进本表，进 git 与各任务 `CONTEXT.md`。
> 最近更新：2026-10-30

## 本机环境（换机重填，不计入能力结论）

- 工作区根：`$AGENT_WORKSPACE`（本机 `D:\agent_workspace`）
- OS / Shell：Windows；Git Bash `D:\software\Git\bin\bash.exe`
- 登录：gh 已登录 Lizardon386（2026-10-29 含 delete_repo scope）
- 安装副本：Qoder `~/.qoder-cn/skills/multi-agent-task-handoff`、OpenCode `~/.config/opencode/skills/multi-agent-task-handoff`、ZCode `~/.zcode/skills/multi-agent-task-handoff`、WorkBuddy `~/.workbuddy-ai/skills/multi-agent-task-handoff`

## 能力矩阵

| Agent | Host/版本 | 最近验证 | 验证方法 | 复验成本 | 读 AGENTS/CONTEXT | 文件/迁移 | 建会话 | 发交接 | 等/读会话 | 打开工作区 | git/CLI | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Qoder Desktop | Qoder Desktop CN 1.0.97 | 2026-10-28 | 见「投递与读回手段」；`install.sh --dry-run` | 低/中 | ✅ | 🟡 | ✅ | ✅ | ✅ | 🔴 | 🟡 | 跨目录迁移未实测；Qoder CLI 未安装；无头 Edge + CDP 可用；技能目录只认实拷贝，junction 不生效；多任务已验（详见 git 与各任务 CONTEXT） |
| OpenCode (OpenChamber 桌面) | OpenChamber 2.5.2 + OpenCode 2.1.2 | 2026-10-29 | 见「投递与读回手段」 | 中 | ✅ | ✅ 文件；跨目录迁移未测 | ✅ 实测 `session.create` | ✅ 实测 `session.send` | ✅ `status`/`messages` + API wait（工具无 wait） | 🔴 | ✅ | 建会话不传 prompt 也能建（测试会话已删）；子会话收在父会话下 |
| ZCode Desktop | ZCode 3.16.3 | 2026-10-29 | 见「投递与读回手段」 | 高 | ✅ | 🟡 文件可；跨目录迁移未测 | ⛔ 子 agent 非用户会话 | ⛔ 跨会话不可达；子 agent SendMessage 往返 ✅ 实测 | 🟡 须显式 `sess_*` ID（current 被拒）；agentId 与 session_ 目录名映射不上 | 🔴 | ✅ | 子 agent 输出落 `~/.zcode/cli/agents/session_<hex>/agent_<uuid>/`；Git Bash 宿主 |
| WorkBuddy AI（桌面） | WorkBuddy AI 5.8.4 | 2026-10-30 | 见「投递与读回手段」；`install.sh --dry-run` 自动识别 | 低 | ✅ | ✅ 文件；跨目录迁移未测 | ✅ Agent 工具建独立上下文子会话 | 🟡 只能投给新建子会话；无 SendMessage 类工具 | 🟡 前台同步返回可读；无 `read_chat_session` | 🔴 | ✅ | 子会话看不到父会话历史；`resume` 续跑返回成功但上下文延续性未确认（自述与行为矛盾，待测）；启用判据：出现在 `skill_management list` |
| Codex | 待测 | — | — | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 未实测 |

## 投递与读回手段

> SKILL.md 接盘第 3 步查「读回手段」、交接第 6 步查「投递手段」，**都从本表取，别处不记**，避免多份真源。
> memory 位置一栏：标宿主 memory 是否落在项目目录；落项目目录的要在 `.gitignore` 忽略。

| Agent | 投递手段 | 读回手段 | memory 位置 |
|---|---|---|---|
| Qoder | `send_message_to_chat_session(sessionId, prompt)` | `wait_chat_sessions` / `read_chat_session` | 主目录（宿主内部，不进项目） |
| OpenCode | `session.send`（先 `session.create`） | `messages` + `POST /api/experimental/session/{id}/wait`（返回 204） | 主目录 |
| ZCode | 跨会话不可达；仅子 agent `SendMessage` 往返 | `ReadSessionContext sess_*`（须显式 ID，无 wait） | 主目录 |
| WorkBuddy | Agent 工具 spawn 新子会话投 prompt（无跨会话投递） | 前台同步返回；`conversation_search` 只检索已沉淀历史 | 项目目录 `.workbuddy-ai/memory/`（需 gitignore） |
| Codex | 待测 | 待测 | 待测 |
