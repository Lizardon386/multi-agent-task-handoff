# multi-agent-task-handoff · 压卡备份

> 状态历史、已完成归档与逐条变更，2026-10-28 从 CONTEXT.md 原样搬出；当前状态以 [CONTEXT.md](CONTEXT.md) 为准。
> 最近更新：2026-11-06
> V3 起文档迁入 `handoff/`；本文件是历史归档，不复制当前状态。

## 状态历史
> 只按时间追加；当前状态以 CONTEXT 为准。

- 2026-11-03：V3 落地——术语统一（项目 / 项目目录 / 工作区根）、文档迁入 `handoff/`、7 个命令、`config.toml`、能力差异表；删除作者快照与同步脚本。
- 2026-10-23：v2 已落地。`SKILL.md` 改为默认单档 + `工程化` / `交接` / `接续` + 只读自检；三份模板重写；当前工作树只保留 v2 的 SKILL、三份根文档和三份模板。
- 2026-10-28：uno-webgame 试点通过。新会话只输入「继续」，自动读 `AGENTS.md` + `CONTEXT.md`；任务级 AGENTS.md 触发成立。3178 暂不使用。
- 2026-10-28：建立 agent 能力矩阵 `AGENT_CAPABILITIES.md`（工作区根）：一行一个 agent/版本、固定能力列、就地更新；Qoder 行已填，Codex 待测。
- 2026-10-28：handoff-pilot-test 闭环通过——收工自动回填 CONTEXT；接手会话读 CONTEXT + PROJECT_RULES；send/wait/read 成功。三档与真实命令已验；实际跨目录迁移未实测。
- 2026-10-28：P0.3 工程化模拟通过——读 SKILL/templates，接管 handoff-pilot-test，三档生成，AGENTS 与 snippet 一致，素材 hash 不变，dry-run 0 迁移。
- 2026-10-28：P0.3 真实命令通过——临时装薄 skill 后新会话执行 `工程化 handoff-pilot-test`，Skill 正常加载；接管后三档刷新（README 58 / DESIGN 199 / CONTEXT 68），AGENTS 未变，素材 hash 不变，dry-run 0 迁移；测试后临时 skill 已删除。
- 2026-10-28：补回 v1 的「DESIGN 可由交付文档承担」规则（`架构设计.md`、`XX实施方案.md` 这类复合名；评审意见不算），v2 收敛时随 references 误删。dsp-hal-eval 无 DESIGN 属正常。
- 2026-10-28：加自动化边界：可逆整理可自动；内容取舍先按证据判；默认只搬不删。同时加默认决策规则：协议/文档/锚点/能力表能判的自己决定并记依据，只在规则冲突、缺事实、不可逆时问人。uno-online / dsp-hal-eval 的卡超 100 行，未加触发器。
- 2026-10-28：本机已装薄 skill（`~/.qoder-cn/skills/multi-agent-task-handoff`，来自 `git archive`，无 `.git`）；全局规则/钩子/计划任务仍无。
- 2026-10-28：加 `压卡 <任务名>` 正式命令（`--help` 可见）；snippet 要求收工时卡超 100 行即调用，不再靠口述。

## 已完成（归档）

- [x] 三份文档、`SKILL.md`、三份模板按 v2 重写。
- [x] uno-webgame 试点：任务级 AGENTS.md 触发成立（新会话只输入「继续」即读 AGENTS.md + CONTEXT.md）。
- [x] handoff-pilot-test 闭环：收工自动回填、接手读卡、send/wait/read 通过。
- [x] uno-online：卡 183 行 / 46 KB → 83 行 / 6.9 KB，历史原样搬到 `工作记录.md`；加 `AGENTS.md`，新会话自动读卡，未改文件。
- [x] 工程化模拟：三档生成 + AGENTS 一致 + dry-run 0 迁移（handoff-pilot-test）。
- [x] 真实 `工程化` 命令：临时装薄 skill 实测通过（2026-10-28）。
- [x] 薄 skill 常驻安装；自然语言「接手这个目录」自动加载 skill 并发起接手流程，已验（会话 `<会话ID>`）。

