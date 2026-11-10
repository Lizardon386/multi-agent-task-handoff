# multi-agent-task-handoff · 上下文与进展

> 多 agent 任务交接：状态写在 `handoff/`，下一个 agent 读卡接手；本卡只记跨机有用的状态与坑。
> 最近更新：2026-11-10
> 项目目录：`D:\agent_workspace\multi-agent-task-handoff`
> 状态锚点：`git log -1 --oneline`；推 GitHub 前 `gh auth status`
> 验证命令：`git status -sb`；`bash install.sh --dryrun`；`bash scripts/handoff.sh --printpath`；`bash scripts/handoff.sh --syncall --dryrun`

## 文档
> 只列项目文档与阅读对象；交接文档同级，README/docs 用 `../`；不复制正文。

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](../README.md) | 使用者 | 这是什么、怎么跑、限制（项目根） |
| [DESIGN.md](../docs/DESIGN.md) | 评审 / 开发 | 摘要、方案、备选、风险、决策 |
| [COMMANDS.md](../docs/COMMANDS.md) | 使用者 | 命令参考：语法、默认值、副作用、错误 |
| [CONTEXT.md](CONTEXT.md) | 接手 agent | 当前状态、下一步、记忆提炼、坑（本文） |
| `PROMPT.md` | 接手 agent | 交接指针，自动生成，默认 gitignore（不链接） |
| [COMPACT_BACKUP.md](COMPACT_BACKUP.md) | 追溯 | 状态历史、逐条变更 |
| [../SKILL.md](../SKILL.md) | agent | 协议正文 |
| [../assets/HELP.txt](../assets/HELP.txt) | 使用者 | 完整 `--help` |

## 目标与完成定义
> 目标一句话；完成标准必须可验证，不写过程。

- 目标：V4 协议落地；所有项目统一布局（根 README、`docs/` 设计/方案/指导类、`handoff/` 交接文档）；文档增删迁移只由 `--doc` 执行；`--post` 承担同 agent 热交接；宿主差异由能力表驱动；机械动作由显式命令执行。
- 完成标准（可验证）：`SKILL.md` / `README.md` / `docs/DESIGN.md` 与安装副本一致；命令表与 `--help` 一致；`--check` 无 ⛔；`CONTEXT.md` ≤100 行；根目录若存在项目文档 `.md`，只能是 `README.md`（包文件 `SKILL.md` 除外）；`install.sh --dryrun`、`scripts/handoff.sh --printpath` / `--syncall` 正常。

## 现在在哪
> 只写当前状态与在飞文件；已完成项压缩为结果，逐版本流水搬入 `COMPACT_BACKUP.md`。

- 已完成：
  - V4 协议：统一布局（根 README、`docs/` 设计/方案/指导类、`handoff/` 交接文档）；文档增删迁移只由 `--doc`；`--post` 热交接；`--suspend` 去掉 `<ID>`；不再生成 `.github/README.md`。
  - 2026-11-10 WorkBuddy：按 `assets/PROBE.md` 全量跑 `--probe --live`（计划先行、一次确认）；S + L1 + L2 全执行，L101 PONG 逐字回显、L201 真接盘 5/5、L202 哨兵一致；L103 绑定临时项目、L104 会话级切目录记 ⛔（无 workDir / 无切目录工具）；临时项目与会话清理干净；能力表就地更新 6 处，WorkBuddy 必测格无「待测」，投递/读回改记 `✅ L2（5/5）`。
  - 2026-11-10 Qoder：`--check` 通过，报 4 条源仓库一致性问题（修复计划待批准）；`--probe --live` 按 `assets/PROBE.md` 全项实测：L201 真接盘 5/5、L202 哨兵一致、K03 fork 重测通过，L103/L104 记 ⛔（建会话只绑注册 workspaceId，无建工作区/切目录 API）；能力表就地更新至 Qoder Desktop 0.5.7（stable 73fe8d7），Qoder 必测格无「待测」；临时项目已删，4 个测试会话（含 11-05 残留）经用户 UI 删除并复验清零；`--suspend --push` 收工。
  - 推送状态以 `git status -sb` 为准。
