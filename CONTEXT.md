# multi-agent-task-handoff · 会话上下文与进展

> 本文件是交接卡：只记当前状态、下一步、坑和交接记录；历史与逐条变更见 [压卡备份.md](压卡备份.md)。
> 最近更新：2026-10-30
> 模式：三档
> 状态锚点：接盘时跑 `git log -1 --oneline`；推 GitHub 前跑 `gh auth status`
> 验证命令：`git status -sb`；`bash install.sh --dry-run`（应识别为 workbuddy）；装完用 `diff -r` 比对安装副本；`gh repo view --json visibility`；`bash sync-作者实机调研.sh --check`

## 文档

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](README.md) | 使用者 | 怎么用、命令、限制 |
| [SKILL.md](SKILL.md) | agent | 协议正文 |
| [DESIGN.md](DESIGN.md) | 评审 / 二次开发 | 取舍、流程、语义与版本演进 |
| [CONTEXT.md](CONTEXT.md) | 接盘 agent | 当前状态、下一步、坑（本文） |
| [压卡备份.md](压卡备份.md) | 追溯用 | 状态历史、已完成、逐条变更 |

## 背景与目标

默认一份目录内的 `CONTEXT.md`，需要时用 `工程化` 升三档，交接只发状态不复制历史。任何 agent 都能读，不安装、不挂钩子、不起服务；git 可选。版本演进见 DESIGN 的「版本与设计演进」。

- 完成定义：SKILL / README / DESIGN 与安装副本一致；`install.sh --dry-run` 能识别当前宿主并指向正确目录；CONTEXT ≤100 行。

## 当前状态

- 现在：已公开发布（https://github.com/Lizardon386/multi-agent-task-handoff，MIT，public）；历史经脱敏重写，旧哈希失效；origin 已接、远端 HEAD 与本地一致；四份安装副本同 HEAD。旧私有仓库已删除并同名重建。
- 公开前清理：`.skill-sync-paths` 移出 git 跟踪（本地文件）；文档里的本机路径改 `~`；工作区根改由 `AGENT_WORKSPACE` 指定，默认 `D:\agent_workspace`。
- 工作区三份文档快照：`sync-作者实机调研.sh` 从工作区根同步到 `作者实机调研/`；`--check` 只读；`post-commit` 发现过期会自动同步并提交快照，随后自动 push（不 force，失败重试一次）。
- v2 协议已落地：默认单档；`接盘` / `交接`（别名 `收工`）/ `压卡` / `工程化` / `自检`（别名 `更新`）+ 只读自检；所有任务命令只看 cwd；唯一参数是 `交接` 的 ID；`收工` 只整理，带 ID 才发送；支持 `+` 或空格串行组合（如 `压卡+收工`、`压卡 收工`）。
- 安装：`install.sh` 按宿主环境变量只给当前 agent 装（Qoder/Claude/Codex/OpenCode/ZCode/WorkBuddy；OpenCode/ZCode/WorkBuddy 也可 `--host` 显式指定），写 `.skill-version`、启用本地钩子、登记 `.skill-sync-paths`（本地文件，已 gitignore）；也支持非 git 副本（ZIP），装工作树、写 `commit=unknown`、跳过钩子和登记；`安装.bat` 是 Windows 双击入口。
- 本机已装薄 skill 四份：Qoder `~/.qoder-cn/skills/multi-agent-task-handoff`、OpenCode `~/.config/opencode/skills/multi-agent-task-handoff`、ZCode `~/.zcode/skills/multi-agent-task-handoff`、WorkBuddy `~/.workbuddy-ai/skills/multi-agent-task-handoff`（均实拷贝）；Qoder 不认目录 junction；提交后由钩子重新导出，或跑 `install.sh`。全局规则/钩子/计划任务仍无。
- 入口是命令不是文件：`接盘` 命令或 `交接` prompt（自带读卡顺序）；不在任务目录铺 `AGENTS.md`；自然语言「接盘」会加载 skill，Qoder 已验；OpenCode 靠 skill description 里的触发词加载。
- 记录粒度：每次收工 1 条关键动作，交接记录 ≤10 条自动滚动；压卡只做兜底。判定标准见「关键约束」。
- 已验证：收工回填、send/wait/read、工程化命令、压卡（uno-online 183→83 行）、skill 自动加载、OpenCode 实装（`OPENCODE` 自动识别 + `--host opencode`）、OpenCode 建会话/`session.send`/`status`/`messages`/API wait 实测（回复 OK，wait 204）、ZCode 实装（`ZCODE_APP_VERSION` 自动识别 + `--host zcode`）、ZCode 子 agent `SendMessage` 往返、WorkBuddy 实装（`CODEBUDDY_HOST` 自动识别 + `--host workbuddy`，第四份副本已装）、WorkBuddy 建子会话投 prompt 读回实测。
- 未验证：实际跨目录迁移；Codex 行待测；Claude/Codex 未在真宿主实装（只测环境识别 + 临时目录安装）。
- dsp-hal-eval 压卡已由其他 agent 完成，不在本目录处理。
- 本目录是协议真源和 git 工作树；非 git 目录靠 `压卡备份.md` 追溯。
- 远端同步状态以 `git status` / `git log` 为准；网络异常时先推本地提交。
- 2026-10-30 收工状态：WorkBuddy 宿主已支持（`CODEBUDDY_HOST=workbuddy*` 识别）；副本同步幂等化（`install.sh --sync-all`）；能力表拆「能力矩阵 + 投递与读回手段」两张表；`PROJECT_RULES` 加「改文档前自查」（三条自问 + 审计 grep），挡单宿主特例进通用文档。

