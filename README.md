# multi-agent-task-handoff · 使用说明

> 给「一个根目录下按任务建子目录」的 agent 工作区，强制一套**可自检**的任务交接规矩：每个任务目录同时维护 `README.md`（使用者）、`DESIGN.md`（方案评审者）、`CONTEXT.md`（下一个 agent）三档，外加骨架生成、合规闸门、以及把整套规矩装到任意工作区的一条命令。
> 标识 `multi-agent-task-handoff`，Qoder / Claude Code / Codex 的用户级 Skill。
> **本目录同时是这个仓库的 git 工作树（真源）**——`D:\agent_workspace\multi-agent-task-handoff\`；`~\.qoder-cn\skills\`、`~\.codex\skills\`、`~\.claude\skills\` 三处是下游副本。
> 设计取舍见 [DESIGN.md](DESIGN.md)，进度与**对外更新记录**见 [CONTEXT.md](CONTEXT.md)，工作区规矩全文见 [../AGENTS.md](../AGENTS.md)。
> 最近更新：2026-10-14

## 一句话说明

会话是易失的：换会话、换 agent、换机器之后，接手的人只能从目录列表猜意图，猜错就返工。三档各管一段——`DESIGN.md` 存「为什么这么设计」（避免同一件事反复重议），`CONTEXT.md` 存「到哪了、还剩什么、有什么坑」（避免重复劳动和踩已知坑），`README.md` 存「这是什么、怎么跑」。

规矩只写成条文没用：agent 冷启动不一定读到，读到了也不一定执行。所以这套东西的形态是**脚本 + 退出码**——`init-task.sh` 铺骨架，`check-docs.sh` 验收，不执行就被闸门拦下。

## 快速开始

```bash
# 1) 装 skill（Qoder 示例；Claude Code 换成 ~/.claude/skills/，Codex 换成 ~/.codex/skills/）
git clone https://github.com/Lizardon386/multi-agent-task-handoff.git ~/.qoder-cn/skills/multi-agent-task-handoff

# 2) 把规矩装进一个工作区（规则块 + 脚本 + 模板，幂等）
bash ~/.qoder-cn/skills/multi-agent-task-handoff/scripts/bootstrap.sh --root <工作区根>

