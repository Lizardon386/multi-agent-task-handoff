# multi-agent-task-handoff · 上下文与进展

> 多 agent 任务交接：状态写在 `handoff/`，下一个 agent 读卡接手；本卡只记跨机有用的状态与坑。
> 最近更新：2026-11-12
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
| `PROMPT.md` / [COMPACT_BACKUP.md](COMPACT_BACKUP.md) | 接手 / 追溯 | 自动指针（gitignore）/ 压卡历史 |
| [../SKILL.md](../SKILL.md) / [../assets/HELP.txt](../assets/HELP.txt) | agent / 使用者 | 协议正文 / 完整 `--help` |

## 目标与完成定义
> 目标一句话；完成标准必须可验证，不写过程。

- 目标：V4 协议落地；所有项目统一布局（根 README、`docs/` 设计/方案/指导类、`handoff/` 交接文档）；文档增删迁移只由 `--doc` 执行；`--post` 承担同 agent 热交接；宿主差异由能力表驱动；机械动作由显式命令执行。
- 完成标准（可验证）：`SKILL.md` / `README.md` / `docs/DESIGN.md` 与安装副本一致；命令表与 `--help` 一致；`--check` 无 ⛔；`CONTEXT.md` ≤100 行；根目录若存在项目文档 `.md`，只能是 `README.md`（包文件 `SKILL.md` 除外）；`install.sh --dryrun`、`scripts/handoff.sh --printpath` / `--syncall` 正常。

## 现在在哪
> 只写当前状态与在飞文件；已完成项压缩为结果，逐版本流水搬入 `COMPACT_BACKUP.md`；推送状态以 `git status -sb` 为准。

- 已完成：
  - 2026-11-12：新增 `--observe` 自动观察记录（开关 `[defaults].observe` 默认 on）；AGENTS 收敛为纯指针、补 `assets/AGENTS.md.tpl`、C10 修正；补测修复空文件/CRLF 边界；提交 `d5c1d57` / `62fc12c` / `f6fa360` / `b6885d6`，6 份副本已同步。
  - 2026-11-11 ZCode：`--probe --live` S+L1/L2 全项（L101 PONG 逐字、L102 建会话、L105/L106、L108、L201 5/5、L202 一致、K03 fork 独立）；L103/L104 记 ⛔；能力表更新至 ZCode 3.18.0、ZCode 必测格无「待测」；临时项目已删，2 个测试会话归档残留。
- 进行中：无。
- 在飞文件（勿动）：无。

## 下一步
> 只写可执行的 1–3 条；不写愿望或背景。

1. Ubuntu/Linux 双平台往返（Windows 已通过）：`--doc` → `--resume` → `--suspend`，再跑 `--check`、`--fix`、`--probe`、`--post`；覆盖非 git 项目、空格路径、XDG / `%APPDATA%` 变体。
2. 现有项目逐个 `--check` → `--doc` 迁移，不默认扫描全盘；dsp-hal-eval README 缺失且被 CONTEXT 引用，`--doc --guard` 会删除文档表 README 行（其余只报告）；`[defaults].post` 当前为 `new`，如需裸 `--post` 走已有会话可跑 `--gear post=next`。

## MEMORY 提炼

> 只放会影响下一家的规则/偏好；不复制记忆原文、不写本机路径/会话 ID；没有写「无」。

