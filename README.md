# multi-agent-task-handoff · 使用说明

> 多 agent 任务接力的最小协议：默认一任务一份 `CONTEXT.md`；需要时用 `工程化` 升到三档，再用 `交接` 把状态交给另一个会话。
> 标识 `multi-agent-task-handoff`。本目录是协议真源与 git 工作树。
> 设计取舍见 [DESIGN.md](DESIGN.md)，当前进度见 [CONTEXT.md](CONTEXT.md)。
> 最近更新：2026-10-28

## 一句话说明

**skill 是可选的**：状态永远在任务目录的 `CONTEXT.md`。不装就手动复制模板，并给新 agent 一段自包含指令（不能只说“读卡”）；装了可调用 `/multi-agent-task-handoff`，由它定义读卡/工程化/交接。装 skill 不等于全自动，仍需一次触发。默认单档；`工程化` 才创建 README/DESIGN 并迁移文件；`交接` 只发交接消息，不复制聊天历史。

## 快速开始

```bash
cp assets/CONTEXT.md.tpl <任务目录>/CONTEXT.md
```

或在 Qoder 里：

```text
/multi-agent-task-handoff                  # 默认单档：确保/刷新当前目录的 CONTEXT.md
/multi-agent-task-handoff 接手              # 当前目录接手
/multi-agent-task-handoff 工程化            # 当前目录工程化（要建新目录时带名字）
/multi-agent-task-handoff 压卡              # 当前目录卡超 100 行时压回
/multi-agent-task-handoff 交接 <sessionId>  # 把交接卡发给指定会话
/multi-agent-task-handoff 接续              # 当前工作区新建会话
```

任务名可省略，默认当前目录；操作别的目录时才写成 `工程化 <任务名>`。`交接` 必须带目标 sessionId。

## 使用说明

### 默认单档

- 开始：读 `CONTEXT.md`，核对状态锚点，跑验证命令。
- 收工：只更新「现在在哪 / 下一步 / 坑」，交接记录加 1 条关键动作；≤10 条，超出时先把仍有效内容提升到状态/坑，再删最旧；不写变更流水。卡超 100 行才用 `压卡` 兜底。
- 关键判定：不知道这条，下一家会不会做错或重做？会才写；能从现有文档或 git 得到的不写。
- 收工/交接时把宿主 memory 里会影响下一家的坑写进「坑与约束」；不需要工程化。
- 上限 100 行；只记关键动作，不写完整历史。
- 自动触发：任务目录 `AGENTS.md` 追加 `assets/AGENTS.md.snippet` 的 3 行。片段只做入口，细则在 SKILL，改协议不需要同步任务目录。
- `README.md` / `DESIGN.md` 只在有外部读者或设计取舍时写，不是必填。
- 根目录已有承担方案设计的交付文档（如 `架构设计.md`、`XX实施方案.md`）时，用它代替 `DESIGN.md`；同一件事只留一份真源。

### 工程化

只在明确要求时执行。步骤：

1. 只读自检：写权限、git 状态、`list_workspaces`、`list_chat_sessions`、宿主是否有会话工具、是否有 qoder CLI；先读 `D:\agent_workspace\AGENT_CAPABILITIES.md` 并复验关键项。
2. 输出四行：可自动 / 需确认 / 需手动 / 不支持；能做的直接做，做不到的列给用户。
3. 建目录；从当前 cwd 迁移顶层非隐藏文件（排除 `.git`、`node_modules`、应用缓存）；先出清单，确认后复制、校验、默认不删源。
4. 用 `assets/*.tpl` 写三档：头块 + `## 文档` 表；README 按 GitHub 落地页，DESIGN 含拓扑/流程/架构树，CONTEXT 写 `模式：三档` 且 ≤100 行；已有方案设计交付文档时用其代替 DESIGN；任务目录 `AGENTS.md` 加 `assets/AGENTS.md.snippet`。
5. 让用户把目录打开为工作区；之后 `接续`，或手动建会话后 `交接`。

### 压卡

兜底动作，不是常规步骤。`CONTEXT.md` 超过 100 行或历史已经堆成日志时，把历史搬出去：

- 日志节原样搬到同目录 `工作记录.md`，逐块逐字校验，不改写内容。
- 非 git 目录先备份到 `.review/<任务名>/` 或 zip；有 git 直接提交，旧内容能从历史找回。
- 卡压到 ≤100 行后，才加任务级 `AGENTS.md` 触发。
- 只搬不删；确需删除时单独确认。

### 交接

- 目标会话必须已注册、未归档；`send_message_to_chat_session` 成功只代表接收。
- prompt 由交接卡生成，包含：路径、锚点、验证命令、下一步、勿动文件、已决策、项目规则指针、旧 sessionId。
- 新会话先回能力自检和锚点是否一致；旧会话用 `wait_chat_sessions` / `read_chat_session` 确认后才停写。
- 不复制历史；细节按旧 sessionId 按需读取。

### 接续

工作区打开后，按 `rootPaths` 精确匹配 workspaceId，`create_chat_session({ workspaceId, prompt })` 新建会话；找不到工作区就停，让用户先打开。

### 跨 agent

Qoder 有 `list_workspaces` / `create_chat_session` / `send_message_to_chat_session`；Codex/Claude 等没有这些 API。文件协议通用，但建工作区/建会话/发消息按宿主能力走；没有就手动。

## 产物与目录

| 文件 | 说明 |
|---|---|
| [SKILL.md](SKILL.md) | 薄协议：单档、工程化、交接、接续、自检 |
| [README.md](README.md) | 本文件 |
| [DESIGN.md](DESIGN.md) | 取舍与边界 |
| [CONTEXT.md](CONTEXT.md) | 本目录交接卡（示例） |
| [assets/CONTEXT.md.tpl](assets/CONTEXT.md.tpl) | 默认单档模板 |
| [assets/README.md.tpl](assets/README.md.tpl) | 工程化时可选的使用说明模板 |
| [assets/DESIGN.md.tpl](assets/DESIGN.md.tpl) | 工程化时可选的方案设计模板 |
| [assets/AGENTS.md.snippet](assets/AGENTS.md.snippet) | 任务级 AGENTS.md 的 3 行触发片段 |
| [assets/AGENT_CAPABILITIES.md.tpl](assets/AGENT_CAPABILITIES.md.tpl) | agent 自动化能力矩阵模板 |

版本演进（为什么从强制三档收敛到单卡）见 [DESIGN.md](DESIGN.md) 的「版本与设计演进」。

## 限制与注意事项

- 不自动捕获、不装钩子、不写全局规则、不起后台服务、不调用模型。
- 打开目录为工作区只能手动：当前没有 create/open workspace 工具或 CLI。
- 不复制完整会话历史；交接卡 + 旧 sessionId 按需查。
- 一个目录同一时间一个写者。
- agent 能按协议和现有文档判断的，自己决定并记录依据；只在规则冲突、信息缺失或不可逆时找你确认。
- git 不是前提；非 git 目录要留备份锚点（`.review/<任务>/` 或 zip）。
- 卡超过 100 行说明它在写日志，不是交接。
- 敏感内容留在本机。
