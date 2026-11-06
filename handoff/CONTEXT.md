# multi-agent-task-handoff · 上下文与进展

> 多 agent 任务交接：状态写在 `handoff/`，下一个 agent 读卡接手；本卡只记跨机有用的状态与坑。
> 最近更新：2026-11-06
> 项目目录：`D:\agent_workspace\multi-agent-task-handoff`
> 状态锚点：`git log -1 --oneline`；推 GitHub 前 `gh auth status`
> 验证命令：`git status -sb`；`bash install.sh --dryrun`；`bash scripts/handoff.sh --printpath`；`bash scripts/handoff.sh --syncall --dryrun`

## 1. 文档
> 只列项目文档与阅读对象；交接文档同级，README/docs 用 `../`；不复制正文。

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](../README.md) | 使用者 | 这是什么、怎么跑、限制（项目根） |
| [DESIGN.md](../docs/DESIGN.md) | 评审 / 开发 | 目标、架构、流程、决策 |
| [CONTEXT.md](CONTEXT.md) | 接手 agent | 当前状态、下一步、记忆提炼、坑（本文） |
| `PROMPT.md` | 接手 agent | 交接指针，自动生成，默认 gitignore（不链接） |
| [COMPACT_BACKUP.md](COMPACT_BACKUP.md) | 追溯 | 状态历史、逐条变更 |
| [../SKILL.md](../SKILL.md) | agent | 协议正文 |
| [../assets/HELP.txt](../assets/HELP.txt) | 使用者 | 完整 `--help` |

## 2. 目标与完成定义
> 目标一句话；完成标准必须可验证，不写过程。

- 目标：V4 协议落地；所有项目统一布局（根 README、`docs/` 设计/方案/指导类、`handoff/` 交接文档）；文档增删迁移只由 `--doc` 执行；`--post` 承担同 agent 热交接；宿主差异由能力表驱动；机械动作由显式命令执行。
- 完成标准（可验证）：`SKILL.md` / `README.md` / `docs/DESIGN.md` 与安装副本一致；命令表与 `--help` 一致；`--check` 无 ⛔；`CONTEXT.md` ≤100 行；根目录项目文档 `.md` 只有 `README.md`（包文件 `SKILL.md` 除外）；`install.sh --dryrun`、`scripts/handoff.sh --printpath` / `--syncall` 正常。

## 3. 现在在哪
> 只写当前状态与在飞文件；已完成项压缩为结果，逐版本流水搬入 `COMPACT_BACKUP.md`。

- 已完成：
  - V4 协议：统一布局（根 README、`docs/` 设计/方案/指导类、`handoff/` 交接文档）；文档增删迁移只由 `--doc`；`--post` 热交接；`--suspend` 去掉 `<ID>`；不再生成 `.github/README.md`。
  - 2026-11-06：`SKILL.md`、`assets/*.tpl`、`HELP.txt`、`README.md`、`docs/DESIGN.md`、`CONTEXT.md`、工作区根规则全部更新；提交 `4d05229`，5 份副本已同步。
  - 2026-11-06：临时 git / 非 git 项目往返测试通过（分类、迁移、标记、改链、PROMPT 读序）。
  - 2026-11-06：`--post` 实测——`--next` 投递到主目录手动会话通过（读卡、HEAD、工作树均正常）；`--new` 仍落 worktree，且新 worktree 无 `PROMPT.md`，判定失败；能力表已更新。
  - 2026-11-06：完备体检通过（布局/标记/链接/上限/忽略/副本/安装守卫/命令面）；`--post --next` 名称解析实测发现 `ListSessions` 会命中正文，SKILL 已要求按 `title` 过滤；`--suspend --local` 写路径本次自测。
  - 2026-11-06：`--gear <key>[=<值>]` / `--gear list` 支持读写 `[defaults]`（含 `post`）；键/默认值/允许值由 `scripts/lib.sh` 映射驱动，非法值不修改；SKILL/HELP 增命令与独立小节（保持 150 行）。
  - 2026-11-06：`--gear` 改为映射驱动收尾；文档复核修正 PROMPT 锚点、硬编码命令计数与 DESIGN 本机挡位值，模板补自测规则与 gear 注释。
  - 推送状态以 `git status -sb` 为准。
