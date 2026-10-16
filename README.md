# multi-agent-task-handoff · 使用说明

> 给「一个根目录下按任务建子目录」的 agent 工作区，强制一套**可自检**的任务交接规矩：每个任务目录同时维护 `README.md`（使用者）、`DESIGN.md`（方案评审者）、`CONTEXT.md`（下一个 agent）三档，外加骨架生成、合规闸门、以及把整套规矩装到任意工作区的一条命令。
> 标识 `multi-agent-task-handoff`，Qoder / Claude Code / Codex 的用户级 Skill。
> **本目录同时是这个仓库的 git 工作树（真源）**——`D:\agent_workspace\multi-agent-task-handoff\`；`~\.qoder-cn\skills\`、`~\.codex\skills\`、`~\.claude\skills\` 三处是下游副本。
> 设计取舍见 [DESIGN.md](DESIGN.md)，进度与**对外更新记录**见 [CONTEXT.md](CONTEXT.md)，工作区规矩原文见 [references/agents-rule.md](references/agents-rule.md)（本机 `D:\agent_workspace\AGENTS.md` 是它的入口版，不在仓库内，所以不给链接）。
> 最近更新：2026-10-16

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

**改闸门判定**的验收线是三条：`bash scripts/selftest.sh` 全绿 → `bash scripts/muttest.sh` 全部被抓到 → 真工作区输出与基线**逐字节相同**。第三条是"只改性能没改语义"的硬证据。

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

### 谁触发铺满

| 触发点 | 在哪跑 | 这一趟做什么 | 没做成时会怎样 |
|---|---|---|---|
| 手动 | 工作树里跑 `scripts\install-everywhere.ps1` | 铺技能目录 + 全局规则块 + 工作区脚本副本 | 全靠人记得跑——这就是历史上出事的那条缝 |
| 别人 `git pull` | `.git/hooks/post-merge` | 同上，且带 `-Prune` | 清单打在 pull 的输出里 |
| 本机 `git push` | `.git/hooks/pre-push` | 同上，且带 `-Prune` | 工作树脏 → 跳过只警告；铺满真失败 → **阻断本次 push** |
| 每日 10:10 | 计划任务跑 `scripts/watchdog.sh` | 逐字节比对副本与工作树；查派生规则文件的 `[锚]`/`[出处]`/`[指针]`；再跑一遍闸门 | 写 `<工作区根>/.watchdog/_需要处理.md`，全绿自动撤掉 |

### 铺满那一趟刷了什么

- `-Source` 缺省 = 脚本所在 `scripts\` 的上一级 = 真源根，所以**从工作树里那份启动即正确**。
- 同一趟幂等刷新：各 agent 技能目录、各 agent 的全局规则块（`.codex\AGENTS.md`、`.claude\CLAUDE.md`）、每个已登记工作区的脚本副本目录（含 `install-everywhere.ps1` 自己）。**副本目录就是真源时跳过自铺**，否则会把扁平脚本铺到工作树根、与 `scripts/` 正主并存两份。

### 两种模式：整份 vs 入口（判重有**两个**锚）

| 模式 | 命令 | `AGENTS.md` 里放什么 | 谁需要它 | 之后改规矩 |
|---|---|---|---|---|
| 整份（默认） | `bash scripts/bootstrap.sh --root <工作区根>` | 本文件（`agents-rule.md`）整段 + 出处戳 | **不加载 skill、只读规则文件**的 agent（安装路 D/E 档），这是它们唯一的规矩来源 | 手工同步那份，或重跑安装器（只补不覆盖） |
| 入口 | `bash scripts/bootstrap.sh --root <工作区根> --entry` | 本机政策 + 一行 `<!-- agents-entry -->` + 一行指针，**不含任何条款** | 装了 skill、agent 会读 `SKILL.md` 的工作区（本机就是这种，149 行 → 16 行） | **不需要动它**——规矩只在源头改 |

- 判重锚：老锚 = 标题含 `任务[双三]档规范`；新锚 = **整行**的 `<!-- agents-entry -->`。`bootstrap.sh` 与 `install-everywhere.ps1` 都认这两个，**两处必须一起改**；入口模式需要认得新锚的安装器，旧版会把整段规则追加进去（本机靠 `pre-push` 保证不落后）。
- 一个文件**两个锚都没有**又已存在时：`bootstrap.sh --entry` 直接报错要人选模式，`install-everywhere.ps1` 只警告不灌（铺满是无人的，不敢覆盖来源不明的文件）——**绝不往未知文件里灌整段规则**。
- 新锚必须整行匹配：正文里出现 `agents-entry` 这串字（本文件就有）不该被当成"装了锚"，那是假绿灯。

### 已装的规则块不会被自动更新

- 判重靠那两个锚，**只补不覆盖**。改了条款，整份模式的工作区得**手工同步那份 `AGENTS.md`**，否则那里的 agent 读到的还是旧版；入口模式不需要——它里面没有条款。
- **本机 `D:\agent_workspace\AGENTS.md` 现在是入口版**（2026-10-15，149 行 → 16 行）：只剩「工作目录约定」那章本机政策 + 锚 + 一行指针。它不再有同步义务；代价是那一章**天生没有源头**，防误删只能靠给工作区根做版本控制。
- 各 agent 的全局规则文件（`~\.codex\AGENTS.md`、`~\.claude\CLAUDE.md`）也是派生物：本机那两份是 2026-10-15 之前的手抄、**没有出处戳**，探针每天报"无出处戳"但不算失败——重写会覆盖本地增补，所以由人决定；它们的措辞已先上收进 `agents-rule.md`，源头不比派生物少东西。要迁就跑 [scripts/sync-global-rules.ps1](scripts/sync-global-rules.ps1)：默认 DryRun 只报告保留哪几行、删掉哪几行，`-Apply` 才写并先留 `.bak-<时间戳>`。锚点标题**之上**的内容永久保留，所以想把本机专属的说明长期留住，就写在文件顶部那一段，而不是写进规则块里。

### 只补不删是默认，清理要显式 `-Prune`

- **为什么会留垃圾**：仓库里删掉的文件在各副本里原样留着。2026-10-14 合并落地页时就留下三份幽灵 `.github/README.md`，内容还是旧规矩，而铺满输出照样全绿——"副本 == 真源"这个前提被静默破掉。
- **两个开关**：`-Prune` **先把待删清单打进输出、再删**；`-Prune -DryRun` 只列不删。手动那一趟默认不带 prune（省略开关就只补，由跑的人决定），本机的钩子已经带上了。
- **作用域严格限定**在本脚本自己铺的两个子树：技能目录下的 skill 子树按真源镜像比对，工作区脚本副本目录按「6 份脚本 + templates/」比对；真源目录本身拒绝执行，也不碰 `AGENTS.md`、全局规则文件与任务目录。
- **副作用要说白**：工作区那个脚本副本目录归安装器所有，别往里放自己的笔记。

### 钩子与计划任务的配方

> 两个钩子都在 `.git/hooks/` 下，**不被 git 跟踪**：换机器照本节重建，且必须保持 **LF** 行尾（带回车的 `sh` 在 Git Bash 下直接语法报错）。

**① `post-merge` —— 别人 pull 时自动铺满。** 带 `-Prune` 的理由：钩子那趟无人值守，不带 prune 就等于「删文件后要清残留」这一步永远没人做（2026-10-14 合并落地页后那三份幽灵 `.github/README.md`，正是靠手动补跑才清掉的）。待删清单打在 pull 自己的输出里，看得见才删；作用域只有两个受管子树，真源目录拒绝执行。`.git/hooks/post-merge` 四行：

```sh
#!/bin/sh
# 更新即铺满，带 -Prune：先打待删清单，再删
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(git rev-parse --show-toplevel)/scripts/install-everywhere.ps1" -Prune
```

**② `pre-push` —— 本机 push 时自动铺满。** 它补的是「commit 了但没人跑铺满」那条缝（已经踩过两次）。挂在 push 而不是 commit：真源即发布源、push 是必经动作，而 `post-commit` 会把分几次提交的**中间态规矩**也铺出去。两种"没铺成"必须分开处理：

| 情形 | 钩子的动作 | 为什么 |
|---|---|---|
| 工作树脏 | 跳过铺满，只警告，**放行 push** | 铺满拷的是工作树，脏树会把未提交内容当权威铺进每个技能目录 |
| 铺满真失败 | **阻断本次 push** | 只打一行没人读的通知，等于回到"靠自觉" |

```sh
#!/bin/sh
# 铁律「更新即铺满」的机械化：推之前先把最新内容铺到本机所有 agent 的技能目录与工作区。
set -e
cd "$(git rev-parse --show-toplevel)" || exit 1
if [ -n "$(git status --porcelain)" ]; then
  echo "pre-push: 工作树有未提交改动，跳过铺满（副本可能落后，watchdog 会报）"
  exit 0
