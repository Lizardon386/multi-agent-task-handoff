# 多agent间工作任务交接手顺

> Qoder / 任意 agent 的用户级 Skill。标识 `multi-agent-task-handoff`。

给「一个根目录下按任务建子目录」的 agent 工作区，强制一套**可自检**的任务交接规矩：每个任务目录同时维护 **面向使用者的 `README.md`** 和 **面向下一个 agent 的 `CONTEXT.md`**，并提供骨架生成、合规闸门、以及把整套规矩装到任意工作区的一条命令。

## 解决什么问题

会话是易失的。换会话、换 agent、换机器之后，接手的人只能从目录列表猜意图——猜错就返工。

- `README.md` 存「为什么这么设计」，避免同一件事被反复重议；
- `CONTEXT.md` 存「到哪了、还剩什么、有什么坑」，避免重复劳动和踩已知坑。

规矩只写成条文没用：agent 冷启动不一定读到，读到了也不一定执行。所以这套东西的形态是**脚本 + 退出码**，不执行就会被闸门拦下。

## 安装

先判断你的 agent 属于哪一类：

| 你的环境 | 走哪条 |
|---|---|
| Windows，本机装了多个 agent（最省事，一条命令铺满） | **F** |
| Codex（桌面 App / CLI） | B（目标路径换成 `~/.codex/skills/`），并补 **G** |
| Qoder | A |
| Claude Code | B |
| 其他认 `SKILL.md` 格式的 agent | C |
| 不加载 skill，但会自动读 `AGENTS.md` / `CLAUDE.md` 之类的规则文件 | D |
| 什么机制都没有，只有个能跑 shell 的 agent，或纯人工 | E |
| 想让「收工跑闸门」不依赖 agent 自觉 | **G** |

### A. Qoder

```bash
git clone https://github.com/Lizardon386/multi-agent-task-handoff.git \
  ~/.qoder-cn/skills/multi-agent-task-handoff
```

Qoder 扫描 skills 目录，开新会话（或让它重扫）后即可调用 `/multi-agent-task-handoff`。之后 `cd` 进去 `git pull` 就能跟进更新。

### B. Claude Code

个人级（所有项目可用）：

```bash
git clone https://github.com/Lizardon386/multi-agent-task-handoff.git \
  ~/.claude/skills/multi-agent-task-handoff
```

项目级（只对该仓库生效，适合团队共享）：把上面的目标路径换成 `<项目>/.claude/skills/multi-agent-task-handoff`。

Claude Code 按 `SKILL.md` 的 `description` 自动匹配调用，不需要斜杠命令；想强制触发就直接说「用 multi-agent-task-handoff skill」。

Codex 同样认 SKILL.md：把上面的目标路径换成 `~/.codex/skills/multi-agent-task-handoff` 即可。Codex 另外还会**每次会话必读**全局 `~/.codex/AGENTS.md`——推荐把 G 的全局规则块一并装上。

### C. 其他支持 skill 机制的 agent

仓库结构是通用的（`SKILL.md` + `scripts/` + `references/` + `assets/`，YAML frontmatter 带 `name` / `description`），不依赖任何专有格式。找到该 agent 的 skills 目录，clone 进去即可；目录名建议保持 `multi-agent-task-handoff`，因为 `SKILL.md` frontmatter 的 `name` 必须与之相同。

### D. 没有 skill 机制，但会自动读规则文件

不装 skill，只把**规矩**装进工作区：

```bash
bash <skill目录>/scripts/bootstrap.sh --root <工作区根>
```

它会铺好 `<工作区根>/multi-agent-task-handoff/`（init + check 脚本）和 `multi-agent-task-handoff/templates/`，并把规则章节追加进 `<工作区根>/AGENTS.md`。`AGENTS.md` 不存在就创建，已含规则块则不动（幂等，可重复跑）。

如果你的 agent 读的不是 `AGENTS.md`（比如 `CLAUDE.md`、`.cursorrules`）：把 `references/agents-rule.md` 的内容整段粘进那个文件即可——那就是规则块的原文，与 `bootstrap.sh` 追加的完全一致。

> **注意这条路同样带上产物链接规则。** `agents-rule.md` 里含「产物链接（强制）」一节，所以只读 `AGENTS.md`、从不加载 `SKILL.md` 的 agent，一样会被要求把产物写成 `[名字](file:///绝对路径)` 可点链接。别以为走 D 就只拿到三档结构。

