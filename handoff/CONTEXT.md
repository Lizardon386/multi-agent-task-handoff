# multi-agent-task-handoff · 上下文与进展

> V3 协议落地中：任务文档已迁入 `handoff/`，命令与模板已改，待做双平台验证与旧项目迁移。
> 最近更新：2026-11-03
> 模式：三档
> 项目目录：`D:\agent_workspace\multi-agent-task-handoff`
> 状态锚点：`git log -1 --oneline`；推 GitHub 前 `gh auth status`
> 验证命令：`git status -sb`；`bash install.sh --dry-run`；`bash install.sh --print-paths`；`bash install.sh --sync-all --dry-run`

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

- 目标：V3 协议落地；任务文档固定在 `handoff/`；宿主差异由能力表驱动；交接只发指针。
- 完成标准（可验证）：`SKILL.md` / `README.md` / `DESIGN.md` 与安装副本一致；7 个命令与 `--help` 一致；`--check` 无 ⛔；`CONTEXT.md` ≤100 行；`install.sh --dry-run` / `--print-paths` / `--sync-all` 正常。

## 现在在哪

- 已完成：
  - `SKILL.md` 重写为 V3（118 行）：7 个命令、术语、`handoff/`、配置、memory、GitHub 边界。
  - 任务文档迁入 `handoff/`：README / DESIGN / CONTEXT / 压卡备份；PROMPT 由 `--suspend` 生成，默认 gitignore。
  - `install.sh`：`--print-paths`、创建 `$AGENT_CONFIG/config.toml`、`.skill-version` 写 `source=`；默认工作区根改 `$HOME/agent_workspace`。
  - 能力表模板改成「Agent 能力与宿主差异表」，新增「项目 / 宿主术语」「项目目录操作」两张表。
  - 删除 `作者实机调研/` 与 `sync-作者实机调研.sh`；`post-commit` 去掉快照同步。
  - 生成 `.github/README.md`（由 `handoff/README.md` 生成）。
- 进行中：无代码改动。
- 在飞文件（勿动）：无。

## 下一步

1. 双平台往返测试：临时 git 项目跑 `--resume` → `--suspend` → `--resume`，再跑 `--doc`、`--check`、`--fix`、`--probe`。
2. 非 git 项目、Windows Git Bash、Ubuntu 路径测试（`$HOME`、XDG、`%APPDATA%`、空格路径）。
3. 现有项目逐个 `--check` → `--fix` 迁移，不默认扫描全盘。
4. WorkBuddy memory 读取方式实测；其余能力表待测项用 `--probe` 补。
5. 安装副本切到 V3：提交后跑 `bash install.sh --sync-all`，`diff -r` 比对 4 份副本。

## 坑与约束

- 项目目录是唯一写入根；工作区根只用来新建项目目录，永远不直接写 `handoff/`。
- 任务文档只在 `<项目目录>/handoff/`；项目自己的 README/DESIGN/docs 不自动搬。
- 旧布局迁移只动同名标准件（CONTEXT/README/DESIGN/压卡备份）；客制化名文档（实施方案/架构设计）留根，由文档表 `../` 引用。
- 一个项目同一时间一个写者；交接后旧会话停写。
- `PROMPT.md` 默认 gitignore；含会话 ID/本机路径，不提交。
- 默认不操作 git；`--commit` 只提交 `handoff/`，`--push` 隐含 commit；失败留本地。
- memory 只读提升；不复制、不写回；项目内 memory 必须 gitignore。
- 有 GitHub remote 才生成 `.github/README.md`；它会覆盖根 README 的首页展示，属预期行为。
- 包文件（`SKILL.md`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`、`.githooks/`）必须留根。
- `install.sh` 只装 HEAD：工作树未提交时，安装副本仍是上一个 commit。
- worktree 会话可能把共享的 `core.hooksPath` 改成 `.git/hooks`，导致提交时钩子静默不跑；提交前 `--check` 看钩子，`--fix` 可恢复。
- 安装注册表在 `$AGENT_CONFIG/sync-paths`（旧仓库内 `.skill-sync-paths` 已迁走并删除）；提交后补跑 `bash install.sh --sync-all`。
- 能力表只在 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；工作区根副本已删，不再双份。

## 交接记录（只记关键动作，≤10 条）

- 2026-11-03 Claude：机器级状态收口——`sync-paths` 迁到 `$AGENT_CONFIG`，仓库内不再留；工作区根能力表副本删除，只留 `$AGENT_CONFIG` 一份；DESIGN 补 5.1.1 与迁移范围。
- 2026-11-03 Claude：V3 文档重整——README 按落地页模板重写；DESIGN 删除进度/待办、已废弃方案移入版本节；CONTEXT 承接待办。
- 2026-11-03 Claude：V3 落地——术语统一、文档迁入 `handoff/`、7 个命令、`config.toml`、能力差异表；删除作者快照与同步脚本；`SKILL.md` 118 行。
- 2026-10-30 WorkBuddy：收尾写实——三条坑（自动 push、副本同步、验证方法）改成实测表述；验证钩子勿用管道。
- 2026-10-30 WorkBuddy：加 workbuddy 宿主；能力表补 WorkBuddy 行；`.workbuddy-ai/` 进 gitignore。
- 2026-10-30 WorkBuddy：能力表拆两张；PROJECT_RULES 定「宿主差异只进能力表」。
- 2026-10-29 ZCode：`install.sh` 加 ZCode 宿主；本机副本增至三份。
- 2026-10-29 ZCode：交接投递按能力表本行选手段；参考 ID 定为 `宿主:ID` 格式。
- 2026-10-29 OpenCode：SKILL description 用自然句含触发词；README 补显式调用说明。
- 2026-10-29 Qoder：公开发布——MIT、`AGENT_WORKSPACE`、脱敏重写历史。

## 参考 ID

- 无；本卡自包含，细节按 `git log` 与 [压卡备份.md](压卡备份.md) 查。