fi
if powershell.exe -NoProfile -ExecutionPolicy Bypass -File "scripts/install-everywhere.ps1" -Prune; then
  echo "pre-push: 铺满完成（-Prune）— 各 agent 技能目录与工作区副本已与工作树一致"
else
  echo "pre-push: 铺满失败，已阻断本次 push（先修脚本，或手工跑一次 install-everywhere.ps1 再推）" >&2
  exit 1
fi
```

**③ 每日看门狗 —— 前两条都够不着的情形归它兜**：既没 pull 也没 push 的漂移、有人直接在副本里手改、别的会话忘了铺。`scripts/watchdog.sh` 逐字节比对各副本与工作树、顺带跑一遍闸门，**只在出问题时**写 `<工作区根>/.watchdog/_需要处理.md`（全绿自动撤掉），日志追加在同目录 `propagation.log`。脚本随仓库走，注册一次即可（PowerShell，只在登录状态下跑，好让待处理件真能被看见）：

```powershell
$cp = '~/.qoder-cn/skills/multi-agent-task-handoff,~\.codex\skills\multi-agent-task-handoff,~\.claude\skills\multi-agent-task-handoff'
$a = New-ScheduledTaskAction -Execute 'D:\software\Git\bin\bash.exe' `
  -Argument ('-c "bash /d/agent_workspace/multi-agent-task-handoff/scripts/watchdog.sh --copies ''{0}''"' -f $cp)
Register-ScheduledTask -TaskName 'multi-agent-handoff-drift' -Action $a `
  -Trigger (New-ScheduledTaskTrigger -Daily -At 10:10) `
  -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew) `
  -Description 'skill drift watchdog: copies vs worktree + gate'