# 3) 开新任务 / 收工验收
bash <工作区根>/multi-agent-task-handoff/init-task.sh my-new-task
bash <工作区根>/multi-agent-task-handoff/check-docs.sh          # exit 0 才算这次会话收工
```

装完验证一次（第二条**应该**报错——拦空骨架就是它的职责）：

```bash
bash <工作区根>/multi-agent-task-handoff/check-docs.sh --root <工作区根>   # exit 0 = 闸门可用
bash <工作区根>/multi-agent-task-handoff/init-task.sh smoke-test          # 应报 [空] 不合规
rm -rf <工作区根>/smoke-test
```

## 使用说明

### 我该走哪条安装路

| 你的环境 | 走哪条 |
|---|---|
| Windows，本机装了多个 agent（最省事，一条命令铺满） | F |
| Qoder | A（上面快速开始那条） |
| Claude Code / Codex | B：clone 到 `~/.claude/skills/` 或 `~/.codex/skills/`，再补 G |
| 其他认 `SKILL.md` 格式的 agent | C：clone 进它的 skills 目录，目录名保持 `multi-agent-task-handoff`（frontmatter 的 `name` 必须等于目录名） |
| 不加载 skill，但会自动读 `AGENTS.md` / `CLAUDE.md` | D：只跑上面第 2 步的 `bootstrap.sh`；或把 [references/agents-rule.md](references/agents-rule.md) 整段粘进那个文件 |
| 什么机制都没有，只有能跑 shell 的 agent / 纯人工 | E：让 agent 执行第 2、3 步；或把 [references/doc-spec.md](references/doc-spec.md)（规则全文，自包含）贴进系统提示 |
| 想让「收工跑闸门」不依赖 agent 自觉 | G：全局规则块 + 每日定时巡检（见下） |

D 路**同样带上产物链接规矩**——`agents-rule.md` 里含「产物链接（强制）」一节，别以为走 D 就只拿到三档结构。

### 装完约束 agent 的是这六条

1. 每个任务目录同时有 `README.md` / `DESIGN.md` / `CONTEXT.md` **三档**，章节顺序固定、不许删；目录里已有承担方案设计的交付文档（`架构设计.md`、`XX实施方案.md` 这类**复合名**）时 DESIGN 可省，闸门打印 `[档]` 而不是 `[缺]`。
2. `设计思路` 必须是「决策 / 理由 / 代价」三列表，**只写结论不写代价视为没写**。
3. **向用户呈现的文件一律写成可点击链接**：文档内用**相对该 `.md` 自身目录**的路径，聊天回复才按宿主选（见下面「产物链接」）。
4. **除五个固定名外的输出文档必须中文命名**（`设计总览.md` 而非 `design-overview.md`）；与三档职责重复的说明/进度文件仍然禁止。
5. 收工前 `check-docs.sh` 退出码 0 才算本次会话结束。
6. **输出前主动过规则清单**（artifact-links / chinese-doc-naming / complete-deliverables / self-audit），把每份输出当交付物而不是草稿。

差别只在**由谁兜底**：A/B/C 是 agent 主动加载 skill；D/E 是规则落进 `AGENTS.md` 被动生效，所以 D/E 要把第 5 条当硬闸门要求。G 补两层：全局规则块（Codex 必读 `~/.codex/AGENTS.md`、Claude Code 对应 `~/.claude/CLAUDE.md`，里面点名「禁止以当前目录不在工作区为由跳过」），以及把 `check-docs.sh` 挂成每日任务、转红才通知——闸门从「agent 自觉跑」变成「调度器每天一定跑」。

### 三份文档，职责不许混

| 文件 | 读者 | 回答的问题 | 变化频率 |
|---|---|---|---|
| `README.md` | 用户 / 使用者 | 这是什么、能干什么、怎么跑起来、有什么限制 | 稳定，用法变了才改 |
| `DESIGN.md` | 方案评审者 / 二次开发的人 | **为什么这么设计**、架构与接缝、哪些语义已定死 | 稳定，设计变了才改 |
| `CONTEXT.md` | 下一个 agent | 做到哪了、还剩什么、有什么坑 | **每次会话都要改** |

进度、验证记录、待办只准写 CONTEXT；设计取舍、架构、已定语义只准写 DESIGN；操作步骤只准写 README。多档都需要的硬事实（端口、路径、磁盘要求）由 owning 那档写全文、其余一行引用——否则必然失同步。归档判据一句话：**这条结论半年后还成立吗？** 成立进 DESIGN，不成立进 CONTEXT。

章节顺序固定（可加节，不可删既定节）：

- `README.md`：一句话说明 → 快速开始 → 使用说明 → 产物与目录 → 限制与注意事项
- `DESIGN.md`：问题与目标 → 设计思路 → 架构与关键接缝 → 已定语义与边界
- `CONTEXT.md`：背景与目标 → 当前状态 → 计划 / 待办 → 关键约束与注意事项 → 变更记录 → 给下一个 agent 的追加区

### 产物链接（强制）

两个渲染面对 `href` 的解析逻辑**相反**，按面选形式：

- **写进 `.md` 文档里的**：一律**相对该文档自身目录**的路径（上级写 `../`），行号与文档内锚点写进**链接文字**、不用 `#L42` 片段。会推 GitHub 的 README 用同一种写法——GitHub 也认相对链接。
- **聊天回复里的**：支持「工作区相对 + `#L` 跳行」的宿主（已验证 Claude Code 的 VSCode 扩展）用 `相对路径#L489`；Qoder 聊天侧边栏、Codex 或不确定时用 `file:///` 绝对链接。

**文档里不要写 `file:///`**：预览面板按"相对文档目录"解析，`file://` scheme 不在其绝对地址白名单里——VSCode 预览报「文件不存在」（文件其实在），Qoder 文档预览干脆不渲染成链接（2026-10-14 实测；旧口径"本机文档首选 `file:///`"由此作废，它来自一次只测了聊天侧边栏的实测）。

