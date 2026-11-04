# multi-agent-task-handoff · 上下文与进展

> V3.1 已落地并推送（`6586df9`）；文档与模板已对齐；5 份副本同步；待双平台验证、WorkBuddy 复验与旧项目迁移。
> 最近更新：2026-11-04
> 模式：三档
> 项目目录：`D:\agent_workspace\multi-agent-task-handoff`
> 状态锚点：`git log -1 --oneline`（当前 `6586df9`）；推 GitHub 前 `gh auth status`
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

- 目标：V3.1 协议落地；任务文档固定在 `handoff/`；宿主差异由能力表驱动；交接只发指针。
- 完成标准（可验证）：`SKILL.md` / `README.md` / `DESIGN.md` 与安装副本一致；8 个命令与 `--help` 一致；`--check` 无 ⛔；`CONTEXT.md` ≤100 行；`install.sh --dry-run` / `--printpath` / `--syncall` 正常。

## 现在在哪

- 已完成：
  - V3 协议与 `handoff/` 布局；8 个命令；`config.toml`；能力差异表；memory 只读。
  - v3.1：`--syncall` 改名并只允许从源仓库运行；迁移语义（能力表可搬、`sync-paths` 不带）；`--printpath` 显示宿主来源、能力表日期与全部副本状态。
  - 文档重整：README 安装/使用分章并补换机迁移；DESIGN 完整历程、版本表收敛、废弃表补全；交接主体统一为 agent；5 份模板对齐。
  - 安装副本 5 份（Qoder / OpenCode / ZCode / WorkBuddy / Claude）同步到 `6586df9`。
  - 推送状态以 `git status -sb` 为准（网络异常时可能 ahead）。
- 进行中：无代码改动。
- 在飞文件（勿动）：无。

## 下一步

1. 双平台往返测试：临时 git 项目跑 `--resume` → `--suspend` → `--resume`，再跑 `--doc`、`--check`、`--fix`、`--probe`。
2. 非 git 项目、Windows Git Bash、Ubuntu 路径测试（`$HOME`、XDG、`%APPDATA%`、空格路径）。
3. 现有项目逐个 `--check` → `--fix` 迁移，不默认扫描全盘。
4. WorkBuddy 5.9.x 复验：配置目录 `~/.workbuddy`、memory 在 `~/.workbuddy/memory/`（用户级单文件）；确认投递/读回是否变化。
5. 每次提交前跑 `--check`，核对 `core.hooksPath` 和副本状态（worktree 会话后尤其要查）。

## 坑与约束

协议级边界（写入根、任务文档位置、迁移范围、单写者、`PROMPT`、git、memory）见 `SKILL.md` 与 `DESIGN.md` 第 7 节，本卡不重复。平时可追加；`--suspend` 时归并，同类合并、删重复，类别 ≤10。

- 钩子：worktree 会话可能把共享 `core.hooksPath` 改成 `.git/hooks`，提交时钩子静默不跑；提交前 `--check` 看，`--fix` 恢复。
- 安装：`install.sh` 只装 HEAD，工作树未提交时副本仍是上一个 commit；`--syncall` 只从源仓库跑（副本没有 HEAD，硬跑会把副本写成 `commit=unknown`）。
- 注册表：`$AGENT_CONFIG/sync-paths` 是本机安装注册表，提交后 `post-commit` 自动对齐；换机不带，新机器重建。
- 能力表：固定 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；只在不存在时从模板播种，已存在不覆盖；换机整表复制、只重填「本机环境」块。
- GitHub：有 remote 才生成 `.github/README.md`，会覆盖根 README 首页（预期）。
- 发布：包文件（`SKILL.md`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`、`.githooks/`）必须留根。
- 工作区文档：`AGENTS.md` / `PROJECT_RULES.md` 缺失时 `--check` 报 🟡，`--fix` 确认后从模板播种；已存在的只报过期。
- 文档：模板不会被 `--check` 校验；改协议或文档结构后手动扫 `assets/*.tpl`，避免模板与正文互相矛盾。
- git：`post-commit` 默认自动 push；`--suspend --commit` 没给 `--push` 时必须设 `SKIP_AUTO_PUSH=1`，否则会把提交推上去。

## 交接记录（只记关键动作，≤10 条）

- 2026-11-04 Claude：v3.1——迁移语义与 `--syncall` 护栏；能力表路径固定；README 增换机迁移；DESIGN 版本/废弃表收敛。
- 2026-11-04 Claude：文档重整——README 安装/使用分章、DESIGN 完整历程与图表、交接主体统一为 agent、`--printpath` 全量视图、5 份模板对齐；已推 `6586df9`；收窄自动提交记忆，`--suspend` 未给 `--push` 时抑制钩子推送。
- 2026-11-03 Claude：能力表拆「memory 读取」表；DESIGN 版本表补 v2 卸载、v3 评审排在 v3 前；4 份副本随提交同步。
- 2026-11-03 Claude：钩子防护——`--printpath` 打印 hooksPath，`--check` 校验、`--fix` 恢复；定位 worktree 会话改共享 hooksPath 的坑。
- 2026-11-03 Claude：机器级状态收口——`sync-paths` 迁到 `$AGENT_CONFIG`，仓库内不再留；工作区根能力表副本删除，只留 `$AGENT_CONFIG` 一份；DESIGN 补 5.1.1 与迁移范围。
- 2026-11-03 Claude：V3 文档重整——README 按落地页模板重写；DESIGN 删除进度/待办、已废弃方案移入版本节；CONTEXT 承接待办。
- 2026-11-03 Claude：V3 落地——术语统一、文档迁入 `handoff/`、7 个命令、`config.toml`、能力差异表；删除作者快照与同步脚本；`SKILL.md` 118 行。
- 2026-10-30 WorkBuddy：收尾写实——三条坑（自动 push、副本同步、验证方法）改成实测表述；验证钩子勿用管道。
- 2026-10-30 WorkBuddy：加 workbuddy 宿主；能力表补 WorkBuddy 行；`.workbuddy-ai/` 进 gitignore。
- 2026-10-30 WorkBuddy：能力表拆两张；PROJECT_RULES 定「宿主差异只进能力表」。

## 参考 ID

- 无；本卡自包含，细节按 `git log` 与 [压卡备份.md](压卡备份.md) 查。