## 计划 / 待办

- [ ] 其他宿主推广后复核能力表（OpenCode 行已补）；实际跨目录迁移仍未实测。
- [ ] 用 UI 复制的真实 `sess_*` ID 验证 ZCode `ReadSessionContext` 跨会话读取（`current`/agentId/目录名映射均不通，实测）。
- [ ] 补工程化的迁移清单细节（排除项、hash 校验、删源确认）。
- [ ] 决定是否加可选 `check-handoff.sh`；默认不加。
- [ ] 自动 push 连续 3 次未跑完（提交后 `git status -sb` 显示 ahead）；若持续，考虑把 push 从 `post-commit` 挪出，改手动或独立脚本。

## 关键约束与注意事项

- 仓库历史已脱敏重写（2026-10-29）：旧 commit 哈希失效，旧历史只在 `.git/pre-rewrite-2026-10-29.bundle`，不要按旧哈希查。
- `.skill-sync-paths` 是本地文件（gitignore），install.sh 生成；不要重新跟踪。
- 副本同步走 `bash install.sh --sync-all`（幂等，只补落后的，被打断也不留后患）；`.skill-sync-paths` 里是 `C:/...` 原始路径，直接 `rm -rf` 会被 safe-delete shim 拒（`SAFE_DELETE_INVALID_PATH`），必须经 install.sh 转换。
- 提交后必查 `git status -sb`：`post-commit` 的自动 push 可能在钩子被打断时没跑完（本地 ahead、远端落后）；commit 成功 ≠ 已推送。
- 改协议的三条红线：`SKILL.md` ≤120 行；流程步骤数不增（现 28 步：接盘 4 / 工程化 5 / 压卡 7 / 交接 7 / 自检 5）；新护栏优先放 `PROJECT_RULES` / README，不进 `SKILL.md`。
- 跨宿主/换机时唯一可靠载体是 `CONTEXT.md`（进版本库、所有宿主都读）；宿主 memory（如 `.workbuddy-ai/memory/`）只对同宿主同项目有效，且已 gitignore。
- 重写后的历史保留 v1 脚本与内部任务名（测试夹具名，默认不脱敏）。
- 交接卡 ≤100 行；交接记录 ≤10 条；不写完整变更记录。
- 三档只在任务目录根；没有用户明确要求，不往更深子目录铺。
- 本目录只维护本 skill；其他任务（含 dsp-hal-eval 压卡）在各自目录处理，不在这里接。
- 关键判定：不知道这条，下一家会不会做错或重做？会才写；能从 CONTEXT/README/DESIGN/git 得到的不写。记录满 10 条时，先把最旧那条仍有效的内容提升到状态/坑，再删。
- 一个目录同一时间只允许一个写者；交接后旧会话停写。
- git 只负责回滚，不负责交接：不在卡里抄 commit 历史；格式提交不算关键动作。
- 非 git 目录不另建备份；压卡前原文附在 `压卡备份.md` 末尾，没有可追溯材料就不要声称“状态可复现”。
- 不复制完整会话历史；新会话按旧 ID 用 `read_chat_session` 按需查。
- 打开工作区只能手动：没有 create/open workspace 工具或 CLI。
- 入口靠指令：接盘命令/交接 prompt；不铺任务级 `AGENTS.md`，不写全局规则。
- 压卡只改 CONTEXT 和 `压卡备份.md`；其他文档的过期链接先报告，确需改先说明确认。
- 不安装、不装常驻/全局钩子、不写全局规则、不起后台服务、不调用模型；仓库本地 `post-commit` 只做安装副本同步、快照检查和自动 push；敏感内容留在本机。
- README / DESIGN 只在 `工程化` 或有外部读者时写，不是每个任务的合规件。