### E. 完全没有加载机制

两条路：

1. **让 agent 执行安装**——直接把这句话丢给它：
   > 运行 `bash <skill目录>/scripts/bootstrap.sh --root <工作区根>`，然后每次改完产物后运行 `<工作区根>/multi-agent-task-handoff/check-docs.sh`，退出码 0 才算本次任务结束。

   规则已经写进该工作区的 `AGENTS.md`，后续会话只要读得到就会被约束。

2. **纯 prompt 投喂**——把 `references/doc-spec.md`（规则全文，含章节顺序、命名禁令、分工红线、**产物链接要求**、边界特例）整篇贴进系统提示或项目指令里。这份是自包含的，不依赖脚本也能执行，只是没有闸门兜底。

### F. 本机装了多个 agent（Windows 一次铺满）

一条命令把 skill 同步进每个 agent 的技能目录、给有全局指令文件约定的 agent 追加规则块、并给每个工作区铺脚本副本目录（新名 `multi-agent-task-handoff/`，旧名 `tools/`）+ `AGENTS.md`：

```powershell
powershell -NoProfile -File <skill目录>\scripts\install-everywhere.ps1 `
  -Source <真源skill目录> -WorkspaceRoots D:\agent_workspace
```

幂等、可重复跑，**只补不删**：已存在同名文件才按 MD5 比对更新，规则块靠「任务[双三]档规范」标题正则判重（与 `bootstrap.sh` 同一把锁），所以不会追加出第二份。默认覆盖 `.codex`、`.qoder-cn`、`.claude` 三个 agent 家目录（**2026-10-12 补上 `.claude`**：它本来就会被写全局规则块，却没有 skill 副本可指，规则里点名的 `references/agents-rule.md` 在它那儿是空的），`.codex/AGENTS.md`、`.claude/CLAUDE.md` 会被写入全局规则块——**不想改别的 agent 的全局指令文件就别跑它**，改用 `bootstrap.sh` 只铺工作区。

`-Source` 缺省为**脚本自身所在的 skill 目录**——`git pull` 后在真源克隆里直接跑即可完成铺满，不用再手填路径。

`install-everywhere.ps1` 同时是「更新即铺满」铁律的执行工具：skill 任何更新（本地改或 `git pull`）后都必须跑一次，详见下文专节。脚本含中文，**文件必须保持 UTF-8 带 BOM**：Windows PowerShell 5.1 把无 BOM 的中文按 GBK 误读，轻则规则块标题判重失效、追加出重复规则块，重则直接语法报错——2026-10-12 实测踩过，脚本已内置防御（显式 UTF-8 读写），但二次编辑后请保持 BOM。

### G. 全局规则 + 每日看门狗：让规矩不依赖 agent 自觉

skill 与 `AGENTS.md` 解决的是「agent 读不读得到」；读到了仍可能不执行——实测有 agent 以「当前目录不在 agent workspace」为由绕过聊天链接规则。两层补丁：

1. **全局规则块（每次会话必读层）**：Codex 必读 `~/.codex/AGENTS.md`，Claude Code 对应 `~/.claude/CLAUDE.md`。走 F 会自动写入；手工装就把 `references/agents-rule.md` 的要点压成 5 条贴进去。规则块里点名「禁止以当前目录不在工作区为由跳过」，把这个借口预先封死。
2. **定时巡检（终审权交给调度器）**：把 `check-docs.sh` 挂成每日任务，全绿则安静、转红才通知——闸门从「agent 收工时自觉跑」变成「调度器每天一定跑」。Codex 自动化（heartbeat/cron）直接给提示词：「跑 `check-docs.sh` 不加管道，全绿保持安静，转红用 `file:///` 链接报告违规」；Windows 任务计划 / Linux cron 同理，退出码非 0 即告警。
### 装完生效的是哪几条

不管走 A–F 哪条，最终约束 agent 的都是同样六条（详见下一节「它强制了什么」）：