- 进行中：无。
- 在飞文件（勿动）：无。

## 4. 下一步
> 只写可执行的 1–3 条；不写愿望或背景。

1. Ubuntu/Linux 双平台往返（Windows 已通过）：`--doc` → `--resume` → `--suspend`，再跑 `--check`、`--fix`、`--probe`、`--post`。
2. 非 git 项目、空格路径、XDG / `%APPDATA%` 变体。
3. 现有项目逐个 `--check` → `--doc` 迁移，不默认扫描全盘；决定 `[defaults].post` 默认值，可用 `--gear post=next` 写入（之后裸 `--post` 会要求目标）。

## 5. MEMORY 提炼

> 只放会影响下一家的规则/偏好；不复制记忆原文、不写本机路径/会话 ID；没有写「无」。

- 直接维护：改完跑 `scripts/handoff.sh --save`（提交 + 同步 + 推送重试），不等用户说「提交」；任务收工仍按 `--suspend` 挡位（默认读 `config.toml`）。
- 功能改动：改完必须实跑测试（正常/非法/边界/安装副本），汇报实际命令与结果；不把静态检查当验证。
- `--doc` 边界：只处理布局/标记/迁移造成的链接；文档原有死链/旧路径/历史内容不改，另列报告。

## 6. 坑与约束
> 只写会踩的坑与约束；协议级边界见 `SKILL.md` / `../docs/DESIGN.md`，本卡不重复；平时可追加，`--suspend` 时归并，≤10 类。

