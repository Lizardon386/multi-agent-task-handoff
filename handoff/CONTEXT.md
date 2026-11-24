# multi-agent-task-handoff · 上下文与进展

> 多 agent 任务交接：状态写在 `handoff/`，下一个 agent 读卡接手；本卡只记跨机有用的状态与坑。
> 最近更新：2026-11-24
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
  - 2026-11-19：密钥扫描门禁（`--save` add 前 / `--push` 推送前）+ CHECK C15；selftest 覆盖模式矩阵与不泄露断言（52 PASS）；提交 `07879ac` / `28a6010`。
  - 2026-11-16：`plan/` 默认不提交；5 个 git 项目 `.gitignore` 加 `plan/`（本仓库已提交，其他项目本地配置）；PROJECT_RULES / 模板 / CHECK C14 / selftest 同步。
  - 2026-11-13：plan/ 计划产出落地（SKILL 压回 150 行、C14/S08/L110/K05）；新增 `scripts/selftest.sh` 机械回归（40 PASS）并接入 `--save` / `--syncall` 门禁；`--save` 同步失败不再推送；阻断路径实测通过。
  - 2026-11-13：在 3178 / uno-online / uno-webgame / color-duel / dsp-hal-eval 上执行 `--doc` / `--suspend` 验证；uno-online 完成 V4 迁移并与平台项目双向解耦后推送 `a95095f`；uno-webgame 删除过时 AGENTS.md 并按最新模板重排；3178 侧引用已清理；协议代码未改。
  - 2026-11-12：`--probe` 清单增 L109（临时 `AGENT_CONFIG` 验证 `--observe` 写入/开关/清理，不写能力表）；删除已完成的「现有项目逐个迁移」下一步。
  - 2026-11-12：新增 `--observe` 自动观察记录（开关 `[defaults].observe` 默认 on）；AGENTS 收敛为纯指针、补 `assets/AGENTS.md.tpl`、C10 修正；补测修复空文件/CRLF 边界；提交 `d5c1d57` / `62fc12c` / `f6fa360` / `b6885d6`，6 份副本已同步。
  - 2026-11-11 ZCode：`--probe --live` S+L1/L2 全项（L101 PONG 逐字、L102 建会话、L105/L106、L108、L201 5/5、L202 一致、K03 fork 独立）；L103/L104 记 ⛔；能力表更新至 ZCode 3.18.0、ZCode 必测格无「待测」；临时项目已删，2 个测试会话归档残留。
- 进行中：无。
- 在飞文件（勿动）：无。
- 维护侧优化（跨 agent 可见摘要）：已落地 selftest（52 项）/ CHECK C01–C15 / `plan/` 落点 / `--observe` / 密钥门禁；剩余 `[否决]`、`[暂缓]`、引用 ID、frontmatter 使用率为 0，不实施。
- 优化落地规则：C 项脚本化按证据触发——同类问题再现 ≥2 次或造成返工才下沉，当前候选 C08/C09（2026-11-24 取证命中 2/1 次）；用户明确要求时除外。本机细节见 `plan/golden-squishing-map.md`（不入库）。

## 下一步
> 只写可执行的 1–3 条；不写愿望或背景。

1. Windows 体验维护（当前 OpenCode/OpenChamber）：跑 `--check`，修 C01/C04/C07/C10 后用 `--fix` 复验；覆盖 `--save`/`--push`、`--syncall`、`install.sh --dryrun`、`scripts/运行时.bat`、`%APPDATA%`、空格路径、非 git 项目、CRLF。
2. Windows 跨宿主：Qoder / OpenCode / WorkBuddy 跑 selftest、密钥门禁与 `--save` FAIL 阻断；cc-haha L110 计划落点。ZCode 已卸载（2026-11-24，已从 sync-paths 移除）；重装后跑 `install.sh` + `--probe` 恢复，不追旧副本。
3. 低优先级 backlog：Ubuntu/Linux 双平台往返（原第 1 条，Windows 稳定后再做）；优化计划 `plan/golden-squishing-map.md` 剩余三项（`[否决]`/`[暂缓]`/引用 ID、frontmatter、未脚本化 C 项）仍在观察，未触发实施。

## MEMORY 提炼