## 变更记录（历史）

- 2026-10-23：v2 落地——默认单档、`工程化`/`交接`/`接续`、只读自检；工作树只保留 v2。
- 2026-10-28：uno-webgame 试点通过；任务级 AGENTS.md 触发成立，新会话只输入「继续」即读 AGENTS.md + CONTEXT.md。
- 2026-10-28：建立能力矩阵（`assets/AGENT_CAPABILITIES.md.tpl` + 工作区根 `AGENT_CAPABILITIES.md`），Qoder 行已填，Codex 待测。
- 2026-10-28：handoff-pilot-test 闭环通过；收工自动回填、接手读卡、send/wait/read 均验；工程化未测。
- 2026-10-28：P0.3 工程化模拟通过；三档生成、AGENTS 一致、素材 hash 不变、dry-run 0 迁移。
- 2026-10-28：P0.3 真实命令通过；薄 skill 加载、三档刷新、素材 hash 不变、dry-run 0 迁移；临时 skill 已删。
- 2026-10-28：补回「DESIGN 可由方案设计交付文档承担」（v1 agents-rule 规则，v2 误删）；SKILL/README/DESIGN 同步。
- 2026-10-28：SKILL/DESIGN 加自动化边界「可逆整理可自动、内容取舍按证据判、默认只搬不删」。
- 2026-10-28：SKILL 加默认决策规则「能按协议/文档/锚点/能力表判定的自己做并记依据，例外才问」；README/DESIGN 同步。
- 2026-10-28：uno-online 压卡 + 触发器落地：CONTEXT 183 行 / 46 KB → 83 行 / 6.9 KB，历史原样搬到 `工作记录.md`；新会话自动读 AGENTS/CONTEXT，未改文件。
- 2026-10-28：SKILL/DESIGN 加两条评估指标（先省开场读取量、再提高自动化）与压卡步骤。
- 2026-10-28：装薄 skill 并验证自动加载：自然语言「接手这个目录」→ 新会话读 AGENTS/CONTEXT/README/DESIGN + PROJECT_RULES、核 sha256、未写入。
- 2026-10-28：压卡收成正式命令（`--help` 可见）；snippet 加压卡检查，uno-online / handoff-pilot-test 的 AGENTS 同步（fixture 432 字节）。
- 2026-10-28：`接手/工程化/压卡/接续` 的任务名改为可选，默认 cwd 目录名；只有操作别的目录时才带名字。

## 已完成流水（2026-11-05 自 CONTEXT「现在在哪」搬出）

> 原样保留；当前状态以 [CONTEXT.md](CONTEXT.md) 为准。

