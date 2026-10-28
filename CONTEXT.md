# multi-agent-task-handoff · 会话上下文与进展

> 本文件是交接卡，不是变更日志：只记关键动作、当前状态、下一步和坑；细节在 git。
> 最近更新：2026-10-28
> 状态锚点：接手时跑 `git log -1 --oneline`

## 背景与目标

默认一份目录内的 `CONTEXT.md`，需要时用 `工程化` 升三档，交接只发状态不复制历史。任何 agent 都能读，不安装、不挂钩子、不起服务；git 可选。版本演进见 DESIGN 的「版本与设计演进」。

## 当前状态

- 2026-10-23：v2 已落地。`SKILL.md` 改为默认单档 + `工程化` / `交接` / `接续` + 只读自检；三份模板重写；当前工作树只保留 v2 的 SKILL、三份根文档和三份模板。
- 2026-10-28：uno-webgame 试点通过。新会话只输入「继续」，自动读 `AGENTS.md` + `CONTEXT.md`；任务级 AGENTS.md 触发成立。3178 暂不使用。
- 2026-10-28：建立 agent 能力矩阵 `AGENT_CAPABILITIES.md`（工作区根）：一行一个 agent/版本、固定能力列、就地更新；Qoder 行已填，Codex 待测。
- 2026-10-28：handoff-pilot-test 闭环通过——收工自动回填 CONTEXT；接手会话读 CONTEXT + PROJECT_RULES；send/wait/read 成功。工程化迁移/三档未测（skill 未安装）。
- 2026-10-28：P0.3 工程化模拟通过——读 SKILL/templates，接管 handoff-pilot-test，三档生成，AGENTS 与 snippet 一致，素材 hash 不变，dry-run 0 迁移。
- 2026-10-28：P0.3 真实命令通过——临时装薄 skill 后新会话执行 `工程化 handoff-pilot-test`，Skill 正常加载；接管后三档刷新（README 58 / DESIGN 199 / CONTEXT 68），AGENTS 未变，素材 hash 不变，dry-run 0 迁移；测试后临时 skill 已删除。
- 2026-10-28：补回 v1 的「DESIGN 可由交付文档承担」规则（`架构设计.md`、`XX实施方案.md` 这类复合名；评审意见不算），v2 收敛时随 references 误删。dsp-hal-eval 无 DESIGN 属正常。
- 本机无本 skill 的全局规则、钩子、计划任务或技能副本；不要重装。
- 本目录是协议真源和 git 工作树；非 git 目录用 `.review/<任务>/` 做归档/备份锚点。
- 远端同步状态以 `git status` / `git log` 为准；网络异常时先推本地提交。

## 计划 / 待办

- [x] 三份文档、`SKILL.md`、三份模板按 v2 重写。
- [x] uno-webgame 试点：任务级 AGENTS.md 触发成立（新会话只输入「继续」即读 AGENTS.md + CONTEXT.md）。
- [x] handoff-pilot-test 闭环：收工自动回填、接手读卡、send/wait/read 通过。
- [ ] 推广到 uno-online / dsp-hal-eval（3178 暂缓）；每个任务目录加 3 行 `AGENTS.md`。
- [x] 工程化模拟：三档生成 + AGENTS 一致 + dry-run 0 迁移（handoff-pilot-test）。
- [x] 真实 `工程化` 命令：临时装薄 skill 实测通过（2026-10-28），测完已删。
- [ ] 推广后复核能力表；Qoder 发交接/wait/read 已验，实际跨目录迁移仍未实测。
- [ ] 根据试点结果补工程化的迁移清单细节（排除项、hash 校验、删源确认）。
- [ ] 决定是否加可选 `check-handoff.sh`（只查存在/标题/日期/行数）；默认不加。

## 关键约束与注意事项

- 交接卡 ≤100 行；只记关键动作；交接记录 ≤5 条；不写完整变更记录。
- 一个目录同一时间只允许一个写者；交接后旧会话停写。
- git 只负责回滚，不负责交接：不在卡里抄 commit 历史；格式提交不算关键动作。
- 非 git 目录必须留备份锚点（`.review/<任务>/` 或 zip）；没有锚点就不要声称“状态可复现”。
- 不复制完整会话历史；新会话按旧 sessionId 用 `read_chat_session` 按需查。
- 打开工作区只能手动：没有 create/open workspace 工具或 CLI。
- 触发器是任务级 `AGENTS.md` 的 3 行片段；不写全局规则；宿主不读时回退显式调用。
- 不安装、不挂钩子、不写全局规则、不起后台服务、不调用模型；敏感内容留在本机。
- README / DESIGN 只在 `工程化` 或有外部读者时写，不是每个任务的合规件。

## 变更记录

- 2026-10-23：v2 落地——默认单档、`工程化`/`交接`/`接续`、只读自检；工作树只保留 v2。
- 2026-10-28：uno-webgame 试点通过；任务级 AGENTS.md 触发成立，新会话只输入「继续」即读 AGENTS.md + CONTEXT.md。
- 2026-10-28：建立能力矩阵（`assets/AGENT_CAPABILITIES.md.tpl` + 工作区根 `AGENT_CAPABILITIES.md`），Qoder 行已填，Codex 待测。
- 2026-10-28：handoff-pilot-test 闭环通过；收工自动回填、接手读卡、send/wait/read 均验；工程化未测。
- 2026-10-28：P0.3 工程化模拟通过；三档生成、AGENTS 一致、素材 hash 不变、dry-run 0 迁移。
- 2026-10-28：P0.3 真实命令通过；薄 skill 加载、三档刷新、素材 hash 不变、dry-run 0 迁移；临时 skill 已删。
- 2026-10-28：补回「DESIGN 可由方案设计交付文档承担」（v1 agents-rule 规则，v2 误删）；SKILL/README/DESIGN 同步。

## 给下一个 agent 的追加区

接手先读本卡，跑 `git log -1 --oneline` 和「验证命令」；按「下一步」做，收工更新「当前状态 / 下一步 / 坑」，并在「变更记录」加一条关键动作（≤3 行）。不要补全历史。
