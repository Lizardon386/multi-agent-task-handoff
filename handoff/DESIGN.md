# multi-agent-task-handoff（任务交接）· 方案设计

> 面向改这套协议的人：为什么任务文档固定在 `handoff/`、项目与工作区根怎么分、命令如何收敛、宿主差异如何驱动自动化。
> 使用者说明见 [README.md](README.md)，当前进度见 [CONTEXT.md](CONTEXT.md)，协议正文见 [SKILL.md](../SKILL.md)。
> 最近更新：2026-11-03

## 文档

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](README.md) | 使用者 | 这是什么、怎么跑、限制 |
| [DESIGN.md](DESIGN.md) | 评审 / 开发 | 本文件 |
| [CONTEXT.md](CONTEXT.md) | 接手 agent | 当前状态、下一步、坑、验证 |
| `PROMPT.md` | 接手 agent | 交接指针，自动生成，默认 gitignore（不链接） |

## 1. 目标与约束

会话是易失的：换会话、换 agent、换机器，接盘的人只能从目录和上一段会话猜。靠人记会漏，靠常驻强制会拖慢每轮，靠文档自身又会写成日志；所以需要一个目录内、任何 agent 都能读的最小协议。

目标：任务文档固定在项目目录的 `handoff/`；交接只发状态和指针；能自动的自动做，做不到的明确列给用户；宿主差异不写进协议正文。

约束：不装常驻服务、不写全局规则、不调用模型；git 可选；任何 agent 读文件即可介入。

非目标：自动记忆、会话回放、AI 摘要、向量检索、强制合规、命令叠加。

## 2. 术语

| 术语 | 定义 | 不是什么 |
|---|---|---|
| 项目 | 宿主 UI 的工作单元：Claude 项目、Qoder 工作区、WorkBuddy 空间、OpenCode/ZCode/Codex 项目 | 不是 `AGENT_WORKSPACE` |
| 项目目录 | 项目的绝对路径；唯一写入根；可为已打开项目或新建项目目录 | 不是工作区根 |
| 工作区根 | `AGENT_WORKSPACE` 容器；只用来新建项目目录 | 不是写入目标 |
| 当前目录 | `pwd`；可 `cd` | 不改变项目 |

判定：宿主给出打开目录就用它；否则用会话启动时的 `pwd`；打开的目录等于工作区根 / `$HOME` / 盘根 / 临时目录时不算项目，先在工作区根下新建项目目录；不按 git 根自动上溯。

## 3. 运行模式与拓扑

```mermaid
flowchart LR
  H[宿主打开的项目] --> P[项目目录]
  P --> D[handoff/]
  D --> C[CONTEXT.md 状态]
  D --> R[README/DESIGN 文档]
  D --> M[PROMPT.md 指针]
  W[工作区根 AGENT_WORKSPACE] -. 只在无项目时.-> P
  G[$AGENT_CONFIG] --> K[能力差异表 / config.toml / sync-paths / 可选 PROJECT_RULES]
```

## 4. 核心流程

| 命令 | 流程 | 产物 |
|---|---|---|
| `--resume` | PROMPT → CONTEXT →（三档）README/DESIGN → 核锚点/验证 | 无写入 |
| `--suspend` | 按需压卡 → 写 CONTEXT → 覆盖 PROMPT →（有 ID）发指针 | CONTEXT/PROMPT |
| `--doc` | CONTEXT → README/DESIGN → 文档表/日期 →（git）gitignore PROMPT | handoff/ 三档 |
| `--check` | 安装 / 布局 / config / 能力表 / memory / 快照 / PROMPT | 无写入 |
| `--fix` | 检查 → 修可自动项 → 冲突停 → 报告 | 修复项 |
| `--probe` | 检查 → 低成本实测 → 更新能力表；`--live` 实际建会话/发送/读回 | 能力表 |

一次只用一个命令；`--workspace` / `--nosave` 是全局选项。

## 5. 架构与关键接缝

### 5.1 仓库布局