- 直接维护：改完跑 `scripts/handoff.sh --save`（提交 + 同步 + 推送重试）；任务收工按 `--suspend` 挡位；衍生挡位统一 `--命令 [--模式 ...]`，默认值放 `[defaults].<命令>`，`--gear` 可改，标题/HELP 写全签名。
- 功能改动必须实跑测试（正常/非法/边界/安装副本）；修 skill bug 优先结构性根治（脚本守卫、收敛动作/权限面），不靠记忆或追加规则；不加无谓检查。
- `--doc` 边界：只处理布局/标记/迁移造成的链接；`--guard` 只删 `## 文档` 表失效协议行，其余只报告；不重建/还原缺失文档；默认 `[defaults].doc=guard`；内容创建只走 `--doc --init`（只新增）；不默认生成 README（仅 GitHub remote/用户确认）。
- 图表检查/修复不纳入协议：Mermaid 图按一次性人工修复（语义判断 + SKILL 已满 150 行）。
- `--probe --live`：按 `assets/PROBE.md` 固定清单，先出计划、确认一次后跑完 S+L1+L2；L2 未过投递/读回不记 ✅；完成时当前宿主必测格无「待测」。
- `--post --next`：目标 stopped/completed 不自动唤醒；先给手动卡（打开/继续后重投），不把 queued 当已消费。
- 宿主识别：`--printpath` 按环境变量粗分；cc-haha 等包装版在能力表 Host/版本区分，协议不写宿主分支。
- 注册表迁移只在 `install.sh` 实际安装并登记时；只读/dryrun 不写；`--gear` 读取/写入需要 `config.toml`，`list` 不需要配置。
- 观察记录：协议命令出现 L2/L3 异常且 `[defaults].observe` 未关闭时，跑 `scripts/handoff.sh --observe <L2|L3> "<事件>"`；只记 skill 自身缺陷，不记环境故障/宿主限制/用户操作错误；开关默认 on。

## 坑与约束
> 只写会踩的坑与约束；协议级边界见 `SKILL.md` / `../docs/DESIGN.md`，本卡不重复；平时可追加，`--suspend` 时归并，≤10 类。