1. 每个任务目录同时有 `README.md`（面向使用者）和 `CONTEXT.md`（面向下一个 agent），六节顺序固定、不许删；
2. `设计思路` 必须是「决策 / 理由 / 代价」三列表，只写结论不写代价视为没写；
3. **向用户呈现的文件一律写成可点击链接**（本机文档用 `[名字](file:///绝对正斜杠路径)`，要推到 GitHub 的仓库 README 用相对链接），裸文件名和反引号路径点不开；
4. **除三档固定名与 `AGENTS.md` 外的输出文档必须中文命名**（`设计总览.md` 而非 `design-overview.md`）；与三档职责重复的说明/进度文件仍然禁止；
5. 收工前 `check-docs.sh` 退出码 0 才算本次会话结束；
6. **输出前必须主动检查规则清单**（artifact-links / chinese-doc-naming / complete-deliverables 等），把每份输出当交付物而非草稿——这是 2026-10-14 新增的 MANDATORY 要求，防止 agent 写内容-first 跳过规则符合性检查。

差别只在**由谁兜底**：A/B/C 是 agent 主动加载 skill；D/E 是规则落进 `AGENTS.md`、靠 agent 读到该文件被动生效，所以 D/E 建议把第 5 条的自检当成硬闸门来要求。

补充：2026-10-12 起 `SKILL.md` 的 `description` 已改为**每一次会话、任意工作目录无条件触发**，并点名「当前目录不在 agent workspace」为无效借口。A/B/C 类 agent 只要装了 skill，聊天链接规则与收工 `CONTEXT.md` 更新即默认生效——不再有「换个目录就不算数」的缝隙。

### 装完验证一次

```bash
bash <工作区根>/multi-agent-task-handoff/check-docs.sh --root <工作区根>   # exit 0 说明闸门可用
bash <工作区根>/multi-agent-task-handoff/init-task.sh smoke-test          # 应报 [空] 不合规——拦空骨架是它的职责
rm -rf <工作区根>/smoke-test                           # 清掉测试目录
```

## 它强制了什么

**三份文档，职责不许混。**

| 文件 | 读者 | 回答的问题 | 变化频率 |
|---|---|---|---|
| `README.md` | 用户 | 这是什么、能干什么、怎么跑起来、有什么限制 | 稳定，用法变了才改 |
| `DESIGN.md` | 方案评审者 / 二次开发的人 | **为什么这么设计**、架构与接缝、哪些语义已定死 | 稳定，设计变了才改 |
| `CONTEXT.md` | 下一个 agent | 做到哪了、还剩什么、有什么坑 | **每次会话都要改** |

进度、验证记录、待办只准写 CONTEXT；设计取舍、架构、已定语义只准写 DESIGN；操作步骤只准写 README。多档都需要的硬事实（端口、路径、磁盘要求）由 owning 那档写全文、其余一行引用——否则必然失同步。

**README 与 DESIGN 的拆分（2026-10-14）**：取舍三列表原先长在说明书第一节，结果真正的使用步骤被顶到第二屏；任务推上 GitHub 后读者第一眼要的是"我怎么用"。归档判据：**这条结论半年后还成立吗？** 成立进 DESIGN，不成立进 CONTEXT。

**DESIGN 档可以省。** 目录里已经有承担方案设计职责的交付文档（`架构设计.md`、`XX实施方案.md`）就不再单立 `DESIGN.md`——两份设计真源必然失同步。闸门打印 `[档] 方案设计已由交付文档「X.md」承担` 并跳过四节检查。**名单只收复合名**：`他人设计稿评审意见书.md` 这种不获豁免（拿假名换豁免是最容易悄悄松掉的口子，已用夹具双向验证过）。

**章节顺序固定，各档既定节不许删。**

- `README.md`：一句话说明 → 快速开始 → 使用说明 → 产物与目录 → 限制与注意事项
- `DESIGN.md`：问题与目标 → 设计思路 → 架构与关键接缝 → 已定语义与边界
- `CONTEXT.md`：背景与目标 → 当前状态 → 计划 / 待办 → 关键约束与注意事项 → 变更记录 → 给下一个 agent 的追加区

**`设计思路`（在 DESIGN.md）必须是「决策 / 理由 / 代价」三列表。** 只有结论没有代价的表等于没写——这是硬要求，空表会被闸门拦下（三档任一表格里留全空行都算）。

