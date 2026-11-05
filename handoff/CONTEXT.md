# multi-agent-task-handoff · 上下文与进展

> V3.2 已落地并推送；机械动作收归 `--suspend` 显式执行，不再依赖提交钩子；待双平台往返测试与旧项目迁移。
> 最近更新：2026-11-05
> 模式：三档
> 项目目录：`D:\agent_workspace\multi-agent-task-handoff`
> 状态锚点：`git log -1 --oneline`；推 GitHub 前 `gh auth status`
> 验证命令：`git status -sb`；`bash install.sh --dry-run`；`bash install.sh --printpath`；`bash install.sh --syncall --dry-run`

## 文档

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](README.md) | 使用者 | 这是什么、怎么跑、限制 |
| [DESIGN.md](DESIGN.md) | 评审 / 开发 | 目标、架构、流程、决策 |
| [CONTEXT.md](CONTEXT.md) | 接手 agent | 当前状态、下一步、坑（本文） |
| `PROMPT.md` | 接手 agent | 交接指针，自动生成，默认 gitignore（不链接） |
| [压卡备份.md](压卡备份.md) | 追溯 | 状态历史、逐条变更 |
| [../SKILL.md](../SKILL.md) | agent | 协议正文 |
| [../assets/HELP.txt](../assets/HELP.txt) | 使用者 | 完整 `--help` |

## 目标与完成定义

- 目标：V3.2 协议落地；任务文档固定在 `handoff/`；宿主差异由能力表驱动；交接只发指针；机械动作由显式命令执行。
- 完成标准（可验证）：`SKILL.md` / `README.md` / `DESIGN.md` 与安装副本一致；8 个命令与 `--help` 一致；`--check` 无 ⛔；`CONTEXT.md` ≤100 行；`install.sh --dry-run` / `--printpath` / `--syncall` 正常。

## 现在在哪

- 已完成：
  - V3 协议与 `handoff/` 布局；8 个命令；`config.toml`；能力差异表；memory 只读。
  - v3.1：`--syncall` 改名并只允许从源仓库运行；迁移语义（能力表可搬、`sync-paths` 不带）；`--printpath` 显示宿主来源、能力表日期与全部副本状态。
  - v3.2：副本同步与 push 收归 `--suspend` 显式执行；`post-commit` 降级为可选加速、不再自动 push；`core.hooksPath` 不再是必需状态。
  - v3.2 后续：评估「全自动化 + 删 `--commit`/`--push`」后不采纳，理由记入「坑与约束」；一条显式封装命令列为候选，未实施。
  - 文档重整：README 安装/使用分章并补换机迁移；DESIGN 完整历程、版本表收敛、废弃表补全；交接主体统一为 agent；5 份模板对齐。
  - 安装副本 5 份（Qoder / OpenCode / ZCode / WorkBuddy / Claude）同步到当前 HEAD。
  - Claude `--probe --live` 通过：`CreateSession` 投递、`ReadSession` 读回；能力表补 `workDir` 落 worktree 的实测结论。
  - WorkBuddy `--probe --live` 通过：前台子会话投递、同步读回，回传内容一致，无残留。
  - 推送状态以 `git status -sb` 为准（网络异常时可能 ahead）。
- 进行中：无代码改动。
- 在飞文件（勿动）：无。

## 下一步

1. 双平台往返测试：临时 git 项目跑 `--resume` → `--suspend` → `--resume`，再跑 `--doc`、`--check`、`--fix`、`--probe`。
2. 非 git 项目、Windows Git Bash、Ubuntu 路径测试（`$HOME`、XDG、`%APPDATA%`、空格路径）。
3. 现有项目逐个 `--check` → `--fix` 迁移，不默认扫描全盘。

## 坑与约束

协议级边界（写入根、任务文档位置、迁移范围、单写者、`PROMPT`、git、memory）见 `SKILL.md` 与 `DESIGN.md` 第 7 节，本卡不重复。平时可追加；`--suspend` 时归并，同类合并、删重复，类别 ≤10。

