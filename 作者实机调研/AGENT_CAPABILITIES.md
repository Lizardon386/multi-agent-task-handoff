# Agent 自动化能力表

> **作者实机调研快照，仅供参考。** 路径、账号、宿主版本均为作者本机环境，不代表通用约定；源文件在工作区根，更新以源文件为准（源文件更新 2026-10-29）。

> 用途：记录每个 agent / host / 版本能自动做什么，避免重复探测；表是实测缓存，不是契约。
> 迁移：整表带走（结论 + 验证方法）；换机只重填「本机环境」，按「复验成本」跑必要项，不从头重测。
> 规则：一行一个 agent+host+版本；只就地更新，不追加；没测过留“待测”，不建空行；备注不写真实会话 ID/凭据。
> 状态：✅ 已验证可用 / 🟡 部分或需确认 / 🔴 只能手动 / ⛔ 不支持 / 待测。
> 复验：版本一致且「最近验证」在 30 天内，只跑低成本项；版本变化或超期，按「验证方法」重跑，先低后中，高成本按需。
> 最近更新：2026-10-29

## 本机环境（换机重填，不计入能力结论）

- 工作区根：`$AGENT_WORKSPACE`（本机 `D:\agent_workspace`）
- OS / Shell：Windows；Git Bash `D:\software\Git\bin\bash.exe`
- 登录：gh 已登录 Lizardon386（2026-10-29 含 delete_repo scope）
- 安装副本：Qoder `~/.qoder-cn/skills/multi-agent-task-handoff`、OpenCode `~/.config/opencode/skills/multi-agent-task-handoff`、ZCode `~/.zcode/skills/multi-agent-task-handoff`

## 能力矩阵

| Agent | Host/版本 | 最近验证 | 验证方法 | 复验成本 | 读 AGENTS/CONTEXT | 文件/迁移 | 建会话 | 发交接 | 等/读会话 | 打开工作区 | git/CLI | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Qoder Desktop | Qoder Desktop CN 1.0.97 | 2026-10-28 | 读文件；`send_message_to_chat_session` + `wait_chat_sessions`；`install.sh --dry-run` | 低/中 | ✅ | 🟡 | ✅ | ✅ | ✅ | 🔴 | 🟡 | uno-webgame 读卡；handoff-pilot-test 收工回填 + 接手中继 + send/wait/read、工程化命令（三档复核、dry-run 0 迁移）已验；uno-online 压卡 + 任务级 AGENTS 触发已验；2026-10-28 color-duel 交接：双仓发送，send/wait 已验，目标会话停在等用户批工具权限（首轮未完成）；无头 Edge 截图 + CDP 可用；实际跨目录迁移未实测；Qoder CLI 未安装 |
| OpenCode (OpenChamber 桌面) | OpenChamber 2.5.2 + OpenCode 2.1.2 | 2026-10-29 | `session.create` → `session.send` → `status`/`messages`；`POST /api/experimental/session/{id}/wait` | 中 | ✅ | ✅ 文件；跨目录迁移未测 | ✅ 实测 `session.create` | ✅ 实测 `session.send` | ✅ `status`/`messages` + API wait（工具无 wait） | 🔴 | ✅ | 2026-10-29 本机实测：建会话（不传 prompt 也建，测试会话已删除）→ send（status busy）→ status idle → messages 读回 "OK"；`opencode api post /api/experimental/session/{id}/wait` 返回 204；子会话收在父会话下 |
| ZCode Desktop | ZCode 3.16.3 | 2026-10-29 | `ReadSessionContext sess_*`（须显式 ID）；子 agent `SendMessage` 往返 | 高 | ✅ | 🟡 文件可；跨目录迁移未测 | ⛔ 子 agent 非用户会话 | ⛔ 跨会话不可达；子 agent SendMessage 往返 ✅ 实测（spawn→续跑→回执） | 🟡 ReadSessionContext 须显式 sess_* ID（current 被拒）；agentId UUID 与 session_ 目录名都映射不上；无 wait | 🔴 | ✅ | 安装副本 `~/.zcode/skills/multi-agent-task-handoff`；Git Bash 宿主；install.sh 按 `ZCODE_APP_VERSION` 识别；子 agent 输出落 `~/.zcode/cli/agents/session_<hex>/agent_<uuid>/` |
| Codex | 待测 | — | — | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 未实测 |