**所有产物写成可点击链接，且链接必须能打开。** 向用户呈现的文件一律是链接：本机文档用 `[名字](file:///绝对正斜杠路径)`，要推到 GitHub 的仓库 README 用相对链接 `[名字](packages/…/game.js)`——裸文件名、反引号路径在侧边栏点不开，而 `file:///D:/...` 在别人机器上点不开。行号写在链接文字里，不用 `#L` 锚点。`[链]` 两种形式**都接受、也都验可达**——**改名而不更新引用会直接判失败**；`file:///` 指向工作区外的链接跳过（脚本要能发给没有 `D:` 盘的人），```` ``` ```` 代码围栏内的内容不验（否则示例代码里的 `[this](Status result)` 会被当成死链）。

**其他输出文档必须中文命名。** `README.md` / `DESIGN.md` / `CONTEXT.md` / `AGENTS.md` 是固定名不许翻译；除此之外，任务目录里真正属于交付物的文档（设计稿、评审意见书、决策件、评估报告）一律中文名，如 `设计总览.md`、`归属决策件.md`——读者是中文同事，文件要转发进群聊和飞书，英文名对方得先猜是哪个。被禁的是**与三档职责重复**的说明/进度文件（`使用说明.md`、`进度.md`、`notes.txt`），不是"多一个文件"本身。豁免：非 `.md` 交付物（`.docx` / `.pdf` 须与供应商原件同名）、`_` 前缀机器产物、`archive/` 与 `inputs/` 子目录、脚本代码。

## 日常用法

```bash
bash multi-agent-task-handoff/init-task.sh <任务名>              # 开新任务：建目录 + 铺三档骨架
bash multi-agent-task-handoff/check-docs.sh                      # 收工闸门：全量验收
bash multi-agent-task-handoff/check-docs.sh my-task              # 只查一个任务
bash multi-agent-task-handoff/check-docs.sh --root E:/other_ws   # 换工作区根（或 export AGENT_WS_ROOT=…）
```

`check-docs.sh` **退出码 0 才算本次会话收尾完成**。检查项前缀：

| 前缀 | 含义 | 是否导致失败 |
|---|---|---|
| `[缺]` | 三档文件不存在（README / DESIGN / CONTEXT） | 是 |
| `[构]` | 缺章节 | 是 |
| `[占]` | 模板占位符没替换 | 是 |
| `[题]` | H1 标题不含任务目录名（中文名写成 `# 目录名（别名）· 使用说明` 就过） | **是**（2026-10-14 新增） |
| `[空]` | 骨架未填（三档任一表格留全空行、CONTEXT 空待办、缺日期；DESIGN「设计思路」三列表**任一格留空**也算） | 是 |
| `[新]` | 顶部缺「最近更新：YYYY-MM-DD」 | 是 |
| `[链]` | 「产物与目录」没有可点击链接（`file:///` 或相对链接都算），**或**链接指向的文件不存在（两种形式都验），**或**顶层交付 `.md` 里用反引号裸写工作区 `.md`/`.txt`（改名遗留的不可点裸名） | **是**（2026-10-10 由告警升级） |
| `[名]` | 顶层输出 `.md` 用了纯 ASCII（英文）文件名（四个固定名 `README` / `DESIGN` / `CONTEXT` / `AGENTS` 豁免） | **是** |
| `[期]` | 三档顶部「最近更新」日期不一致 | **是** |
| `[旧]` | 超期未更新（`STALE_DAYS` 可调，默认 30 天） | 否，仅告警 |
| `[档]` | 方案设计已由某交付文档承担（`架构设计.md`、`XX实施方案.md` 这类复合名），因此不要求 `DESIGN.md` | 否，仅信息 |

只有超期保持告警：已完结的任务本就该停在最后改动那天，历史文档也不可能一夜改净——硬失败只会让人直接绕过整个检查。缺链接与日期不同步则是要守的东西本身，放过去就等于没有这条规矩。

**跑闸门不要加管道。** `check-docs.sh | tail -2` 只会留下结尾那句 `OK`，把前面的 `[链]`/`[旧]` 违规行全部截掉——这是真实发生过的自审失真，别在自己身上重演。

## 目录结构

```
SKILL.md                    skill 入口：工作流、必备章节、产物链接规则
scripts/init-task.sh        建任务目录 + 铺三档骨架
scripts/check-docs.sh       合规闸门
scripts/bootstrap.sh        把整套规矩装进任意工作区根（--force 可重同步副本）
scripts/install-everywhere.ps1  铁律「更新即铺满」的执行工具：一次铺满本机所有 agent 的技能目录（`.codex`/`.qoder-cn`/`.claude`）+ 全局规则 + 工作区脚本副本目录（含它自己）（见安装 F 与「更新即铺满」一节）
references/doc-spec.md      规则全文：命名禁令、分工红线、产物链接、边界特例、为什么要有这条规矩
references/agents-rule.md   bootstrap 追加进工作区 AGENTS.md 的规则块原文
assets/README.md.tpl        使用者文档骨架
assets/DESIGN.md.tpl        方案设计文档骨架（问题与目标 / 设计思路 / 架构与关键接缝 / 已定语义与边界）
assets/CONTEXT.md.tpl       agent 交接档案骨架
.github/README.md           本文件（仓库落地页，不属于 skill 内容）
.gitattributes              锁 eol=lf，见末节
```