```text
multi-agent-task-handoff/
├─ SKILL.md                 # 协议正文（包文件，必须在根）
├─ install.sh               # 安装：宿主识别、config、--print-paths、--sync-all
├─ 安装.bat                  # Windows 双击入口，调用 install.sh
├─ LICENSE
├─ assets/                  # HELP / 模板 / 示例
├─ .github/README.md        # 由 handoff/README.md 生成
├─ .githooks/post-commit    # 同步安装副本 + 自动 push
├─ .gitignore
└─ handoff/
   ├─ README.md             # 产品/任务 README 源
   ├─ DESIGN.md             # 本文件
   ├─ CONTEXT.md            # 当前状态
   ├─ PROMPT.md             # 自动生成（gitignore）
   └─ 压卡备份.md            # 历史
```

包文件（`SKILL.md`、`install.sh`、`安装.bat`、`assets/`、`LICENSE`、`.githooks/`）必须在根；任务文档进 `handoff/`。

#### 5.1.1 机器级状态统一放 `$AGENT_CONFIG`

按作用域归属，不按文件类型：

| 文件 | 归属 | 位置 |
|---|---|---|
| `config.toml` | 用户/机器偏好 | `$AGENT_CONFIG/` |
| `AGENT_CAPABILITIES.md` | 各宿主能力实测缓存 | `$AGENT_CONFIG/` |
| `sync-paths` | 本机安装目录注册表 | `$AGENT_CONFIG/` |
| `PROJECT_RULES.md` / `AGENTS.md` | 工作区跨任务规则与入口指针 | 工作区根 |
| `handoff/*` | 任务状态 | 项目目录 |

- `$AGENT_CONFIG`：Linux/macOS `${XDG_CONFIG_HOME:-$HOME/.config}/multi-agent-task-handoff`；Windows `%APPDATA%\multi-agent-task-handoff`；可用 `AGENT_CONFIG` 覆盖。
- `sync-paths` 是“一行一个安装目录”的纯文本，由 `install.sh` 追加；`--sync-all` 与 `post-commit` 都读它。
- 旧位置 `<repo>/.skill-sync-paths` 由 `install.sh` / `post-commit` 一次性迁到新位置后删除。
- 三者不合并成一个文件：偏好（低频编辑）、能力缓存（Markdown 表）、注册表（高频追加）的读写方式不同，合并会让 bash 解析变脆。

### 5.2 关键接缝

1. **项目 ↔ 工作区根**：项目目录是写入根；工作区根只建项目目录。
2. **任务文档 ↔ 项目文档**：`handoff/` 是任务文档；根 README/DESIGN 是项目文档，不自动搬。
3. **CONTEXT ↔ PROMPT**：CONTEXT 人维护；PROMPT 自动生成，冲突以 CONTEXT 为准。
4. **能力表 ↔ 自动化**：建会话/绑定目录/切目录/UI 打开/文件迁移/会话搬运分级；未知按手动。
5. **memory ↔ 交接**：只读提升；不复制、不写回；位置与读取方式查能力表「memory 读取」。
6. **生成物 ↔ 真源**：`.github/README.md` 是生成物；源文件是 `handoff/README.md`。

## 6. 关键设计决策