- 进行中：无。
- 在飞文件（勿动）：无。

## 下一步
> 只写可执行的 1–3 条；不写愿望或背景。

1. 修 4 条一致性问题（修复计划已给出、待批准，未批准前不动）：① `assets/HELP.txt:60` `--target` 可跟范围补 `--doc`；② `SKILL.md:43` 中文别名补「路径诊断」（不加行，保持 ≤150 行）；③ `assets/CONTEXT.md.tpl:6` / `assets/PROMPT.md.tpl:29` 锚点改命令式（`git log -1 --oneline`，不写固定 SHA）；④ `assets/examples/AGENTS.md:7` 跨任务规则改 `<工作区根>/PROJECT_RULES.md` 并注查找顺序（项目目录 → 父目录 → `$AGENT_CONFIG` 兜底）。
2. Ubuntu/Linux 双平台往返（Windows 已通过）：`--doc` → `--resume` → `--suspend`，再跑 `--check`、`--fix`、`--probe`、`--post`；顺带覆盖非 git 项目、空格路径、XDG / `%APPDATA%` 变体。
3. 现有项目逐个 `--check` → `--doc` 迁移，不默认扫描全盘；dsp-hal-eval README 缺失且被 CONTEXT 引用，`--doc --guard` 会删除文档表 README 行（其余只报告），布局继续；`[defaults].post` 当前为 `new`，如需裸 `--post` 走已有会话可跑 `--gear post=next`（之后会要求目标）。

## MEMORY 提炼

> 只放会影响下一家的规则/偏好；不复制记忆原文、不写本机路径/会话 ID；没有写「无」。

- 直接维护：改完跑 `scripts/handoff.sh --save`（提交 + 同步 + 推送重试），不等用户说「提交」；任务收工仍按 `--suspend` 挡位（默认读 `config.toml`）。
- 功能改动：改完必须实跑测试（正常/非法/边界/安装副本），汇报实际命令与结果；不把静态检查当验证。
- 修 skill bug：优先结构性根治（脚本守卫、收敛动作/权限面），不靠记忆或追加规则修补。
- `--doc` 边界：只处理布局/标记/迁移造成的链接；`--guard` 只删 `## 文档` 表中的失效协议行，其余死链/旧路径/历史内容只报告；不重建/还原缺失文档（包括从会话记录恢复）；默认挡位 `[defaults].doc=guard`；内容创建只走 `--doc --init`（只新增）。
- 衍生挡位：`--命令 [--模式 ...]`；默认值放 `[defaults].<命令>`，`--gear` 可改；标题/HELP 写全签名。
- `--doc` 不默认生成 README：仅 GitHub remote 或用户确认要发布时生成；CONTEXT 仍必生成。
- 图表检查/修复不纳入协议：Mermaid 图问题按一次性人工修复处理，不新增 `--doc` / `--check` 检查项（语义判断 + SKILL 已满 150 行）。
- `--probe --live`：按 `assets/PROBE.md` 固定清单，先出计划、确认一次后跑完 S+L1+L2；L2 未过投递/读回不记 ✅；完成时当前宿主必测格无「待测」。
- `--post --next`：目标 stopped/completed 等非活动状态时不自动唤醒；先给手动卡（打开/继续后重投），不把 queued 当已消费。
- 宿主识别：`--printpath` 按环境变量粗分；cc-haha 等包装版在能力表 Host/版本区分，协议不写宿主分支。

## 坑与约束
> 只写会踩的坑与约束；协议级边界见 `SKILL.md` / `../docs/DESIGN.md`，本卡不重复；平时可追加，`--suspend` 时归并，≤10 类。

