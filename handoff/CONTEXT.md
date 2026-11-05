# multi-agent-task-handoff · 上下文与进展

> 多 agent 任务交接：状态写在 `handoff/`，下一个 agent 读卡接手；本卡只记跨机有用的状态与坑。
> 最近更新：2026-11-05
> 模式：三档
> 项目目录：`D:\agent_workspace\multi-agent-task-handoff`
> 状态锚点：`git log -1 --oneline`；推 GitHub 前 `gh auth status`
> 验证命令：`git status -sb`；`bash install.sh --dryrun`；`bash scripts/handoff.sh --printpath`；`bash scripts/handoff.sh --syncall --dryrun`

## 1. 文档
> 只列任务文档与阅读对象；项目根文档用 `../`；不复制正文。

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](README.md) | 使用者 | 这是什么、怎么跑、限制 |
| [DESIGN.md](DESIGN.md) | 评审 / 开发 | 目标、架构、流程、决策 |
| [CONTEXT.md](CONTEXT.md) | 接手 agent | 当前状态、下一步、记忆提炼、坑（本文） |
| `PROMPT.md` | 接手 agent | 交接指针，自动生成，默认 gitignore（不链接） |
| [COMPACT_BACKUP.md](COMPACT_BACKUP.md) | 追溯 | 状态历史、逐条变更 |
| [../SKILL.md](../SKILL.md) | agent | 协议正文 |
| [../assets/HELP.txt](../assets/HELP.txt) | 使用者 | 完整 `--help` |

## 2. 目标与完成定义
> 目标一句话；完成标准必须可验证，不写过程。

- 目标：V3.10 协议落地；任务文档固定在 `handoff/`；宿主差异由能力表驱动；交接只发指针；机械动作由显式命令执行。
- 完成标准（可验证）：`SKILL.md` / `README.md` / `DESIGN.md` 与安装副本一致；8 个命令与 `--help` 一致；`--check` 无 ⛔；`CONTEXT.md` ≤100 行；`install.sh --dryrun`、`scripts/handoff.sh --printpath` / `--syncall` 正常。

## 3. 现在在哪
> 只写当前状态与在飞文件；已完成项压缩为结果，逐版本流水搬入 `COMPACT_BACKUP.md`。

- 已完成：
  - V3 协议与 `handoff/` 布局；8 个命令；`config.toml`；能力差异表；memory 只读。
  - 当前协议 v3.10：`--save` 与挡位、无钩子、`scripts/` 入口、`COMPACT_BACKUP.md` 归档名、README 落地页、`--suspend` 压卡清单、`--resume` 接手清单、源仓库正文审计。
  - 2026-11-05：`--check` / `--fix` / `--probe --live` 通过；能力表 Qoder 行更新；CONTEXT 清掉本机副本/探测状态。
  - 推送状态以 `git status -sb` 为准。
- 进行中：无代码改动；本次收工提交 handoff 文档。
- 在飞文件（勿动）：无。

## 4. 下一步
> 只写可执行的 1–3 条；不写愿望或背景。

1. 双平台往返测试：临时 git 项目跑 `--resume` → `--suspend` → `--resume`，再跑 `--doc`、`--check`、`--fix`、`--probe`。
2. 非 git 项目、Windows Git Bash、Ubuntu 路径测试（`$HOME`、XDG、`%APPDATA%`、空格路径）。
3. 现有项目逐个 `--check` → `--fix` 迁移，不默认扫描全盘。

## 5. MEMORY 提炼

> 只放会影响下一家的规则/偏好；不复制记忆原文、不写本机路径/会话 ID；没有写「无」。

- 直接维护：改完跑 `scripts/handoff.sh --save`（提交 + 同步 + 推送重试），不等用户说「提交」；任务收工仍按 `--suspend` 挡位（默认读 `config.toml`）。

## 6. 坑与约束
> 只写会踩的坑与约束；协议级边界见 `SKILL.md` / `DESIGN.md`，本卡不重复；平时可追加，`--suspend` 时归并，≤10 类。

