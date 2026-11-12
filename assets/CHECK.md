# 检查清单（--check / --fix）

> 用途：固定 `--check` / `--fix` 的逐项检查，避免自由裁量和漏检；输出即动作记录，不额外写日志。
> 执行：`--check` 只读，逐项输出 `[OK]` / `[WARN]` / `[SKIP]`；`--fix` 只修标记「可修」的项，其余只报告；默认不提交。
> 最近更新：2026-11-12

## 输出格式

```text
[OK]   C01 安装副本：6 份全部当前
[WARN] C05 能力表：当前宿主仍有待测 P 项 L104
[SKIP] C11 源仓库一致性：非源仓库
[OK]   C13 模板通用性：项目文档模板无专属命令
```

## 检查项

| ID | 检查 | 命令 / 判定 | --fix |
|---|---|---|---|
| C01 | 安装副本 | `--printpath`；所有副本 commit = HEAD | 可修：源仓库跑 `--syncall` |
| C02 | 文档布局与 scope | 根 README、`docs/`、`handoff/` 标记与目录一致；无 `.github/README.md`、`docs/README.md` | 只报告：跑 `--doc` |
| C03 | 链接 | 文档表与章节链接可达；迁移链接无断 | 只报告 |
| C04 | config / workspace | `--printpath` 配置存在、workspace 来源明确 | 可修：缺失时从模板创建/补键 |
| C05 | 能力表 | 存在、日期、当前宿主待测格 | 只报告：跑 `--probe` |
| C06 | sync-paths | 注册表存在、条数可读 | 只报告：跑 `install.sh` |
| C07 | PROMPT 忽略/跟踪 | `git check-ignore` 命中；`git ls-files` 为空 | 可修：补 `.gitignore` / `git rm --cached` |
| C08 | 项目内 memory | 项目内 memory 已 gitignore | 只报告 |
| C09 | CONTEXT 限额 | ≤100 行、记录 ≤10、坑 ≤10 | 只报告：`--suspend` 压卡 |
| C10 | 工作区文档 | `AGENTS.md` / `PROJECT_RULES.md` 存在；AGENTS 只做入口指针并指向 PROJECT_RULES；PROJECT_RULES 指向 `$AGENT_CONFIG` 与 `handoff/` | 可修：确认后从 `assets/AGENTS.md.tpl` / `assets/PROJECT_RULES.md.tpl` 播种 |
| C11 | 源仓库一致性 | SKILL / HELP / COMMANDS / 模板 / examples 的命令、签名、路径一致 | 只报告（非源仓库 SKIP） |
| C12 | probe 完成度 | 当前宿主能力表必测格无「待测」；缺失/策略阻止有 ⛔/🟡 + 证据 | 只报告：跑 `--probe` |
| C13 | 模板通用性 | README / DESIGN / COMMANDS / CONTEXT / PROMPT 模板不含本 skill 专属命令、脚本路径、宿主名；专属内容用 `<占位符>`；允许 `handoff/`、`docs/`、scope 标记与 `--suspend` | 只报告 |

## 完成

- 每项必须有 `[OK]` / `[WARN]` / `[SKIP]` 之一，不能省略（C01–C13）。
- `[WARN]` 写触发项与下一步命令；`[SKIP]` 写原因。
- `--fix` 只执行 C01 / C04 / C07 / C10 的「可修」动作；其余只报告。
- 非源仓库跳过 C11；文档整理项一律只报告「需跑 `--doc`」；内容过时走普通编辑，不归 `--doc`。