- 钩子：`post-commit` 只是可选加速；worktree 会话可能改共享 `core.hooksPath` 让它静默不跑，但副本同步与 push 由 `--suspend` 显式执行，不影响正确性。
- 安装：`install.sh` 只装 HEAD，工作树未提交时副本仍是上一个 commit；`--syncall` 只从源仓库跑（副本没有 HEAD，硬跑会把副本写成 `commit=unknown`）。
- 注册表：`$AGENT_CONFIG/sync-paths` 是本机安装注册表，`--suspend` 与可选 `post-commit` 按它对齐副本；换机不带，新机器重建。
- 能力表：固定 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；只在不存在时从模板播种，已存在不覆盖；换机整表复制、只重填「本机环境」块。
- GitHub：有 remote 才生成 `.github/README.md`，会覆盖根 README 首页（预期）。
- 发布：包文件（`SKILL.md`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`、`.githooks/`）必须留根。
- 工作区文档：`AGENTS.md` / `PROJECT_RULES.md` 缺失时 `--check` 报 🟡，`--fix` 确认后从模板播种；已存在的只报过期。
- 文档：模板不会被 `--check` 校验；改协议或文档结构后手动扫 `assets/*.tpl`，避免模板与正文互相矛盾。
- git：钩子不自动 push；只有 `--push` 会显式推送，`--commit` 只提交 `handoff/`。
- 不回到全自动：文件改动无法触发 git（边界禁止常驻服务），钩子失效时全自动=全不自动且无兜底；与「git 可选」「敏感信息不提交」冲突。`--commit` / `--push` 保留；嫌步骤多只能封成一条显式命令。

## 交接记录（只记关键动作，≤10 条）

- 2026-11-05 WorkBuddy：v3.2 落地并推送；全自动方案评估后不采纳（理由见坑）；本次 `--suspend --push` 走显式 push + `--syncall` 收工。
- 2026-11-05 WorkBuddy：`--probe --live` 实测通过；压卡沉降一条旧记录；`--suspend --push` 收工并推送前面未推的提交。
- 2026-11-04 Claude：v3.1——迁移语义与 `--syncall` 护栏；能力表路径固定；README 增换机迁移；DESIGN 版本/废弃表收敛。
- 2026-11-04 Claude：文档重整——README 安装/使用分章、DESIGN 完整历程与图表、交接主体统一为 agent、`--printpath` 全量视图、5 份模板对齐；收窄自动提交记忆，`--suspend` 未给 `--push` 时抑制钩子推送；Claude `--probe --live` 通过，能力表补 `CreateSession` 的 worktree 落点。
- 2026-11-03 Claude：能力表拆「memory 读取」表；DESIGN 版本表补 v2 卸载、v3 评审排在 v3 前；4 份副本随提交同步。
- 2026-11-03 Claude：钩子防护——`--printpath` 打印 hooksPath，`--check` 校验、`--fix` 恢复；定位 worktree 会话改共享 hooksPath 的坑。
- 2026-11-03 Claude：机器级状态收口——`sync-paths` 迁到 `$AGENT_CONFIG`，仓库内不再留；工作区根能力表副本删除，只留 `$AGENT_CONFIG` 一份；DESIGN 补 5.1.1 与迁移范围。
- 2026-11-03 Claude：V3 文档重整——README 按落地页模板重写；DESIGN 删除进度/待办、已废弃方案移入版本节；CONTEXT 承接待办。
- 2026-11-03 Claude：V3 落地——术语统一、文档迁入 `handoff/`、7 个命令、`config.toml`、能力差异表；删除作者快照与同步脚本；`SKILL.md` 118 行。
- 2026-10-30 WorkBuddy：收尾写实——三条坑（自动 push、副本同步、验证方法）改成实测表述；验证钩子勿用管道。

## 参考 ID

- 无；本卡自包含，细节按 `git log` 与 [压卡备份.md](压卡备份.md) 查。