| 决策 | 理由 | 代价 |
|---|---|---|
| 任务文档固定在 `handoff/` | 路径唯一，避免 `docs/` 碰撞和多套兜底 | 不在项目根直接可见，依赖 skill 入口或指针 |
| 项目目录是唯一写入根 | 多仓/AOSP 场景下不会把卡写到工作区根 | 无项目时要先建目录 |
| 工作区根只做容器 | 与“产物根”区分，避免把 `handoff/` 写到容器 | 用户要理解两个概念的区别 |
| 命令一次只用一个 | 组合过长、顺序和冲突难维护 | 需要多步时分开跑 |
| `--doc` 只补文档 | 不建兄弟目录、不迁移代码 | 旧布局要靠 `--fix` 迁移 |
| 交接只发指针 | 跨 agent 不复制聊天历史；PROMPT 可复用 | 目标读不到文件时要附全文 |
| `PROMPT.md` 自动生成并 gitignore | 含会话 ID/本机路径，默认不提交 | 跨机交接要另发内容 |
| 默认不操作 git | commit/push 是外部可见动作 | 要落锚点时必须显式 `--commit`/`--push` |
| 能力表按差异拆分 | 宿主叫法、目录来源、会话能力各不同 | 表多，首次要填 |
| memory 只读提升 | 保持 `CONTEXT.md` 是唯一可移植真源 | 宿主记忆的细节不自动搬运 |
| `.github/README.md` 由 `handoff/README.md` 生成 | GitHub 首页只认 `.github`/根/`docs` | 会覆盖根 README 的首页展示 |
| 安装只认当前宿主 | 不替没打开它的 agent 铺副本 | 换宿主要重跑一次 |

## 7. 已定语义与边界

