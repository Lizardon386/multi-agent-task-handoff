# multi-agent-task-handoff · 使用说明

> 面向使用者：这里既是 `D:\agent_workspace` 的文档合规工具与骨架模板，**也是这套 skill 自己的 git 工作树（真源）**。
> 任务进度与遗留问题见同目录 `CONTEXT.md`，设计取舍见 `DESIGN.md`，工作区规矩全文见上一级的 `AGENTS.md`。
> 最近更新：2026-10-14

## 一句话说明

用两个脚本把「每个任务目录都要有 README.md + DESIGN.md + CONTEXT.md」这条规矩变成**可执行、可自检**的约束：`init-task.sh` 开新任务时铺骨架，`check-docs.sh` 收工时验收。

> **2026-10-14 起真源搬到这里**：`.git` 从 `~/.qoder-cn/skills/multi-agent-task-handoff\` 移进了本目录，各 agent 的 skills 目录降级成**下游副本**。改逻辑就在本目录改 → `git commit` + `git push` → 跑 `scripts/install-everywhere.ps1` 铺满。反过来在 skills 目录里改，下次铺满会被静默覆盖。


## 方案设计

设计取舍（决策 / 理由 / 代价 全表，含 2026-10-14 三档拆分与 DESIGN 豁免的取舍）、四个脚本之间的接缝、哪些约定是动不得的契约，都在同目录 [DESIGN.md](DESIGN.md)。

## 快速开始

```bash
cd D:/agent_workspace
bash multi-agent-task-handoff/scripts/init-task.sh my-new-task   # 建任务目录 + README/CONTEXT 骨架
bash multi-agent-task-handoff/scripts/check-docs.sh              # 全量验收；末尾带任务名可只查一个
```

## 使用说明

| 操作 | 命令 |
|---|---|
| 新建任务并铺骨架 | `bash multi-agent-task-handoff/scripts/init-task.sh <任务名>`（目录已存在则只补缺失的 md，不覆盖） |
| 全量合规检查 | `bash multi-agent-task-handoff/scripts/check-docs.sh` |
| 只查一个任务 | `bash multi-agent-task-handoff/scripts/check-docs.sh uno-online` |
| 换一个工作区根 | `bash multi-agent-task-handoff/scripts/check-docs.sh --root E:/other_ws`（或 `export AGENT_WS_ROOT=...`；默认取脚本所在副本目录的上级，副本目录认新名 `multi-agent-task-handoff` 与旧名 `tools`，都不在时退化为 `D:/agent_workspace`） |
| 收紧"过期"判定 | `STALE_DAYS=7 bash multi-agent-task-handoff/scripts/check-docs.sh` |
| 把规矩装进新工作区 | `bash scripts/bootstrap.sh --root <新根>`（在本目录跑；幂等；`--force` 才覆盖已有脚本。目标目录就是本目录时自动跳过自铺） |
| **改完真源铺满本机** | `powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent_workspace\multi-agent-task-handoff\scripts\install-everywhere.ps1"`（铁律「更新即铺满」；铺所有 agent 技能目录 + 全局规则块 + 各工作区的脚本副本目录。**先 commit + push 再铺**） |
| 改章节要求 | 改本仓库的 `scripts/check-docs.sh` 三个 `*_SECTIONS` + `assets/*.tpl` + `references/agents-rule.md` 三处，缺一不可 |

退出码：`0` 全绿；`1` 有缺项。前缀含义：`[缺]` 三档文件不存在（DESIGN 可由 `架构设计.md` 这类方案设计交付文档承担，此时打印 `[档]`）、`[构]` 缺章节、`[占]` 模板占位符、`[题]` H1 标题不含任务目录名（中文名写成 `# 目录名（别名）· 使用说明` 就过）、`[空]` 骨架未填（**三档任一表格留全空行**都算；DESIGN「设计思路」的三列表**任一格留空**也算）、`[链]` 「产物与目录」缺可点击链接（`file:///` 与相对链接都算）**或链接指向不存在的文件**（两种形式都验）、`[名]` 顶层输出 `.md` 用了纯 ASCII 文件名（四个固定名豁免）、`[期]` **三档**「最近更新」日期不一致、`[新]` 缺「最近更新」、`[旧]` 更新超期。`[档]` 与 `[旧]` 不影响退出码，其余全是失败项。跑它的时候**别加管道**（`| tail`、`| grep`），只看结尾那行 `OK` 会把违规行吃掉。

**约定检查时机**：任何 agent 改完本工作区产物后、结束会话前跑一次 `check-docs.sh`，退出码 0 才算收尾。

## 产物与目录