`SKILL.md` 是给 agent 执行用的；`references/doc-spec.md` 是要质疑或修订规矩时才读的全文。

## 更新即铺满（铁律）

skill 无论**本地改过**还是 **`git pull` 到更新**，都必须立刻把最新内容覆盖到本机所有 agent 的技能目录——只更新真源不铺满，其他 agent 下次会话就在跑旧规矩，等于规矩分叉。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <最新skill目录>\scripts\install-everywhere.ps1
```

- **永远从"最新那份"里运行它**：`-Source` 缺省就是脚本自身所在的 skill 目录。`git pull` 后在真源克隆里直接跑；本地改完在改过的那份里直接跑。
- 同一趟还会幂等刷新：各 agent 的全局规则块（`.codex/AGENTS.md`、`.claude/CLAUDE.md`）与每个已登记工作区的脚本副本目录（旧名 `tools/`，新名 `multi-agent-task-handoff/`）——**包括 `install-everywhere.ps1` 自己**（2026-10-12 补：此前它不铺自己，真源更新了、工作区那份却永远停在旧版，而旧版 `-Source` 还硬编码着别的 agent 目录，从工作区跑就会拿错的源当权威）。
- **已有规则块的工作区不会被自动更新**：`bootstrap.sh` 与本脚本都靠「任务[双三]档规范」标题正则判重，只补不覆盖。改了条款，要**手工同步该工作区的 `AGENTS.md`**，否则那里的 agent 读到的还是旧版——这条本身就是 2026-10-12 补进 `references/agents-rule.md` 的（此前「更新即铺满」只在 `SKILL.md` 和本页，只读 `AGENTS.md` 的 agent 完全看不到）。
- **pull 自动化（可选但推荐）**：在真源克隆里装 `post-merge` 钩子，pull 一合并就自动铺满——`.git/hooks/post-merge` 三行：

  ```sh
  #!/bin/sh
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(git rev-parse --show-toplevel)/scripts/install-everywhere.ps1"
  ```

条款原文以 `SKILL.md` 的「Propagation rule (MANDATORY)」为准；本节是给人看的操作版。

## 最近更新

跟进方式：`git -C <skill目录> pull` 后**必须**按上节「更新即铺满」跑一次 `install-everywhere.ps1`（或事先装好 `post-merge` 钩子，pull 完自动铺满）。

**2026-10-14**

- **工作区脚本副本目录改名 `multi-agent-task-handoff`，`tools` 继续接受；副本目录是否算任务目录改成按内容判**。起因是收工跑闸门发现 **exit 1、34 条 `[链]`**：`D:\agent_workspace\tools\` 已被改名成别的目录名，而 `bootstrap.sh`、`install-everywhere.ps1`、`check-docs.sh` 的 root 解析与跳过名单、以及工作区/全局 `AGENTS.md` 和落地页教的命令全写死 `tools/`——下次铺满会另造一个 `tools/`，改名那份变成没人认领的第三副本（"两份真源必然漂移"的翻版）。现在：四处解析器都认两个名字，`bootstrap.sh` 与 `install-everywhere.ps1` 遇到已有 `tools/` 的工作区沿用旧名（一次铺满不会铺出两份脚本），结尾提示打印真实路径而不是失效的 `bash tools/init-task.sh`。跳过名单改为**按内容判**：副本目录只有脚本时跳过（新工作区不该一跑就红），一旦铺了三档就照任务目录检查——正是这条抓出了 20 条指向旧路径的死链。旧名硬跳过是这些死链能活到今天的原因。
- **新增 `[题]`（判失败）**：H1 必须含任务目录名，中文别名写成 `# 目录名（别名）· 使用说明`。原先这条全靠人工守，实测 8 个目录 2 个对不上（含本 skill 自己的工作区副本，标题一直还写着旧名）。
- **`[空]` 加严第二层**：DESIGN「设计思路」的三列表**任一格留空**即失败。只判"整行三格全空"时 `| 用 A | 有理由 |  |` 是绿的，而漏的恰恰是最要紧的代价列。两列表照旧不判，避免误伤架构表。
- **`[链]` 现在也剥行内 `` `code` ``**（此前只剥 ` ``` ` 围栏）：三份文档为了说明这条规则，用行内反引号举 `[this](Status result)` 这个反例，被闸门判红 4 条——**规则误伤了写规则的人**。反引号定界符按**等长 run 配对**，因为文档里存在 ```` ```` ``` ```` `` 这种"反引号套反引号"的写法，简单成对匹配会配错位、把 span 漏出去。``[`x.md`](url)`` 这类 display 名带反引号的合法链接先解开再验，可达性覆盖没有因此缩小；格式例子要写成代码段（**两个**反引号包住，单反引号包不住含反引号的例子），散文里裸写的链接形状 `[文字](链接)` 就是一条点不开的死链、照报——2026-10-14 曾给"占位符"开过豁免，结果当场打穿了证明 span 生效的那条反向对照（夹具 c8），已撤销。`AGENTS.md` 的可达性豁免由并行会话的 commit `7c09c5b` 引入（规则正文里的示例链接不是真路径），本轮保留它；两条修叠加之后 `dsp-hal-eval` 才转绿。
- **去掉 GNU `date -d` 依赖**：过期天数改成纯 bash 的 civil→days 算法（与 `date -u` 对拍 14 组，含闰年、世纪年、`08`/`09` 这类零补齐日期）。对拍顺手抓出一个真 bug：`IFS=-` 拆出的 `08`/`09` 在 bash 算术里是非法八进制，不写 `10#` 时**八月、九月的日期会让 `[旧]` 判定直接报错**——今天恰好是 10 月，这条会一路绿到 8 月才炸。不做 PowerShell 版（`[空]/[档]/[链]` 全靠 grep/awk，两套逻辑必然漂移），也不挂 git hook（工作区不是 git 仓库；skill 仓库的 pre-commit 去检查别人的目录方向不对）。这两条待办按裁定关闭。
- 15 项夹具断言全过（`--root` 隔离根，跑完即删），含三条关键反向对照：半填行报 / 两列表不报、别名标题放行 / 纯标题报、行内代码里的假链接放行 / **同一段不写反引号照报**。全量闸门 ~11s。