| 主题 | 约定 |
|---|---|
| 写入根 | 项目目录；工作区根永远不直接写 `handoff/` |
| 文档路径 | `<项目目录>/handoff/{CONTEXT,README,DESIGN,PROMPT,压卡备份}.md` |
| 冲突 | 目标已存在且非本协议生成 → 停，不覆盖、不换路径 |
| 交接卡 | CONTEXT ≤100 行；交接记录 ≤10 条；只记关键动作 |
| PROMPT | 每次覆盖；带生成时间；默认 gitignore；不写真实会话 ID |
| 命令 | 一次一个；`--workspace`/`--nosave` 全局；子参数只跟所属命令 |
| git | 默认不操作；`--commit` 只提交 `handoff/`；`--push` 隐含 commit |
| memory | 只读提升；不复制、不写回；项目内 memory 必须 gitignore |
| GitHub | 有 remote 即生成 `.github/README.md`；无 remote 不生成；不用 symlink |
| 一个写者 | 同一项目同一时间一个会话写；交接后旧会话停写 |
| 跨任务规则 | 项目目录 → 父目录 → `$AGENT_CONFIG/PROJECT_RULES.md` |
| 能力表 | `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；差异表驱动，协议不写宿主分支 |
| 机器级状态 | `config.toml`、`AGENT_CAPABILITIES.md`、`sync-paths` 统一放 `$AGENT_CONFIG`；工作区根只放规则与入口 |
| 迁移范围 | 只迁符合模版的同名任务文档（`CONTEXT` / `README` / `DESIGN` / `压卡备份`）；客制化名文档（`实施方案`、`架构设计` 等）留根，由 `CONTEXT` 的文档表用 `../` 引用 |
| 迁移判定 | root `CONTEXT.md` 存在且 `模式：三档`，或文档带模版特征；产品 README/DESIGN 不动 |
| 完成定义 | 文档与安装副本一致；`--help` 与命令表一致；`--check` 无 ⛔；卡 ≤100 行 |

## 8. 工程约束

- 一次只用一个命令；不提供 `+` / 空格叠加。
- `SKILL.md` 单文件，硬上限 150 行、目标 120；超出才拆 `references/`。
- 协议护栏（冲突停、不搬会话、单写者、memory 只读）必须留在 `SKILL.md`，不能只放 `PROJECT_RULES.md` 或 README。
- 宿主差异只进 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；`SKILL.md` 不写宿主分支。
- 旧仓迁移是逐项目人工动作，不默认扫描全盘；先 `--check` 出清单，再 `--fix`。
- 迁移只动同名标准件；客制化交付文档（大方案、架构稿）不搬，避免移动工程产物和大范围改链。
- `.github/README.md` 覆盖根 README 的首页展示是预期行为；要求项目 README 当首页的仓不适用。
- 安装只装 HEAD；工作树未提交时只装上一个 commit。
- 机器级状态只放 `$AGENT_CONFIG`，不放仓库；仓库里不留 `.skill-sync-paths`。
- worktree 会话可能修改共享的 `core.hooksPath`；`--check` 校验，`--fix` 恢复，不静默接受。

## 9. 版本与设计演进

旧版代码已从工作树删除；这里只留设计演进。2026-10-29 公开发布前用 git-filter-repo 脱敏重写历史，旧哈希失效。

v1→v2 的转折点不是“不要交接”，而是“不要用常驻强制层保证交接”：v1 的闸门/安装器/看门狗保证了文档存在，代价是每轮变慢、文档长成日志；v2 保留交接目标，删掉强制层，默认一份卡，三档改为显式工程化。

### 9.1 版本表

| 版本 | 时间 | 形态 | 理念更替 | 具体措施 |
|---|---|---|---|---|
| v1.0 | 2026-10-08 | 两档 + init/check | 会话易失，先把交接文档落成骨架 | 两档模板；`init-task.sh` 铺骨架；`check-docs.sh` 验收 |
| v1.1 | 2026-10-14 | 三档 + 闸门加严 | 使用说明与设计取舍分开 | 拆出 `DESIGN.md`；加严 `[题]/[空]/[链]`；补中文命名与链接规则 |
| v1.2 | 2026-10-15–16 | 入口模式 + 自动铺满 + 看门狗 | 多 agent/多机分发，靠机械兜底防漂移 | 双锚、出处戳、`-Prune`、`pre-push`、每日看门狗、夹具/变异测试 |
| v1 卸载 | 2026-10-16 | 全部撤掉 | 强制层成本高于收益 | 删三处副本、全局规则、钩子、计划任务 |
| v2 | 2026-10-23 | 默认单档 + 可选工程化/交接 | 从“强制规范”转向“最小协议” | 一任务一卡；`工程化` 升三档；`交接` 只发状态；git 可选 |
| v2.1 | 2026-10-29 | 公开发布 | 对外可用：路径不绑作者机器 | `AGENT_WORKSPACE`；MIT；脱敏重写历史 |
| v2 卸载 | 2026-11-03 | 撤掉根目录三档 | “cwd/任务目录 + 根三档”在多仓/散落仓、Ubuntu 下不成立 | 根三档迁 `handoff/`；命令收敛为 7 个；删作者快照与同步脚本；中文别名保留 |
| v3 评审 | 2026-11-03 | 方案收敛 | 否决 docs/、symlink、会话搬运、命令叠加 | 明细见 9.2 |
| v3 | 2026-11-03 | 项目化 + `handoff/` + 差异表驱动 | 从“cwd 即任务根”转向“项目目录”；工作区根只作容器；宿主差异决定自动化程度；会话不搬运 | 术语统一；`handoff/`；7 个命令；`config.toml`；能力差异表；`.github` 快照；memory 只读提升 |

### 9.2 已废弃方案

| 废弃方案 | 否决原因 | 替代 |
|---|---|---|
| 工作区/工作区根 = 宿主打开的文件夹；草稿根 = `AGENT_WORKSPACE` | 与“工作区根 = `AGENT_WORKSPACE` 容器”的最终定义冲突（16:43 评审第 1 条被 17:45 纠正推翻） | 项目目录 = 写入根；工作区根 = `AGENT_WORKSPACE` 容器 |
| agent 主动打开文件夹并迁移会话 | 多数宿主不支持搬运活会话 | 新建会话 + `PROMPT.md` 指针 |
| `docs/` / `docs/handoff/` | 与项目自有 docs 冲突；GitHub 识别路径不稳定 | 固定 `handoff/` |
| 根 README 生成 | 会与项目自己的根 README 冲突 | 有 GitHub remote 时生成 `.github/README.md` |
| `.github` symlink | Windows 不稳定；会抢项目首页；相对链接易坏 | 生成 `.github/README.md` |
| `--coding` | 名字容易被理解为“开编码目录” | `--doc` |
| 命令叠加 | 命令过长、顺序和冲突难维护 | 一次只用一个命令 |