| 文件 | 用途 |
|---|---|
| [init-task.sh](scripts/init-task.sh) | 建任务目录 + 铺三档骨架（skill 同步副本） |
| [check-docs.sh](scripts/check-docs.sh) | 三档合规检查（skill 同步副本） |
| [bootstrap.sh](scripts/bootstrap.sh) | 安装/重同步器（skill 同步副本，留着是为了工作区自己也能铺） |
| [install-everywhere.ps1](scripts/install-everywhere.ps1) | 铁律「更新即铺满」的执行工具（skill 同步副本；2026-10-12 起会被它自己铺进来） |
| [templates/README.md.tpl](assets/README.md.tpl) | 使用者文档骨架 |
| [templates/DESIGN.md.tpl](assets/DESIGN.md.tpl) | 方案设计骨架（决策/理由/代价三列表） |
| [templates/CONTEXT.md.tpl](assets/CONTEXT.md.tpl) | agent 交接档案骨架 |
| [README.md](README.md) | 本目录使用者文档（范例） |
| [DESIGN.md](DESIGN.md) | 本目录方案设计：工具自己的取舍表、四个脚本之间的接缝、哪些约定是动不得的契约（范例） |
| [CONTEXT.md](CONTEXT.md) | 本目录交接档案（范例） |
| [AGENTS.md](../AGENTS.md) | 工作区规矩全文，含「产物链接（强制）」一节 |

**真源就是本目录**（skill 仓库的 git 工作树）：[SKILL.md](SKILL.md)、[check-docs.sh](scripts/check-docs.sh)、[bootstrap.sh](scripts/bootstrap.sh)、[install-everywhere.ps1](scripts/install-everywhere.ps1)。`~/.qoder-cn\skills\`、`~\.codex\skills\`、`~\.claude\skills\` 下那份都是**下游副本**——改逻辑一律在这里改，`git commit` + `git push` 后跑铺满，否则下次铺满会把你在副本里改的东西静默覆盖掉。

依赖：bash（Git Bash / Linux / macOS 任一）+ POSIX 常用工具（`grep`、`awk`、`sed`、`find`）。2026-10-14 起**不再依赖 GNU `date -d`**——过期天数改成纯 bash 算法，BSD/macOS 的 `date` 也能跑。无网络、无外部依赖。

## 限制与注意事项

- `check-docs.sh` 只校验**结构与是否留空**，不判断内容质量；正确的标题配空话照样通过。这是刻意的弱校验（见 `DESIGN.md` 的取舍表）。
- 必须在 bash 里跑（Windows 用 Git Bash）：整个脚本是 bash，纯 cmd/PowerShell 下没有对应实现——**这是有意的**，两套判定逻辑必然漂移。日期计算本身已不依赖 GNU `date -d`。
- 一级子目录**除 `templates`/`node_modules`/`.git` 外都被要求三档**：临时放个截图目录也会被拦，这是有意的。脚本副本目录（`multi-agent-task-handoff` / 旧名 `tools`）**按内容判**——只有脚本时跳过，一旦铺了三档就照任务目录检查。
- 章节匹配用 `grep -qE "^## +.*<节名>"` 子串匹配，正文里出现同名普通二级标题会被误判为"该节已存在"。
- `[链]` 的可达性校验**只查指向本工作区内部的链接**，指向 `$ROOT` 之外的一律跳过。原因是脚本会发给别人，对方机器没有 `D:` 盘，不跳过就会全线误报。代价：写到工作区外的链接（如 `C:\Users\…`）不受保护。
- **相对链接按文档自身所在目录解析后同样验可达**（2026-10-14）。但可达性只在本机成立：README 推到 GitHub 后，`file:///` 死链闸门照样放行——它验不了别人机器上的路径，这一层只能靠写的人自己按读者选形式。
- **提取链接前先剥掉 ```` ``` ```` 代码围栏和行内 `` `code` `` **（围栏是先有的，行内代码 2026-10-14 补上）：示例代码里的 C++ lambda `[this](Status result)` 会被 `](...)` 误认成链接，在 `dsp-hal-eval/架构设计.md` 上真误报过一次；本目录三份文档用行内反引号举同一个反例，也被自己判红了 4 条。反引号配对按**等长 run** 处理，不是简单成对匹配——写 ```` ```` ``` ```` `` 这种"反引号套反引号"的例子时成对匹配会配错位、剩下的 span 漏出来。代价：行内代码与围栏里的真链接同样不验，产物链接本就不该写在代码里。display 名带反引号的合法链接（反引号 + 方括号名 + 反引号 + 圆括号目标那种写法）先解开再验，不会被剥掉。
- `[链]` 判前会先剥掉 HTML 注释：模板在注释和表头里写了 `file:///` 示例，不剥的话空表格也会"命中链接"通过。表头同理不能留字面示例。（2026-10-10 修掉的自造假绿灯。）
- 顶部日期只认 `> 最近更新：YYYY-MM-DD` 这一行（`^> ` 锚定）。2026-10-10 前不锚定，实测有"顶部漏日期、正文带日期"的文档被 `head -1` 拿正文那行当顶部日期，`[新]` 不触发、整个闸门判 OK 放过——静默漏检比报错危险。
- `init-task.sh` 只补不覆盖，没有 `--force`；要重来请手动删对应 md。`--force` 只在 `bootstrap.sh` 里，且只作用于脚本副本目录下的脚本与模板，不碰任务目录。
- 脚本不做删除、不跑 git——它是脚手架与闸门，不是清理工具。