点不开的反例：裸文件名、反引号路径、纯文本 `D:\...`、被转义的方括号、链接文字以 `\` 结尾（`\]` 会被当转义）。

### 日常命令

```bash
bash multi-agent-task-handoff/init-task.sh <任务名>              # 开新任务：建目录 + 铺三档骨架
bash multi-agent-task-handoff/check-docs.sh                      # 收工闸门：全量验收
bash multi-agent-task-handoff/check-docs.sh my-task              # 只查一个任务
bash multi-agent-task-handoff/check-docs.sh --root E:/other_ws   # 换工作区根（或 export AGENT_WS_ROOT=…）
STALE_DAYS=7 bash multi-agent-task-handoff/check-docs.sh         # 收紧"过期"判定（默认 30 天）
```

上面是**下游工作区**（bootstrap 铺出的扁平副本）的写法。在真源工作树里脚本多一层 `scripts/`：`bash multi-agent-task-handoff/scripts/check-docs.sh`。两种布局 root 解析都认，闸门结尾也会按实际位置打印正确命令。

**跑闸门不要加管道**（`| tail`、`| grep`）——只看结尾那句 `OK` 会把违规行截掉，这是真实发生过的自审失真。

### 检查项前缀与严重度

| 前缀 | 含义 | 是否导致失败 |
|---|---|---|
| `[缺]` | 三档文件不存在（README / DESIGN / CONTEXT） | 是 |
| `[构]` | 缺章节 | 是 |
| `[占]` | 模板占位符没替换 / 日期没填 | 是 |
| `[题]` | H1 标题不含任务目录名（中文名写成 `# 目录名（别名）· 使用说明` 就过） | 是 |
| `[空]` | 骨架未填（三档任一表格留全空行、CONTEXT 空待办；DESIGN「设计思路」三列表**任一格留空**也算） | 是 |
| `[链]` | 「产物与目录」没有可点击链接（`file:///` 或相对链接都算），**或**链接指向的文件不存在（两种形式都验），**或**顶层交付 `.md` 用反引号裸写工作区 `.md`/`.txt` | 是 |
| `[名]` | 顶层输出 `.md` 用了纯 ASCII 文件名（`README`/`DESIGN`/`CONTEXT`/`AGENTS`/`SKILL` 五个固定名豁免） | 是 |
| `[期]` | 三档顶部「最近更新」日期不一致 | 是 |
| `[新]` | 顶部缺 `> 最近更新：YYYY-MM-DD` | 是 |
| `[旧]` | 超期未更新（`STALE_DAYS` 可调，默认 30 天） | 否，仅告警 |
| `[档]` | 方案设计已由某交付文档承担（`架构设计.md`、`XX实施方案.md` 这类复合名），故不要求 `DESIGN.md` | 否，仅信息 |

只有超期保持告警：已完结的任务本就该停在最后改动那天，硬失败只会让人直接绕过整个检查。`[档]` 的名单**只收复合名**——`他人设计稿评审意见书.md` 换不到豁免（拿假名换豁免是最容易悄悄松掉的口子，已用夹具双向验证）。

### 更新即铺满（铁律）

skill 无论**本地改过**还是 **`git pull` 到更新**，都必须立刻把最新内容覆盖到本机所有 agent 的技能目录——只更新真源不铺满，其他 agent 下次会话就在跑旧规矩，等于规矩分叉。在本机：

```powershell
# 改完真源：先 commit + push，再从工作树里这一份启动
git -C D:\agent_workspace\multi-agent-task-handoff push origin master
powershell -NoProfile -ExecutionPolicy Bypass -File D:\agent_workspace\multi-agent-task-handoff\scripts\install-everywhere.ps1
```