- 安装：`install.sh` 只装 HEAD，工作树未提交时副本仍是上一个 commit；`--syncall` 只从源仓库跑（副本没有 HEAD，硬跑会把副本写成 `commit=unknown`）。
- 注册表：`$AGENT_CONFIG/sync-paths` 是本机安装注册表，`--syncall` 按它对齐副本；换机不带，新机器重建。
- 能力表：固定 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；只在不存在时从模板播种，已存在不覆盖；换机整表复制、只重填「本机环境」块。
- GitHub：有 remote 才生成 `.github/README.md`，会覆盖根 README 首页（预期）。
- 入口 / 发布：`install.sh` 只安装，诊断/同步用 `scripts/handoff.sh`（Windows `scripts/运行时.bat`），不要再给 install.sh 加运行时子命令；包文件（`SKILL.md`、`scripts/`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`）必须留根。
- 工作区文档：`AGENTS.md` / `PROJECT_RULES.md` 缺失时 `--check` 报 🟡，`--fix` 确认后从模板播种；已存在的只报过期。
- 文档：模板不会被 `--check` 校验；改协议或文档结构后手动扫 `assets/*.tpl`，避免模板与正文互相矛盾。
- git：不装钩子；只有 `--push` 会显式推送，`--commit` 只提交 `handoff/`；`--push` 由 `scripts/handoff.sh --push` 重试 3 次 / 3 秒，只重试网络错误；未确认推送成功不写「已推送」。
- 不回到全自动：文件改动无法触发 git（边界禁止常驻服务），没有可靠触发器时全自动=全不自动；与「git 可选」「敏感信息不提交」冲突。`--commit` / `--push` 保留；嫌步骤多只能封成一条显式命令。
- 能力表：验证方法里的参数名必须与脚本实际一致（`--dryrun`、`--syncall`，无中间连字符）；`--check` 只报不修。

## 7. 交接记录（只记关键动作，≤10 条）
> 超出先压卡到 `COMPACT_BACKUP.md`；不写日常细节。

- 2026-11-05 Qoder：`--check` / `--fix` / `--probe --live` 通过；能力表 Qoder 行补 `--dryrun` 与实测方法；CONTEXT 清掉本机副本/探测状态；压卡一条旧记录。
- 2026-11-05 WorkBuddy / Claude：v3.2–v3.10 迭代（入口拆分、`--save` 与挡位、删钩子、归档改名、README 落地页化、压卡/接手清单）；全自动方案不采纳；SKILL 正文审计（`--syncall` 条件、`--printpath` 输出、模板路径、边界措辞）；`--check` 增源仓库正文一致性审计（只报告，不自动改）；按 WorkBuddy 审计修正 `--printpath` 用法串，并写明 `--save` 属脚本层、不在 SKILL/HELP 命令表。详细流水见 [COMPACT_BACKUP.md](COMPACT_BACKUP.md)。
- 2026-11-05 WorkBuddy：压卡沉降一条旧记录；`--suspend --push` 收工并推送前序提交。
- 2026-11-04 Claude：v3.1——迁移语义与 `--syncall` 护栏；能力表路径固定；README 增换机迁移；DESIGN 版本/废弃表收敛。
- 2026-11-04 Claude：文档重整——README 安装/使用分章、DESIGN 完整历程与图表、交接主体统一为 agent、`--printpath` 全量视图、5 份模板对齐；收窄自动提交记忆，`--suspend` 未给 `--push` 时抑制钩子推送；能力表补 `CreateSession` 的 worktree 落点。
- 2026-11-03 Claude：能力表拆「memory 读取」表；DESIGN 版本表补 v2 卸载、v3 评审排在 v3 前。
- 2026-11-03 Claude：钩子防护——`--printpath` 打印 hooksPath，`--check` 校验、`--fix` 恢复；定位 worktree 会话改共享 hooksPath 的坑。
- 2026-11-03 Claude：机器级状态收口——`sync-paths` 迁到 `$AGENT_CONFIG`，仓库内不再留；工作区根能力表副本删除，只留 `$AGENT_CONFIG` 一份；DESIGN 补 5.1.1 与迁移范围。
- 2026-11-03 Claude：V3 文档重整——README 按落地页模板重写；DESIGN 删除进度/待办、已废弃方案移入版本节；CONTEXT 承接待办。
- 2026-11-03 Claude：V3 落地——术语统一、文档迁入 `handoff/`、7 个命令、`config.toml`、能力差异表；删除作者快照与同步脚本；`SKILL.md` 118 行。

## 8. 参考 ID
> 只放可回读的 ID / 路径；不复制历史。

- 无；本卡自包含，细节按 `git log` 与 [COMPACT_BACKUP.md](COMPACT_BACKUP.md) 查。