- 安装：`install.sh` 只装 HEAD，工作树未提交时副本仍是上一个 commit；`--syncall` 只从源仓库跑（副本没有 HEAD，硬跑会把副本写成 `commit=unknown`）。
- 注册表：`$AGENT_CONFIG/sync-paths` 是本机安装注册表，`--syncall` 按它对齐副本；换机不带，新机器重建。
- 能力表：固定 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；只在不存在时从模板播种，已存在不覆盖；换机整表复制、只重填「本机环境」块；验证方法里的参数名必须与脚本一致（`--dryrun`、`--syncall`，无中间连字符），`--check` 只报不修。
- GitHub：README 固定在根，首页直接显示；不生成 `.github/README.md`。旧生成物由 `--doc` 确认后删除。
- 入口 / 发布：`install.sh` 只安装，诊断/同步用 `scripts/handoff.sh`（Windows `scripts/运行时.bat`），不要再给 install.sh 加运行时子命令；包文件（`SKILL.md`、`scripts/`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`）必须留根。
- 工作区文档：`AGENTS.md` / `PROJECT_RULES.md` 缺失时 `--check` 报 🟡，`--fix` 确认后从模板播种；已存在的只报过期。
- 文档：模板不会被 `--check` 校验；改协议或文档结构后手动扫 `assets/*.tpl`，避免模板与正文互相矛盾；命令/挡位文档只写通用机制（键与允许值由 `--gear list` 与 `scripts/lib.sh` 映射给出），新增挡位不用改 SKILL/HELP；PROMPT 锚点提交后天然落后一个 commit，按「本次提交在其后」读；`--doc` 只处理布局/标记/迁移造成的链接，不改文档原有死链/旧路径/历史内容。
- git：不装钩子；只有 `--push` 会显式推送，`--commit` 提交协议管理文档（`handoff/` 与带标记文档及其移动/删除）；`--push` 由 `scripts/handoff.sh --push` 重试 3 次 / 3 秒，只重试网络错误；Windows 再加 HTTP/1.1 + OpenSSL 回退 3 次；未确认推送成功不写「已推送」。
- `--post`：`--new` 的新会话必须绑定当前项目目录，Claude Code `CreateSession` 即使传项目目录仍落 worktree（2026-11-06 实测），且新 worktree 无 `PROMPT.md`（gitignore），按能力表应拒绝，改走主项目 UI 新建 + `--next`；`--next` 接受会话 ID 或会话名，宿主有会话列表工具（如 `ListSessions`）就直接查，不要让用户手抄 ID，查到的 `workDir` 必须等于项目目录；工具的模糊查询会命中正文（2026-11-06 实测），必须按 `title` 过滤后再判唯一；本机 `config.toml` 无 `[defaults].post`，裸 `--post` 缺默认目标，应设 `post = "next"` 或强制询问目标。
- 不回到全自动：文件改动无法触发 git（边界禁止常驻服务），没有可靠触发器时全自动=全不自动；与「git 可选」「敏感信息不提交」冲突。`--commit` / `--push` 保留；嫌步骤多只能封成一条显式命令。

## 7. 交接记录（只记关键动作，≤10 条）
> 超出先压卡到 `COMPACT_BACKUP.md`；不写日常细节。

- 2026-11-06 Claude：`--gear` 改为 `[defaults]` 映射驱动（含 post）+ `--gear list`，非法值不改；SKILL/HELP/README/DESIGN/模板/工作区规则同步；文档复核去命令计数、修 PROMPT 锚点与本机挡位值；功能改完必须自测；`--doc` 边界明确（只修迁移链接，不改原有内容）。
- 2026-11-06 Claude：V4 完备测试——`--next` 主目录会话通过；`--new` 落 worktree 判失败（新 worktree 无 PROMPT.md）；`ListSessions` 查询命中正文，SKILL 增按 `title` 过滤；`--suspend --local` 写路径验证；`--gear key=value` 写挡位（非法值不改），改为 `[defaults]` 映射驱动（含 post），SKILL/HELP 增命令与独立小节。
- 2026-11-06 Claude：V4 布局落地——README 在根、设计/方案/指导类入 `docs/`、`--doc` 独占增删迁移、`--post` 热交接、`--suspend` 去 ID；本仓库迁移并同步 5 份副本；`--post --new` 加项目目录校验；HELP 的 post 默认值改 `new / next`，坑合并至 10 类，清理 3 个已合并的 worktree 分支；`--post` 实测：`--next` 主目录会话通过，`--new` 落 worktree 判失败（新 worktree 无 PROMPT.md），能力表更新。
- 2026-11-05 Qoder：`--check` / `--fix` / `--probe --live` 通过；能力表 Qoder 行补 `--dryrun` 与实测方法；CONTEXT 清掉本机副本/探测状态；压卡一条旧记录。
- 2026-11-05 WorkBuddy / Claude：v3.2–v3.10 迭代（入口拆分、`--save` 与挡位、删钩子、归档改名、README 落地页化、压卡/接手清单）；全自动方案不采纳；SKILL 正文审计（`--syncall` 条件、`--printpath` 输出、模板路径、边界措辞）；`--check` 增源仓库正文一致性审计（只报告，不自动改）；按 WorkBuddy 审计修正 `--printpath` 用法串，并写明 `--save` 属脚本层、不在 SKILL/HELP 命令表；`--push` 内置 Windows HTTP/1.1 + OpenSSL 回退；DESIGN/README 与 SKILL 口径对齐；`.gitignore` 自动评估/维护入 `--check` / `--fix` / `--suspend`。详细流水见 [COMPACT_BACKUP.md](COMPACT_BACKUP.md)。
- 2026-11-05 WorkBuddy：压卡沉降一条旧记录；`--suspend --push` 收工并推送前序提交。
- 2026-11-04 Claude：v3.1——迁移语义与 `--syncall` 护栏；能力表路径固定；README 增换机迁移；DESIGN 版本/废弃表收敛。
- 2026-11-04 Claude：文档重整——README 安装/使用分章、DESIGN 完整历程与图表、交接主体统一为 agent、`--printpath` 全量视图、5 份模板对齐；收窄自动提交记忆，`--suspend` 未给 `--push` 时抑制钩子推送；能力表补 `CreateSession` 的 worktree 落点。
- 2026-11-03 Claude：能力表拆「memory 读取」表；DESIGN 版本表补 v2 卸载、v3 评审排在 v3 前。
- 2026-11-03 Claude：钩子防护——`--printpath` 打印 hooksPath，`--check` 校验、`--fix` 恢复；定位 worktree 会话改共享 hooksPath 的坑。

## 8. 参考 ID
> 只放可回读的 ID / 路径；不复制历史。

- 无；本卡自包含，细节按 `git log` 与 [COMPACT_BACKUP.md](COMPACT_BACKUP.md) 查。

<!-- multi-agent-task-handoff: scope=handoff -->