```

  `--copies` 写成绝对路径是有原因的：计划任务里 `HOME` 常指向 MSYS 的 `/home/<user>` 而不是 `C:\Users\<user>`，靠默认名单会**一个副本都比对不到**——那种"没查"脚本会当错误报（exit 2），不会给你一行绿。

条款原文以 [SKILL.md](SKILL.md) 的「Propagation rule (MANDATORY)」为准，本节是给人看的操作版。

## 产物与目录

| 文件 | 用途 |
|---|---|
| [SKILL.md](SKILL.md) | skill 入口：工作流、必备章节、产物链接规则、铺满铁律（agent 读这份） |
| [scripts/init-task.sh](scripts/init-task.sh) | 建任务目录 + 铺三档骨架 |
| [scripts/check-docs.sh](scripts/check-docs.sh) | 合规闸门（本仓库所有规矩的可执行下限） |
| [scripts/bootstrap.sh](scripts/bootstrap.sh) | 把整套规矩装进任意工作区根（`--force` 重同步副本；`--entry` 生成"本机政策 + 指针"的入口文件，不复述条款） |
| [scripts/install-everywhere.ps1](scripts/install-everywhere.ps1) | 「更新即铺满」的执行工具（铺技能目录 + 全局规则 + 工作区副本，含它自己） |
| [references/doc-spec.md](references/doc-spec.md) | 规则全文：命名禁令、分工红线、产物链接、边界特例 |
| [references/agents-rule.md](references/agents-rule.md) | bootstrap 追加进各工作区 `AGENTS.md` 的规则块原文 |
| [assets/README.md.tpl](assets/README.md.tpl) · [assets/DESIGN.md.tpl](assets/DESIGN.md.tpl) · [assets/CONTEXT.md.tpl](assets/CONTEXT.md.tpl) | 三档骨架模板 |
| [scripts/selftest.sh](scripts/selftest.sh) | **闸门夹具自检**：47 条断言，在隔离临时根上造夹具、闸门只跑一次、按目录切段断言。改判定前后都要跑 |
| [scripts/muttest.sh](scripts/muttest.sh) | 变异测试：把闸门逐条改坏 18 处，确认 selftest 每条都会红——防的是"断言静默消失"那种假绿灯 |
| [scripts/watchdog.sh](scripts/watchdog.sh) | 铺满漂移看门狗：`diff -q` 逐字节比对各副本与工作树 + 跑一遍闸门，只在出问题时写 `<工作区根>/.watchdog/_需要处理.md`。挂每日计划任务（注册命令见「更新即铺满」） |
| [scripts/sync-global-rules.ps1](scripts/sync-global-rules.ps1) | 一次性迁移工具：把各 agent 的**全局规则文件**重写成源头当前的 global-block 段 + 出处戳。默认 DryRun，`-Apply` 才写且先备份；只认"第一个命中锚的标题行→文件末尾"，锚点之后还有 H1 就中止。**刻意不进工作区扁平副本清单**（它需要 `references/` 与 `git`） |
| [README.md](README.md) | 本文件：仓库落地页 + 本目录三档之一（2026-10-14 起合并，不再有第二份 `.github/README.md`） |
| [DESIGN.md](DESIGN.md) | 本目录方案设计：工具自己的取舍表、脚本之间的接缝、动不得的契约 |
| [CONTEXT.md](CONTEXT.md) | 本目录交接档案：进度、待办、踩坑，**以及对外的「发布更新记录」** |
| `D:\agent_workspace\AGENTS.md`（本机文件，在仓库之外，故不给链接） | 工作区入口：本地政策 + 指针，2026-10-15 起不再复述细则。它标题里的「任务三档规范」是安装器的**幂等锚**，删掉那四个字会让下次铺满在本文件末尾追加第二份规则块 |

## 限制与注意事项

### 跑起来需要什么

- 需要 bash（Git Bash / Linux / macOS 均可）。`check-docs.sh` **不依赖 GNU `date -d`**（2026-10-14 起改用纯 bash 的 civil→days 算法），但整个脚本仍是 bash——**纯 cmd / PowerShell 下没有对应实现**，这是刻意的：`[空]/[档]/[链]` 全靠 grep/awk，两套判定逻辑必然漂移。Windows 请走 Git Bash。
- `install-everywhere.ps1` 仅 Windows（PowerShell 5.1+），运行加 `-ExecutionPolicy Bypass`；脚本含中文，**保存必须 UTF-8 带 BOM**，否则 5.1 按 GBK 误读、判重失效会追加出重复规则块。它的输出是 GBK，接 `| iconv -f GBK -t UTF-8` 才读得懂。

### 谁会删东西，输出为什么会花
- **只有闸门不碰删除**：`check-docs.sh` 不联网、不执行删除、不跑 git——它是验收工具，不是清理工具。会删的是另外两个，且各自范围窄：`install-everywhere.ps1 -Prune` 只删两个受管子树里的残留文件（先列清单），`watchdog.sh` 只删**它自己写的**待处理件。
- **Git Bash 里钩子与铺满的输出会有一半乱码**：PowerShell 按 GBK 写、`sh` 的 `echo` 是 UTF-8，同一条流两种编码，整体 `| iconv -f GBK -t UTF-8` 就把 UTF-8 那半弄花（反之亦然）。不改脚本的 `OutputEncoding`——它会连带影响 cmd 那边，而这两行都只是状态播报，不是判定结果；**要看的关键内容（prune 的待删清单、闸门违规行）来自 PowerShell 侧，`iconv` 之后是干净的**。

### 闸门拦什么、拦不住什么

- **闸门性能是功能的一部分**：Windows 起一个子进程 ≈25ms，现在每个任务目录只起 4 次进程（三档判定一次 awk、链接提取一次、裸名候选一次、`find` 一次），真工作区全量 ≈0.9 秒。2026-10-14 之前是 10.7 秒，更早 38 秒那版直接被人绕过——慢的闸门等于没有闸门。
- 文档与默认值里出现的 `D:/agent_workspace`、`C:/Users/…` 只是本机示例路径。非本机首次使用**必须显式传 `--root`**，否则 `check-docs.sh` 会静默检查一个不存在的目录。
- 闸门只校验**结构与是否留空**，不判断内容质量：正确的标题配空话照样通过。这是刻意的弱校验（取舍见 [DESIGN.md](DESIGN.md) 的表）。
- **闸门绿不等于链接点得开**，而且它只在**本机**判可达。三种它看不见的情况：① 文档里写满 `file:///` 照样 exit 0，在预览面板却点不开（选错形式）；② 指向工作区外的 `file:///` 一律跳过（脚本要能发给没有 `D:` 盘的人）；③ 相对链接 `../` 越出仓库根——本机真的存在，GitHub 上却是 404。第 ③ 种 2026-10-15 手工查出并改净 5 条，让 `[链]` 自动拦的待办记在 [CONTEXT.md](CONTEXT.md)。
- 一级子目录除 `templates`/`node_modules`/`.git` 外都被要求三档；脚本副本目录**按内容判**（只有脚本时跳过，铺了三档就照任务目录查）。别顺手把任务目录加进跳过名单，那等于关掉规矩。
- 章节匹配用 `grep -qE "^## +.*<节名>"` 子串匹配，正文里出现同名普通二级标题会被误判为"该节已存在"。

### 仓库里不能删的配置

- 本仓库根目录留了 `.gitattributes`（`* text=auto eol=lf`），不能删：Windows Git 默认 `autocrlf=true`，bash 脚本一旦带上 `\r`，接收方直接语法报错。

### 仓库根那三份文档是什么身份

- 根目录的 `README.md` / `DESIGN.md` / `CONTEXT.md` 是**本工作区的三档交接文档**，写的是本机路径与进度，属于上下文不是规范——规范以 [SKILL.md](SKILL.md) 与 `references/` 为准。GitHub 首页渲染优先级是 `.github` > 根目录 > `docs`，2026-10-14 合并后根 README 就是首页那份。