- **新增第 6 条强制规则：输出前必须主动检查规则清单（Pre-output rules check, MANDATORY）**。起因是真实事故：agent 写方案时用代码格式 `` `文件名` `` 代替 `file:///` 链接，被用户指出。根因不是"图快"，是把输出当草稿写、没做规则符合性检查、依赖用户挑错。新增条款要求 agent 在输出任何涉及文件引用的方案/计划/文档变更前，强制过 artifact-links / chinese-doc-naming / complete-deliverables / self-audit 四项检查。写入 `SKILL.md` 的新章节"Pre-output rules check (MANDATORY)"，并更新 `description` 的第 (3) 条。此规则与 `feedback-self-audit-with-evidence` 互补：self-audit 是 reactive（被问时才检查），pre-output 是 proactive（输出前主动检查）。
- **规范从两档扩成三档：`README.md`（使用者说明）+ `DESIGN.md`（方案设计）+ `CONTEXT.md`（agent 交接）**。「设计思路」三列表从 README 搬到 DESIGN，README 只剩说明所需的五节。动因是同一件事的两次重复：3178 的 README 被批"太繁琐、加了很多无谓的东西"，而它推上 GitHub 后读者要的确实是"我怎么用"。归档判据一句话：**这条结论半年后还成立吗？** 成立进 DESIGN，不成立进 CONTEXT。闸门同步：`[缺]/[构]` 查三档、`[空]` 从只判 README 改成**三档任一表格留全空行都判**（原先它顺带抓住了 README 的空产物表，拆档后不许松开）、`[期]` 改成**三档日期必须同日**、`[名]` 豁免 `DESIGN.md`。规则块标题随之改成「任务三档规范」，**幂等标记同时接受旧标题**（正则 `任务[双三]档规范`），免得留着旧标题的工作区被追加第二份规则块。
- **`[链]` 的链接形式放宽到「`file:///` 或仓库相对链接」，可达性同时收紧到两种形式都验**。起因是一个真实后果：任务目录推上 GitHub 后，README 里的 `file:///D:/...` 对读者全是死链，而闸门只认这个前缀——等于规矩在把文档往错的方向推。放宽只放在"产物节有没有可点的东西"这一条上，断链检测反而比旧版更强（相对链接按**文档自身目录**解析）。反向验证做过：一条断掉的相对链接当场报红；同一段 C++ lambda 写在 ```` ``` ```` 围栏里放行、不写围栏报红，证明放行是围栏在起作用而不是提取器没看见。
- 顺带修掉一处假阳性：`[this](Status result)` 这类代码里的 `](...)` 会被当成链接（2026-10-14 在一份 C++ 架构文档上误报）。现在 `check_links` 先剥掉 ```` ``` ```` 围栏再提取。
- **一条流程错误，值得所有 agent 记**：这次改动我先落在了 `D:\agent_workspace\tools\check-docs.sh` 上——那是 `install-everywhere.ps1` 第 ③ 步的**下游副本**，真源是 skill 的 `scripts/check-docs.sh`。谁之后跑一次铺满，我的改动就会被旧版原地覆盖。规矩本来就写在门上（"skill 一改必跑 install-everywhere.ps1"），方向却是反的：**改闸门要改 skill 里那份，再铺满**。