> 只放会影响下一家的规则/偏好；不复制记忆原文、不写本机路径/会话 ID；没有写「无」。

- 直接维护：改完跑 `scripts/handoff.sh --save`（提交 + 同步 + 推送重试）；任务收工按 `--suspend` 挡位；衍生挡位统一 `--命令 [--模式 ...]`，默认值放 `[defaults].<命令>`，`--gear` 可改，标题/HELP 写全签名。
- 功能改动必须实跑测试（正常/非法/边界/安装副本）；修 skill bug 优先结构性根治（脚本守卫、收敛动作/权限面），不靠记忆或追加规则；不加无谓检查。
- 功能改完跑 `sh scripts/selftest.sh`；`--save` 提交前自动跑，FAIL 不提交；`--syncall` 在首次落后时自测，`--dryrun` 不跑。
- `--doc` 边界：只处理布局/标记/迁移造成的链接；`--guard` 只删 `## 文档` 表失效协议行，其余只报告；不重建/还原缺失文档；默认 `[defaults].doc=guard`；内容创建只走 `--doc --init`（只新增）；不默认生成 README（仅 GitHub remote/用户确认）。
- 图表检查/修复不纳入协议：Mermaid 图按一次性人工修复（语义判断 + SKILL 已满 150 行）。
- `--probe --live`：按 `assets/PROBE.md` 固定清单，先出计划、确认一次后跑完 S+L1+L2；L2 未过投递/读回不记 ✅；完成时当前宿主必测格无「待测」。
- `--post --next`：目标 stopped/completed 不自动唤醒；先给手动卡（打开/继续后重投），不把 queued 当已消费。
- 宿主识别：`--printpath` 按环境变量粗分；cc-haha 等包装版在能力表 Host/版本区分，协议不写宿主分支。
- 注册表迁移只在 `install.sh` 实际安装并登记时；只读/dryrun 不写；`--gear` 读取/写入需要 `config.toml`，`list` 不需要配置。
- 观察记录：协议命令出现 L2/L3 异常且 `[defaults].observe` 未关闭时，跑 `scripts/handoff.sh --observe <L2|L3> "<事件>"`；只记 skill 自身缺陷，不记环境故障/宿主限制/用户操作错误；开关默认 on。
- 密钥：`--save` / `--push` 扫描 `handoff/*.md`，命中即阻断且只报类型与位置；写卡时用 `<TOKEN>`、`${VAR}` 等占位符，不贴真实凭据。
- 优先级：Windows 体验维护优先；Ubuntu/Linux 双平台往返降为低优先级 backlog，Windows 稳定后再做。
- 优化项按证据落地：同类问题 ≥2 次或造成返工才实施；检查项优先留 `CHECK.md`，不预先脚本化；用户明确要求时除外。

## 坑与约束
> 只写会踩的坑与约束；协议级边界见 `SKILL.md` / `../docs/DESIGN.md`，本卡不重复；平时可追加，`--suspend` 时归并，≤10 类。

