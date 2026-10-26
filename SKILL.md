---
name: multi-agent-task-handoff
description: 多 agent 任务接力协议：默认一份 CONTEXT.md 交接卡；工程化后升三档（README/DESIGN/CONTEXT），按 3178 式文档头块与文档表维护。
when_to_use: 开始或结束一个任务、接手别人留下的任务目录、把工作交接给另一个 agent/会话、或要把当前会话工程化到新目录时。
argument-hint: "[工程化 <任务名> | 交接 <sessionId> | 接续 <任务名>]"
---

# 多 agent 任务交接

## 默认：单档

每个任务目录只维护 `CONTEXT.md`（模板 `assets/CONTEXT.md.tpl`）。

- CONTEXT 顶部写 `模式：单档`；只记关键动作，≤100 行。
- 开始：读卡、核对状态锚点、跑验证命令。
- 收工：更新「现在在哪 / 下一步 / 坑」，交接记录加一条关键动作（≤3 行）。
- README/DESIGN 只在有外部读者或设计取舍时写。

## 工程化 <任务名>

用户明确要求时才执行。先只读自检，再按「自动 → 确认 → 手动」执行。

1. **自检**：pwd/写权限、git 状态、`list_workspaces`、`list_chat_sessions`、当前宿主是否有 `create_chat_session` / `send_message_to_chat_session` / `wait_chat_sessions` / `read_chat_session`、`command -v qoder`。输出四行：✅ 可自动 / 🟡 需确认 / 🔴 需手动 / ⛔ 不支持；不要问用户“你能不能做 X”。
2. **建目录**：cwd 已在 `D:\agent_workspace` 下则接管；否则建 `D:\agent_workspace\<任务名>`，已存在不覆盖。
3. **迁移**：先列「源 → 目标」清单；只处理 cwd 顶层非隐藏文件，排除 `.git`、`node_modules`、应用缓存；确认后复制、校验 hash、默认不删源；移动/覆盖/删除单独确认。
4. **写三档**：用 `assets/*.tpl` 生成 README/DESIGN/CONTEXT，删掉模板注释；三份都要有 H1 + 一句话 + `最近更新` + `## 文档` 表；CONTEXT 写 `模式：三档`。
   - README 按 GitHub 落地页写：这是什么 / 快速开始 / 使用说明 / 产物与目录 / 限制。
   - DESIGN 至少有：目标与约束、运行模式/拓扑（mermaid）、核心流程（mermaid 时序或流程）、4.1 包/目录文本树 + 关系图、关键决策表、已定语义/工程约束。
   - CONTEXT 保持 ≤100 行，只记关键动作。
5. **下一步**：让用户把目录打开为工作区；之后跑 `接续 <任务名>`，或手动建会话后跑 `交接 <sessionId>`。

## 维护（按模式）

- 开始：读 CONTEXT；`模式：三档` 时再读 README/DESIGN。
- 收工：CONTEXT 每次更新；README 仅在用法/产物变化时更新；DESIGN 仅在设计/架构变化时更新；三份的 `## 文档` 表和日期同步。
- 质量自检：新 agent 能否只读这些文档回答 目标/当前/下一步/坑/验证；答不上就补，不交给下一家。
- 单档不维护 README/DESIGN；三档才维护。

## 交接 <sessionId>

1. 读 CONTEXT，确认字段齐全：模式、目标/完成定义、现在在哪、下一步、坑、锚点、验证命令、交接记录、参考会话。
2. 生成 prompt（≤40k）：工作目录 + 文档表 + 锚点 + 验证命令 + 下一步 1–3 条 + 勿动文件 + 已决策 + 旧会话 ID；要求新会话先回能力自检 + 锚点一致/不一致。
3. `send_message_to_chat_session(sessionId, prompt)`；成功只代表接收。
4. `wait_chat_sessions` / `read_chat_session` 确认锚点与验证通过；否则补信息，不宣布完成。
5. 更新「当前接手」「交接记录」；旧会话停写。

## 接续 <任务名>

工作区已打开时：`list_workspaces` 按 `rootPaths` 精确匹配；找不到就停。读卡生成 prompt，`create_chat_session({ workspaceId, prompt })`，后续同「交接」的确认步骤。

## 规则

- 能自动：建目录、复制、写文档、发消息给已知 sessionId、等/读。
- 需确认：移动/删除源、覆盖、commit/push、创建会话。
- 只能手动：打开工作区；跨宿主会话 API；复制完整历史（不做）。
- 失败就停，报告实际错误；不猜 workspaceId/sessionId。一个目录同一时间一个写者。
- 不装钩子、不写全局规则、不铺副本、不起后台服务、不调用模型。