**2026-10-12**

- **规矩的适用范围写进 `description` / `when_to_use`**：任意工作目录、每一次会话都生效，明确禁止以"当前目录不在 agent workspace"为理由跳过聊天链接规则与收工 `CONTEXT.md` 更新——实测确有 agent 这样绕过过。
- 新增 `scripts/install-everywhere.ps1`（安装路径 F）。提交前修掉一处会坑其他 agent 的缺陷：递归复制没排除 `.git`，而真源目录本身就是 git 工作树，会把整个 `.git` 灌进另一个 agent 的技能目录。
- `[链]` 的反引号裸写检查补上"目录/文件改名后遗留的死链"分支；文档内的行号锚点一律改写进**链接文字**，不留 `#L42`。
- README 全局刷新：安装决策表把 **F 提为 Windows 多 agent 首选**、补 Codex 明示行，新增 **G（全局规则块 + 每日看门狗）**——回答「规矩能不能不靠 agent 自觉」：能，把闸门挂给调度器。A–E 保留：F 只覆盖 Windows 且会改其他 agent 的全局文件，单 agent / 非 Windows / 最小安装仍走原路。
- **新增铁律「更新即铺满」**（写入 `SKILL.md` 的 Propagation rule）：skill 无论本地改过还是 `git pull` 到更新，都必须立刻用 `install-everywhere.ps1` 覆盖本机所有 agent 的技能目录——只更新真源不铺满，其他 agent 下次会话就在跑旧规矩。配套改动：脚本 `-Source` 缺省改为**脚本自身所在的 skill 目录**（永远从最新那份里运行它）；真源克隆可装 `post-merge` 钩子让 pull 后自动铺满。
- README 再刷新：「更新即铺满」从变更日志升级为独立章节（规则 + 命令 + `post-merge` 钩子配方），「跟进方式」与「目录结构」改为强制引用该节。
- **自查出「铺满」自己的三个漏洞并修掉**（同日）：
  1. `install-everywhere.ps1` 第③步不铺它自己 → 工作区 `tools/` 那份长期停在旧版（实测 `d466de…` vs 真源 `30a4af…`，且旧版 `-Source` 仍硬编码别的 agent 目录，从工作区跑会拿错源当权威）。已把它加进 step③ 的同步清单。
  2. `.claude` 会被写入全局规则块 `CLAUDE.md`，却不在默认 `-AgentHomes` 里 → Claude 侧规则点名引用的 skill 根本没安装。已补进默认列表（本机实测新增 11 个文件）。
  3. 「更新即铺满」只写在 `SKILL.md` 和本页，**`references/agents-rule.md`（即各工作区 `AGENTS.md` 的规则块原文）整条缺失** → 只读 `AGENTS.md` 的 agent 压根不知道要铺。已补「真源与更新即铺满」一节，并写明**已有规则块的工作区只补不覆盖，条款变了必须手工同步那一份**（本机 `D:\agent_workspace\AGENTS.md` 已同步）。
- `SKILL.md` 的 Resources 节此前漏列 `install-everywhere.ps1`，已补；Propagation rule 增两条约束（铺满含其自身、工作区 `AGENTS.md` 不自动更新）。
- **已知未做**：`install-everywhere.ps1` 里写死的全局规则块（`$globalBlock`，5 条要点）与 `references/agents-rule.md` 是两份独立文本，改后者不会自动带动前者；等下一次规则稳定后统一成"从 agents-rule.md 截取要点"。