- 安装：`install.sh` 只装 HEAD，工作树未提交时副本仍是上一个 commit；`--syncall` 只从源仓库跑（副本没有 HEAD，硬跑会把副本写成 `commit=unknown`）。
- 注册表：`$AGENT_CONFIG/sync-paths` 是本机安装注册表，`--syncall` 按它对齐副本；换机不带，新机器重建。
- 能力表：固定 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；只在不存在时从模板播种，已存在不覆盖；换机整表复制、只重填「本机环境」块；验证方法里的参数名必须与脚本一致（`--dryrun`、`--syncall`，无中间连字符），`--check` 只报不修。
- GitHub：README 固定在根，首页直接显示；不生成 `.github/README.md`。旧生成物由 `--doc` 确认后删除。
- 入口 / 发布：`install.sh` 只安装，诊断/同步用 `scripts/handoff.sh`（Windows `scripts/运行时.bat`），不要再给 install.sh 加运行时子命令；包文件（`SKILL.md`、`scripts/`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`）必须留根。
- 工作区文档：`AGENTS.md` / `PROJECT_RULES.md` 缺失时 `--check` 报 🟡，`--fix` 确认后从模板播种；已存在的只报过期。
- 文档：模板不会被 `--check` 校验；改协议或文档结构后手动扫 `assets/*.tpl`，避免模板与正文互相矛盾；命令/挡位文档只写通用机制（键与允许值由 `--gear list` 与 `scripts/lib.sh` 映射给出），新增挡位不用改 SKILL/HELP；PROMPT 锚点用 `git log -1 --oneline`，不写固定 SHA；`--doc` 只处理布局/标记/迁移造成的链接，不改文档原有死链/旧路径/历史内容；不默认生成 README（仅 GitHub remote/用户确认）；非 GitHub 项目 README 缺失时只报告，不因项目自有文档引用而创建或改引用；不从会话记录/历史副本还原缺失文档；`--doc` 先跑 `--doc --guard`（只删 `## 文档` 表失效协议行，其余只报告），内容创建只走 `--doc --init`（只新增）。
- git：不装钩子；只有 `--push` 会显式推送，`--commit` 提交协议管理文档（`handoff/` 与带标记文档及其移动/删除）；`--push` 在源仓库环境推源仓库、安装副本环境推当前目录仓库，重试 3 次 / 3 秒，只重试网络错误；Windows 再加 HTTP/1.1 + OpenSSL 回退 3 次；未确认推送成功不写「已推送」。
- `--post`：`--new` 的新会话必须绑定当前项目目录，Claude Code `CreateSession` 即使传项目目录仍落 worktree（2026-11-06 实测），且新 worktree 无 `PROMPT.md`（gitignore），按能力表应拒绝，改走主项目 UI 新建 + `--next`；`--next` 接受会话 ID 或会话名，宿主有会话列表工具（如 `ListSessions`）就直接查，不要让用户手抄 ID，查到的 `workDir` 必须等于项目目录；工具的模糊查询会命中正文（2026-11-06 实测），必须按 `title` 过滤后再判唯一；本机 `[defaults].post = "new"`；Claude 上 `--new` 落 worktree，裸 `--post` 应改 `--next`，或设 `post = "next"` 强制询问目标。
- 不回到全自动：文件改动无法触发 git（边界禁止常驻服务），没有可靠触发器时全自动=全不自动；与「git 可选」「敏感信息不提交」冲突。`--commit` / `--push` 保留；嫌步骤多只能封成一条显式命令。

## 交接记录（只记关键动作，≤10 条）
> 超出先压卡到 `COMPACT_BACKUP.md`；不写日常细节。

- 2026-11-10 Qoder：`--check` 报 4 条一致性问题（修复计划待批准）；`--probe --live` 全项实测（L201 5/5、L202 哨兵一致、K03 fork 重测），L103/L104 记 ⛔；能力表更新至 Qoder Desktop 0.5.7、Qoder 必测格无「待测」；临时项目已删，4 个测试会话经用户 UI 删除并复验清零；压卡沉降 4 条已完成流水与 1 条最旧交接记录；`--suspend --push` 收工。
- 2026-11-10 WorkBuddy：`--probe --live` 按 `assets/PROBE.md` 全项实测（S+L1+L2），L201 5/5、L202 哨兵一致，L103/L104 记 ⛔；临时项目与会话清理干净；能力表更新 6 处、WorkBuddy 必测格无「待测」；PROMPT 锚点改为命令式；`--suspend --push` 收工。
- 2026-11-09 Claude：`--probe` 固定清单落地（`assets/PROBE.md`）：S/L1/L2/K 分级、一次计划确认、临时项目隔离与清理、完成定义；每次 live 跑 L2；能力表模板/HELP/COMMANDS/DESIGN/README 同步；Claude 实测 L1/L2 5/5（临时项目，测后清理）；提交 `d76add9`，5 份副本同步。
- 2026-11-09 Claude：修复 `--push` 普通项目支持（安装副本环境推当前目录仓库，源仓库环境推源仓库，保留重试/TLS 回退）；脚本对 `--resume / --suspend / --post / --check / --fix / --probe / --workspace` 提示「由 agent 按 SKILL 执行」；HELP/SKILL/COMMANDS/DESIGN/README 同步执行层分工；临时 bare remote 实测普通项目推送成功、非 git 目录报明确错误、源仓库行为不变；提交 `913431d`，5 份副本同步。
- 2026-11-09 Claude：修正 DESIGN 5 处图问题（悬空节点 `P`、开工误绑 `--doc`、`PROJECT_RULES` 误归 `$AGENT_CONFIG`、`README / COMMANDS` 标签、带文本箭头缺空格）；8 张 Mermaid 图节点引用全局校验通过；提交 `9de3a1f`，5 份副本同步；决定图表检查/修复不纳入 `--doc` / `--check`，保持 guard 权限面与 SKILL 150 行上限。
- 2026-11-06 Claude：`--doc` 不再默认生成 README（仅 GitHub remote/用户确认）；dsp-hal-eval 实测非 git 项目零写入，旧 README 引用冲突只报告；发现另一会话从会话日志恢复其 README（5 条旧路径死链），补规则：`--doc` 不重建/还原缺失文档；README/HELP/DESIGN/模板/规则同步；`--doc [--guard | --init]` 拆分，默认 `[defaults].doc=guard`；修 bug 优先结构性根治写入工程约束；跨会话验证通过（371d87f）；guard WARN 汇总修正（根目录多文档/普通死链计入 WARN）；清理死元数据（`.skill-version` date、sync-paths 旧头、config 模板假注释、能力表旧规则）；COMMANDS 作为可选角色，guard 输出 DESIGN/COMMANDS 建议。
- 2026-11-06 Claude：`--gear` 改为 `[defaults]` 映射驱动（含 post）+ `--gear list`，非法值不改；SKILL/HELP/README/DESIGN/模板/工作区规则同步；文档复核去命令计数、修 PROMPT 锚点与本机挡位值；功能改完必须自测；`--doc` 边界明确（只修迁移链接，不改原有内容；不默认生成 README，仅 GitHub 项目）。
- 2026-11-06 Claude：V4 完备测试——`--next` 主目录会话通过；`--new` 落 worktree 判失败（新 worktree 无 PROMPT.md）；`ListSessions` 查询命中正文，SKILL 增按 `title` 过滤；`--suspend --local` 写路径验证；`--gear key=value` 写挡位（非法值不改），改为 `[defaults]` 映射驱动（含 post），SKILL/HELP 增命令与独立小节。
- 2026-11-06 Claude：V4 布局落地——README 在根、设计/方案/指导类入 `docs/`、`--doc` 独占增删迁移、`--post` 热交接、`--suspend` 去 ID；本仓库迁移并同步 5 份副本；`--post --new` 加项目目录校验；HELP 的 post 默认值改 `new / next`，坑合并至 10 类，清理 3 个已合并的 worktree 分支；`--post` 实测：`--next` 主目录会话通过，`--new` 落 worktree 判失败（新 worktree 无 PROMPT.md），能力表更新。
- 2026-11-05 Qoder：`--check` / `--fix` / `--probe --live` 通过；能力表 Qoder 行补 `--dryrun` 与实测方法；CONTEXT 清掉本机副本/探测状态；压卡一条旧记录。
## 参考 ID
> 只放可回读的 ID / 路径；不复制历史。

- 无；本卡自包含，细节按 `git log` 与 [COMPACT_BACKUP.md](COMPACT_BACKUP.md) 查。

<!-- multi-agent-task-handoff: scope=handoff -->