- 安装/注册表：`install.sh` 只装 HEAD（工作树未提交时副本仍落后）；旧 `.skill-sync-paths` 只在 `install.sh` 实际安装并登记时迁移，`--printpath` / `--dryrun` 只提示，`--syncall` 缺注册表+旧文件报错提示先 install；注册表换机不带，新机器重建。
- 能力表/工作区文档：`$AGENT_CONFIG/AGENT_CAPABILITIES.md` 只在不存在时播种；`AGENTS.md` / `PROJECT_RULES.md` 缺失时 `--check` 报 🟡、`--fix` 确认后播种；宿主升级可能改工具集（ZCode 3.16.3→3.18.0），投递/读回按表复验，不复用旧结论。
- 入口/发布：`install.sh` 只安装，诊断/同步用 `scripts/handoff.sh`（Windows `scripts/运行时.bat`），不加运行时子命令；包文件（`SKILL.md`、`scripts/`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`）必须留根；GitHub README 固定在根，不生成 `.github/README.md`。
- 文档：改协议或结构后手动扫 `assets/*.tpl`；命令/挡位文档只写通用机制（键与允许值由 `--gear list` 与 `scripts/lib.sh` 给出）；PROMPT 锚点用 `git log -1 --oneline`；`--doc` 边界与 README 规则见 MEMORY 提炼；审计覆盖参数签名、模板与 examples。
- git：不装钩子；`--commit` 提交协议管理文档；`--push` 在源仓库环境推源仓库、安装副本环境推当前目录仓库，重试 3 次 / 3 秒，只重试网络错误；Windows 再加 HTTP/1.1 + OpenSSL 回退 3 次；未确认推送成功不写「已推送」。
- `--post`：`--new` 的新会话必须绑定当前项目目录，Claude `CreateSession` 落 worktree（2026-11-06 实测）应拒绝，改走主项目 UI 新建 + `--next`；`--next` 先 ID 后 title，按 `title` 过滤唯一命中；`workDir` 必须等于项目目录；工具模糊查询会命中正文。
- 不回到全自动：文件改动无法触发 git（禁止常驻服务）；`--commit` / `--push` 保留；嫌步骤多只能封成一条显式命令。

## 交接记录（只记关键动作，≤10 条）
> 超出先压卡到 `COMPACT_BACKUP.md`；不写日常细节。

- 2026-11-12 cc-haha：AGENTS 收敛为纯入口指针（16→9 行）、PROJECT_RULES 承接工作区根/产物/同主题分目录/$AGENT_CONFIG 路径；新增 `assets/AGENTS.md.tpl`，CHECK C10 改为按模板播种；模板扫描无本机/宿主专属。
- 2026-11-12 cc-haha：新增 `--observe` 自动观察记录（`[defaults].observe` 默认 on，`--gear observe=off` 关闭）；写 `$AGENT_CONFIG/OBSERVATIONS.md`；SKILL/HELP/COMMANDS/DESIGN/README/配置模板同步；补测空文件/多行/CRLF/截断/空格路径/非法值与组合参数，修复空文件不建表头与 CRLF/tab 归一化；安装副本回归通过。
- 2026-11-12 cc-haha：修复文档过时项（README/COMMANDS/DESIGN 日期、README 体检行、DESIGN CHECK.md 资产/完成定义/维护自检）与 `--doc` 措辞；项目文档模板去 skill 专属命令，CHECK 增加 C13 模板通用性；实测 13 项与模板扫描通过。
- 2026-11-12 cc-haha：能力表/工作区规则/AGENTS/模板记录 PowerShell 优先 pwsh 7（绝对路径，不每次探测，5.1 兜底）；实测绝对路径调用返回 7.7.0。
- 2026-11-12 cc-haha：新增 `assets/CHECK.md` 固定检查清单（C01–C12）；`--check`/`--fix` 按清单输出 `[OK]/[WARN]/[SKIP]`；`--save` 一行摘要、`--syncall` 实际同步汇总；PROMPT 45→26、CONTEXT 80→77（记录 10→7）；实测清单 12 项、save 一行、syncall 2 份汇总。
- 2026-11-11 cc-haha：瘦身交接卡与验证分级——PROMPT 改指针卡（88→45 行）；resume 必跑 `git status`、其余按需；CONTEXT 去重压缩到 80 行；printpath/syncall 全当前时汇总一行、install dryrun 压缩；临时环境测落后/缺失/空注册表，真实仓库回归。
- 2026-11-11 ZCode：`--probe --live` 全项（S+L1/L2，L201 5/5、L202 一致、K03 fork 独立）；宿主 3.18.0 跨会话 `SendToSession` / `ReadSession` / `WaitSessions` 可用，推翻旧结论「⛔ 仅子 agent」；L103/L104 记 ⛔；能力表 ZCode 行刷新、无「待测」；临时项目已删，2 个测试会话归档（无删除 API）；压卡搬出 3 条已完成流水与 1 条最旧记录。

- 2026-11-10 cc-haha：修复注册表迁移边界（拆分 `resolve_paths` / `migrate_paths_file`，迁移只在 `install.sh` 登记分支；`--printpath` / `--dryrun` 不写；`--syncall` 缺注册表+旧文件报错提示 install）与 `--gear` 读取缺配置报错（`--gear list` 不需配置）；临时 git 仓库实测 5 项、真实仓库回归；SKILL/HELP/COMMANDS/DESIGN 同步；提交 `a186de5`。
- 2026-11-10 OpenCode：`--probe --live` S+L1+L2 全项通过（L201 5/5、L202 哨兵一致、K03 fork 独立；L103 cwd=临时项目、L104 session_move）；能力表更新至 OpenChamber 2.5.3 + OpenCode 2.2.0（内置 managed；PATH CLI 2.1.2），OpenCode 必测格无「待测」；临时项目与 3 个测试会话清理，残留 1 条项目元数据；`--fix` 非文档项通过，两条源仓库一致性问题待修。
- 2026-11-10 cc-haha：确认并修复 Qoder 报的 4 条一致性问题 + 补齐 `--doc [--target DIR]` 签名（SKILL/HELP/COMMANDS/README/DESIGN）；模板锚点改命令式、examples 跨任务规则改工作区根；`--help`/别名一致，`--doc --target`、install/syncall 复验通过。<!-- multi-agent-task-handoff: scope=handoff -->