**2026-10-10**

- **`[链]` 由"仅告警"升级为失败项**，并新增 `[期]`（两档顶部「最近更新」必须一致）。起因是真实事故：agent 跑 `check-docs.sh | tail -2`，把告警行截掉当成全绿——**告警在没人逐行读输出时等于不存在**。从此文档里也写明"跑闸门不许加管道"。
- `[链]` 增加**可达性校验**：链接指向的文件不存在直接判失败（改名不更新引用会被当场抓住）；指向工作区之外的链接跳过，保证脚本能发给没有 `D:` 盘的人。顺带修掉 Linux 绝对路径的漏报，并把闸门从 38s 优化回 9s。
- 新增 `[名]`：顶层输出文档用纯 ASCII（英文）文件名判失败——读者是中文同事，文件要转发进群聊和飞书。
- 顶部日期**只认 blockquote 那一行**，修掉 `[新]`/`[旧]`/`[期]` 在正文里随便写个日期就蒙过的静默漏检。
- 产物链接改**双轨制**：文档内守 `file:///` 绝对路径，聊天回复在已验证支持跳行的宿主可用工作区相对 `#L` 锚点。

**2026-10-09**

- 首版：双档规范 + `init-task.sh` / `check-docs.sh` / `bootstrap.sh` 三脚本 + 两份模板；仓库落地页放 `.github/` 以保持 skill 根目录纯净。

## 依赖与注意事项

- 需要 bash（Git Bash / Linux / macOS 均可）。2026-10-14 起 `check-docs.sh` **不再依赖 GNU `date -d`**——过期天数改用纯 bash 的 civil→days 算法，BSD/macOS 的 `date` 也能跑。整个脚本仍是 bash，**纯 cmd / PowerShell 下没有对应实现**（刻意不做：两套判定逻辑必然漂移），Windows 请走 Git Bash。
- `install-everywhere.ps1` 仅 Windows（PowerShell 5.1+），运行加 `-ExecutionPolicy Bypass`；脚本含中文，**保存必须 UTF-8 带 BOM**——5.1 对无 BOM 文件按 GBK 误读，会把规则块判重逻辑整段搞坏（2026-10-12 实测）。
- 脚本不联网、不执行删除、不跑 git。它是脚手架与闸门，不是清理工具。
- 文档与默认值里出现的 `D:/agent_workspace`、`C:/Users/…` 只是本机示例路径。非本机首次使用**必须显式传 `--root`**，否则 `check-docs.sh` 会静默检查一个不存在的目录。
- 工作区脚本副本目录（新名 `multi-agent-task-handoff/`，旧名 `tools/`）是**同步副本**，真源在本仓库。只改副本会在下次 `bootstrap.sh --force` 时被覆盖；改逻辑请改仓库再重同步。两套名字都被 root 解析与跳过逻辑接受，`bootstrap.sh` 遇到已有 `tools/` 的工作区沿用旧名，不会一次铺出两份脚本。
- 工作区 `AGENTS.md` 里的规则块标题是 `bootstrap.sh` 与 `install-everywhere.ps1` 的幂等标记。2026-10-14 规范从两档扩成三档、标题改成「任务三档规范」，**标记同时接受旧标题**（正则 `任务[双三]档规范`）——否则留着旧标题的工作区再跑一次铺满就会追加出第二份规则块。新建工作区拿到的是新标题。

## 这份说明为什么在 `.github/` 而不是仓库根

本仓库的根目录**就是** skill 目录本身：clone 到 `~/.qoder-cn/skills/` 时，根目录应当只有 `SKILL.md` 和它引用的 `scripts/`、`references/`、`assets/`。而 skill 规范禁止文档类附属文件（`README` / `CHANGELOG` 之类），所以这份说明放在 `.github/`——GitHub 查找 README 的优先级是 `.github` > 根目录 > `docs`，渲染效果完全一样，但不污染 skill 结构。

根目录只允许一个非 skill 文件：`.gitattributes`（`* text=auto eol=lf`）。它不能删——仓库里是 bash 脚本，而 Windows Git 默认 `autocrlf=true`，一旦转成 CRLF，脚本里的 `then` 带回车会让接收方直接语法报错。