- V3 协议与 `handoff/` 布局；8 个命令；`config.toml`；能力差异表；memory 只读。
- v3.1：`--syncall` 改名并只允许从源仓库运行；迁移语义（能力表可搬、`sync-paths` 不带）；`--printpath` 显示宿主来源、能力表日期与全部副本状态。
- v3.2：副本同步与 push 收归 `--suspend` 显式执行；`post-commit` 降级为可选加速、不再自动 push；`core.hooksPath` 不再是必需状态。
- v3.3：入口按动作拆分——`install.sh` 只安装；`scripts/` 下的 `handoff.sh` / `运行时.bat` 负责诊断与同步，`lib.sh` 共享函数。
- v3.3.1：`--push` 走 `scripts/handoff.sh --push`，默认重试 3 次 / 3 秒，只重试网络错误；认证/冲突立即失败。
- v3.3.2：参数名去掉中间连字符——`--dryrun` / `--nohook` / `--noregister`，旧参数立即失效。
- v3.3.3：运行时脚本归入 `scripts/`（`handoff.sh` / `lib.sh` / `运行时.bat`），`install.sh` 留根；归档为 `handoff/压卡备份.md`。
- v3.4：新增 `scripts/handoff.sh --save`（提交+同步+推送重试）；`[defaults].suspend` / `.probe` 挡位，本机 `push` / `live`。
- v3.5：删除 `.githooks`，同步/推送全部显式执行；归档文件名改回 `压卡备份.md`。
- v3.6：归档文件名改为 `COMPACTION_BACKUP.md`（精确英文）；H1 保持中文。
- v3.7：handoff 文档头块统一（用途 / 阅读对象 / 更新 / 项目目录）；CONTEXT 章节加编号。
- v3.8：DESIGN 维护章同步 `--save`、挡位默认与「命令内部」流程图。
- v3.9：撤销顶块版本摘要，改为稳定描述；各文档章节补用法头。
- 文档：README 按落地页重构（快速导航、平台安装表、最短路径、样例卡、FAQ、参与）；模板同步。
- v3.10：归档文件名改为 `COMPACT_BACKUP.md`（H1 保持中文）；文档、模板、规则引用同步。
- v3.2 后续：评估「全自动化 + 删 `--commit`/`--push`」后不采纳，理由记入「坑与约束」；一条显式封装命令列为候选，未实施。
- 文档重整：README 安装/使用分章并补换机迁移；DESIGN 完整历程、版本表收敛、废弃表补全；交接主体统一为 agent；5 份模板对齐。
- 安装副本 5 份（Qoder / OpenCode / ZCode / WorkBuddy / Claude）同步到当前 HEAD。
- Claude `--probe --live` 通过：`CreateSession` 投递、`ReadSession` 读回；能力表补 `workDir` 落 worktree 的实测结论。
- WorkBuddy `--probe --live` 通过：前台子会话投递、同步读回，回传内容一致，无残留。
- 推送状态以 `git status -sb` 为准（网络异常时可能 ahead）。
- 2026-11-06：临时 git / 非 git 项目往返测试通过（分类、迁移、标记、改链、PROMPT 读序）。
- 2026-11-06：`--post` 实测——`--next` 投递到主目录手动会话通过（读卡、HEAD、工作树均正常）；`--new` 仍落 worktree，且新 worktree 无 `PROMPT.md`，判定失败；能力表已更新。
- 2026-11-06：完备体检通过（布局/标记/链接/上限/忽略/副本/安装守卫/命令面）；`--post --next` 名称解析实测发现 `ListSessions` 会命中正文，SKILL 已要求按 `title` 过滤；`--suspend --local` 写路径本次自测。
- 2026-11-06：`--gear <key>[=<值>]` / `--gear list` 支持读写 `[defaults]`（含 `post`）；键/默认值/允许值由 `scripts/lib.sh` 映射驱动，非法值不修改；SKILL/HELP 增命令与独立小节（保持 150 行）。
- 2026-11-06：`--gear` 改为映射驱动收尾；文档复核修正 PROMPT 锚点、硬编码命令计数与 DESIGN 本机挡位值，模板补自测规则与 gear 注释。
- 2026-11-06：`--doc` 不再默认生成 README，仅 GitHub remote 或用户确认发布时生成；CONTEXT 仍必生成；SKILL/README/HELP/DESIGN/模板同步；dsp-hal-eval 实测：非 git 项目跳过 README，旧 README 引用只报告不改。
- 2026-11-06：`--doc [--guard | --init]`——默认挡位 `[defaults].doc=guard`；`--guard` 只删 `## 文档` 表失效协议行，其余只报告；`--init` 只新增（不还原）；跨会话验证通过（371d87f）。

## 交接记录（压卡沉降）

> 交接记录超 10 条时先沉降到本节，条目一字未改。