- 安装/注册表：`install.sh` 只装 HEAD（工作树未提交时副本仍落后）；旧 `.skill-sync-paths` 只在 `install.sh` 实际安装并登记时迁移，`--printpath` / `--dryrun` 只提示，`--syncall` 缺注册表+旧文件报错提示先 install；注册表换机不带，新机器重建。
- 能力表/工作区文档：`$AGENT_CONFIG/AGENT_CAPABILITIES.md` 只在不存在时播种；`AGENTS.md` / `PROJECT_RULES.md` 缺失时 `--check` 报 🟡、`--fix` 确认后播种；宿主升级可能改工具集（ZCode 3.16.3→3.18.0），投递/读回按表复验，不复用旧结论。
- 入口/发布：`install.sh` 只安装，诊断/同步用 `scripts/handoff.sh`（Windows `scripts/运行时.bat`），不加运行时子命令；包文件（`SKILL.md`、`scripts/`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`）必须留根；GitHub README 固定在根，不生成 `.github/README.md`。
- 文档：改协议或结构后手动扫 `assets/*.tpl`；命令/挡位文档只写通用机制（键与允许值由 `--gear list` 与 `scripts/lib.sh` 给出）；PROMPT 锚点用 `git log -1 --oneline`；`--doc` 边界与 README 规则见 MEMORY 提炼；审计覆盖参数签名、模板与 examples。
- 跨项目引用：`--doc` 只修本仓链接；其他项目指向被迁移文档的链接会失效（本次 3178→uno-online 已手工同步）。迁移后需手工扫描同工作区引用。
- git：不装钩子；`--commit` 提交协议管理文档；`--push` 在源仓库环境推源仓库、安装副本环境推当前目录仓库，重试 3 次 / 3 秒，只重试网络错误；Windows 再加 HTTP/1.1 + OpenSSL 回退 3 次；未确认推送成功不写「已推送」。
- `--post`：`--new` 的新会话必须绑定当前项目目录，Claude `CreateSession` 落 worktree（2026-11-06 实测）应拒绝，改走主项目 UI 新建 + `--next`；`--next` 先 ID 后 title，按 `title` 过滤唯一命中；`workDir` 必须等于项目目录；工具模糊查询会命中正文。
- 不回到全自动：文件改动无法触发 git（禁止常驻服务）；`--commit` / `--push` 保留；嫌步骤多只能封成一条显式命令。

## 交接记录（只记关键动作，≤10 条）
> 超出先压卡到 `COMPACT_BACKUP.md`；不写日常细节。

- 2026-11-24 cc-haha：ZCode 已卸载：从 `sync-paths` 移除副本登记（5 条），能力表保留 3.18.0 历史证据并注明重装后按 `--probe` 复验覆盖；下一步不再追旧副本。
- 2026-11-24 OpenCode：用户调整优先级——Windows 体验维护优先，Ubuntu/Linux 双平台往返降为低优先级；下一步重排为 Windows 回归 / 跨宿主 / ZCode 副本与 cc-haha L110；resume 验证 5/6 副本当前（ZCode 缺失）、doc guard OK；优化计划仍观察；未开工。
- 2026-11-19 cc-haha：实现密钥扫描门禁：`--save`（add 前）/ `--push`（推送前）扫 `handoff/*.md`，命中只报文件:行:类型、不打印内容；CHECK 增 C15；selftest 增阻断/不泄露/占位符不误报 + 模式矩阵 fixture（52 PASS）。
- 2026-11-17 cc-haha：能力表填表规则接入 `--probe` §5 / CHECK C05 / SKILL `--probe` 完成定义；均指向 `assets/AGENT_CAPABILITIES.md.tpl` 的归属/写法/时效/行规则。
- 2026-11-16 cc-haha：`plan/` 默认不提交；5 个 git 项目 `.gitignore` 加 `plan/`；PROJECT_RULES / 模板 / CHECK C14 / selftest 增加「plan/ 已忽略」检查。
- 2026-11-13 cc-haha：plan/ 计划产出落地（SKILL 压回 150 行、C14/S08/L110/K05）；新增 `scripts/selftest.sh` 机械回归（40 PASS）并接入 `--save` / `--syncall` 门禁；`--save` 同步失败不再推送；阻断路径（save 无提交、syncall 无副本）实测通过。
- 2026-11-13 cc-haha：借鉴 agents-md：PROJECT_RULES/模板增「同一问题两次纠正即停」；OBSERVATIONS 表头增「写具体、同类合并、问题消失删除」；脚本内置表头同步。
- 2026-11-13 cc-haha：多项目执行 `--doc` / `--suspend`（3178 引用清理、uno-online 迁移与解耦并推送 `a95095f`、uno-webgame 标准迁移并删 AGENTS.md、color-duel / dsp-hal-eval 补标记）；发现跨项目链接随迁移失效并手工同步；协议代码未改。
- 2026-11-12 cc-haha：`--probe` 清单增 L109（临时 `AGENT_CONFIG` 验证 `--observe` 写入/开关/清理，不写能力表）；下一步删除已完成的「现有项目逐个迁移」条。
- 2026-11-12 cc-haha：AGENTS 收敛为纯入口指针（16→9 行）、PROJECT_RULES 承接工作区根/产物/同主题分目录/$AGENT_CONFIG 路径；新增 `assets/AGENTS.md.tpl`，CHECK C10 改为按模板播种；模板扫描无本机/宿主专属。
<!-- multi-agent-task-handoff: scope=handoff -->