## 交接记录（只记关键动作，≤10 条）

- 2026-10-28 OpenCode：补 OpenCode 能力行与卡字段（模式/验证/完成定义）；范围收窄为只维护本 skill，dsp-hal-eval 压卡已在别处完成。
- 2026-10-29 OpenCode：补「现在在哪 / 参考 ID」字段；压卡检查 71 行 / 10 条，无需压卡。
- 2026-10-29 OpenCode：SKILL description 用自然句含触发词（接手/接盘/交接/收工/压卡/工程化/自检），OpenCode 可按自然语言加载；README 补 `@` 显式调用。
- 2026-10-29 ZCode：`install.sh` 加 ZCode 宿主（`ZCODE_APP_VERSION` 自动识别 + `--host zcode`）；`.skill-sync-paths` 加 ZCode 行，按先例随宿主支持提交；本机副本增至三份。
- 2026-10-29 ZCode：交接投递按能力表本行选手段（去 Qoder 硬编码）；参考 ID 定为 `宿主:ID` 格式（`sess_*` 只在 ZCode 可读，实测）。
- 2026-10-29 ZCode：实装 ZCode 宿主收工；本轮记录滚动删「片段冻结接口」条——其载体（任务级 AGENTS 片段）v2 已移除，历史见 git 与压卡备份。
- 2026-10-29 Qoder：公开发布——MIT、`AGENT_WORKSPACE` 工作区根、脱敏重写历史；旧私有库删除后同名新建并推送，已转 public。
- 2026-10-30 WorkBuddy：加 workbuddy 宿主（`CODEBUDDY_HOST=workbuddy*` 优先识别，`WORKBUDDY_CONFIG_DIR`/`CODEBUDDY_CONFIG_DIR` 兜底，`--host workbuddy`），本机副本增至四份；能力表补 WorkBuddy 行——建独立上下文子会话/投 prompt/读回实测可用，无跨会话投递与 `read_chat_session`；`.workbuddy-ai/` 进 gitignore。
- 2026-10-30 WorkBuddy：收尾——能力表拆「能力矩阵 + 投递与读回手段」两张表（备注定 ≤120 字上限），PROJECT_RULES 定「宿主差异只进能力表，通用文档不写单宿主特例」；清掉 SKILL/README 里 3 处单宿主特例；`.workbuddy-ai/` 加全局忽略。
- 2026-10-30 WorkBuddy：收工——压卡 84 行 / 10 条无需压卡；新增护栏三条红线（`SKILL.md` ≤120 行、步骤数不增、新护栏不进协议正文）；跨宿主唯一可靠载体是 `CONTEXT.md`，宿主 memory 只对同宿主同项目有效；提交后必查 `git status -sb`（自动 push 已连续 3 次未跑完）。

## 参考 ID

- 无；本卡自包含，细节按 `git log` 与 [压卡备份.md](压卡备份.md) 查。