- `-Source` 缺省 = 脚本所在 `scripts\` 的上一级 = 真源根，所以**从工作树里那份启动即正确**。
- 同一趟幂等刷新：各 agent 技能目录、各 agent 的全局规则块（`.codex\AGENTS.md`、`.claude\CLAUDE.md`）、每个已登记工作区的脚本副本目录（含 `install-everywhere.ps1` 自己）。**副本目录就是真源时跳过自铺**，否则会把扁平脚本铺到工作树根、与 `scripts/` 正主并存两份。
- **已有规则块的工作区不会被自动更新**：`bootstrap.sh` 与本脚本都靠标题正则 `任务[双三]档规范` 判重、只补不覆盖。改了条款要**手工同步那份 `AGENTS.md`**，否则那里的 agent 读到的还是旧版。
- **默认只补不删**：仓库里删掉的文件在各副本里会留着（2026-10-14 合并落地页时就留下三份幽灵 `.github/README.md`，内容还是旧规矩，而铺满输出照样全绿）。要清就加 `-Prune`——**先把待删清单打进输出，再删**；只想看清单用 `-Prune -DryRun`。作用域严格限定在本脚本自己铺的两个子树：技能目录下的 skill 子树按真源镜像比对，工作区脚本副本目录按「4 份脚本 + templates/」比对；真源目录本身拒绝执行，也不碰 `AGENTS.md`、全局规则文件与任务目录。**副作用要说明白：工作区那个脚本副本目录归安装器所有，别往里放自己的笔记。**
- 可选但推荐：装 `post-merge` 钩子，pull 完自动铺满——`.git/hooks/post-merge` 三行：

  ```sh
  #!/bin/sh
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(git rev-parse --show-toplevel)/scripts/install-everywhere.ps1"
  ```

条款原文以 [SKILL.md](SKILL.md) 的「Propagation rule (MANDATORY)」为准，本节是给人看的操作版。

## 产物与目录

| 文件 | 用途 |
|---|---|
| [SKILL.md](SKILL.md) | skill 入口：工作流、必备章节、产物链接规则、铺满铁律（agent 读这份） |
| [scripts/init-task.sh](scripts/init-task.sh) | 建任务目录 + 铺三档骨架 |
| [scripts/check-docs.sh](scripts/check-docs.sh) | 合规闸门（本仓库所有规矩的可执行下限） |
| [scripts/bootstrap.sh](scripts/bootstrap.sh) | 把整套规矩装进任意工作区根（`--force` 重同步副本） |
| [scripts/install-everywhere.ps1](scripts/install-everywhere.ps1) | 「更新即铺满」的执行工具（铺技能目录 + 全局规则 + 工作区副本，含它自己） |
| [references/doc-spec.md](references/doc-spec.md) | 规则全文：命名禁令、分工红线、产物链接、边界特例 |
| [references/agents-rule.md](references/agents-rule.md) | bootstrap 追加进各工作区 `AGENTS.md` 的规则块原文 |
| [assets/README.md.tpl](assets/README.md.tpl) · [assets/DESIGN.md.tpl](assets/DESIGN.md.tpl) · [assets/CONTEXT.md.tpl](assets/CONTEXT.md.tpl) | 三档骨架模板 |
| [README.md](README.md) | 本文件：仓库落地页 + 本目录三档之一（2026-10-14 起合并，不再有第二份 `.github/README.md`） |
| [DESIGN.md](DESIGN.md) | 本目录方案设计：工具自己的取舍表、脚本之间的接缝、动不得的契约 |
| [CONTEXT.md](CONTEXT.md) | 本目录交接档案：进度、待办、踩坑，**以及对外的「发布更新记录」** |
| [../AGENTS.md](../AGENTS.md) | 工作区规矩全文（含本地注解，不由安装器覆盖） |

## 限制与注意事项

- 需要 bash（Git Bash / Linux / macOS 均可）。`check-docs.sh` **不依赖 GNU `date -d`**（2026-10-14 起改用纯 bash 的 civil→days 算法），但整个脚本仍是 bash——**纯 cmd / PowerShell 下没有对应实现**，这是刻意的：`[空]/[档]/[链]` 全靠 grep/awk，两套判定逻辑必然漂移。Windows 请走 Git Bash。
- `install-everywhere.ps1` 仅 Windows（PowerShell 5.1+），运行加 `-ExecutionPolicy Bypass`；脚本含中文，**保存必须 UTF-8 带 BOM**，否则 5.1 按 GBK 误读、判重失效会追加出重复规则块。它的输出是 GBK，接 `| iconv -f GBK -t UTF-8` 才读得懂。
- 脚本不联网、不执行删除、不跑 git——它是脚手架与闸门，不是清理工具。
- 文档与默认值里出现的 `D:/agent_workspace`、`C:/Users/…` 只是本机示例路径。非本机首次使用**必须显式传 `--root`**，否则 `check-docs.sh` 会静默检查一个不存在的目录。
- 闸门只校验**结构与是否留空**，不判断内容质量：正确的标题配空话照样通过。这是刻意的弱校验（取舍见 [DESIGN.md](DESIGN.md) 的表）。
- **闸门绿不等于链接点得开**：`[链]` 对 `file:///` 与相对路径都接受、都验本机可达，所以文档里写满 `file:///` 照样 exit 0、在预览里却点不开——选形式这件事它帮不上。
- 一级子目录除 `templates`/`node_modules`/`.git` 外都被要求三档；脚本副本目录**按内容判**（只有脚本时跳过，铺了三档就照任务目录查）。别顺手把任务目录加进跳过名单，那等于关掉规矩。
- 章节匹配用 `grep -qE "^## +.*<节名>"` 子串匹配，正文里出现同名普通二级标题会被误判为"该节已存在"。
- 本仓库根目录留了 `.gitattributes`（`* text=auto eol=lf`），不能删：Windows Git 默认 `autocrlf=true`，bash 脚本一旦带上 `\r`，接收方直接语法报错。
- 根目录的 `README.md` / `DESIGN.md` / `CONTEXT.md` 是**本工作区的三档交接文档**，写的是本机路径与进度，属于上下文不是规范——规范以 [SKILL.md](SKILL.md) 与 `references/` 为准。GitHub 首页渲染优先级是 `.github` > 根目录 > `docs`，2026-10-14 合并后根 README 就是首页那份。