- 2026-10-28 Qoder：记录滚动改为“先沉降再删最旧”，避免早期决策被滚丢。
- 2026-10-28 Qoder：AGENTS 片段改为稳定入口，协议细则不再复制到任务目录。
- 2026-10-30 WorkBuddy：能力表拆两张；PROJECT_RULES 定「宿主差异只进能力表」。
- 2026-10-30 WorkBuddy：加 workbuddy 宿主；能力表补 WorkBuddy 行；`.workbuddy-ai/` 进 gitignore。
- 2026-11-05 WorkBuddy：v3.2 落地（推送状态以 git 为准）；全自动方案评估后不采纳（理由见坑）；本次 `--suspend --push` 走显式 push + `--syncall` 收工；Claude 修正推送状态表述、收工末尾总是 `--syncall`、`--resume` 核对 cwd 与项目目录；v3.3 拆分 install/handoff 入口；v3.3.1 加 `scripts/handoff.sh --push` 网络错误重试；DESIGN 加开发者维护章，模板同步（提交/推送/同步）；v3.3.2 参数去中间连字符（`--dryrun` / `--nohook` / `--noregister`）；v3.3.3 运行时归入 `scripts/`，归档改回 `压卡备份.md`；DESIGN 版本表只留主版本，小版本细节归本卡与 `压卡备份.md`；主版本表的「结果」改为「理由与结果」，写出转向原因；维护流程标出手动/自动并补流程图；CONTEXT 增 `MEMORY 提炼` 章，承接跨 agent 的规则/偏好；新增 `--save` 与 `[defaults]` 挡位（本机 push / live）；CONTEXT 各章加用法头，模板同步；删除 `.githooks`，同步/推送全部显式执行；v3.5 归档名改回 `压卡备份.md`；v3.6 文件名改 `COMPACTION_BACKUP.md`（H1 中文）；v3.7 文档头块统一，CONTEXT 章节编号；v3.8 DESIGN 维护章同步 `--save`/挡位/流程图；v3.9 撤销顶块版本摘要，各文档章节补用法头；README 按落地页重构（快速导航、平台安装表、最短路径、样例卡、FAQ、参与），模板同步；v3.10 归档文件名改为 `COMPACT_BACKUP.md`，文档/模板/工作区规则同步。
- 2026-10-30 WorkBuddy：收尾写实——三条坑（自动 push、副本同步、验证方法）改成实测表述；验证钩子勿用管道。
- 2026-11-03 Claude：V3 落地——术语统一、文档迁入 `handoff/`、7 个命令、`config.toml`、能力差异表；删除作者快照与同步脚本；`SKILL.md` 118 行。
- 2026-11-05 Qoder：切换 GitHub 推送为 SSH 443，远端与本地对齐；无代码改动。
- 2026-11-03 Claude：V3 文档重整——README 按落地页模板重写；DESIGN 删除进度/待办、已废弃方案移入版本节；CONTEXT 承接待办。
- 2026-11-03 Claude：机器级状态收口——`sync-paths` 迁到 `$AGENT_CONFIG`，仓库内不再留；工作区根能力表副本删除，只留 `$AGENT_CONFIG` 一份；DESIGN 补 5.1.1 与迁移范围。
- 2026-11-03 Claude：钩子防护——`--printpath` 打印 hooksPath，`--check` 校验、`--fix` 恢复；定位 worktree 会话改共享 hooksPath 的坑。
- 2026-11-03 Claude：能力表拆「memory 读取」表；DESIGN 版本表补 v2 卸载、v3 评审排在 v3 前。
- 2026-11-04 Claude：v3.1——迁移语义与 `--syncall` 护栏；能力表路径固定；README 增换机迁移；DESIGN 版本/废弃表收敛。
- 2026-11-04 Claude：文档重整——README 安装/使用分章、DESIGN 完整历程与图表、交接主体统一为 agent、`--printpath` 全量视图、5 份模板对齐；收窄自动提交记忆，`--suspend` 未给 `--push` 时抑制钩子推送；能力表补 `CreateSession` 的 worktree 落点。

<!-- multi-agent-task-handoff: scope=handoff -->
