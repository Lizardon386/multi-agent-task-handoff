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

它会铺好 `<工作区根>/tools/`（init + check 脚本）和 `tools/templates/`，并把规则章节追加进 `<工作区根>/AGENTS.md`。`AGENTS.md` 不存在就创建，已含规则块则不动（幂等，可重复跑）。

如果你的 agent 读的不是 `AGENTS.md`（比如 `CLAUDE.md`、`.cursorrules`）：把 `references/agents-rule.md` 的内容整段粘进那个文件即可——那就是规则块的原文，与 `bootstrap.sh` 追加的完全一致。

> **注意这条路同样带上产物链接规则。** `agents-rule.md` 里含「产物链接（强制）」一节，所以只读 `AGENTS.md`、从不加载 `SKILL.md` 的 agent，一样会被要求把产物写成 `[名字](file:///绝对路径)` 可点链接。别以为走 D 就只拿到双档结构。

### E. 完全没有加载机制

两条路：

1. **让 agent 执行安装**——直接把这句话丢给它：
   > 运行 `bash <skill目录>/scripts/bootstrap.sh --root <工作区根>`，然后每次改完产物后运行 `<工作区根>/tools/check-docs.sh`，退出码 0 才算本次任务结束。

   规则已经写进该工作区的 `AGENTS.md`，后续会话只要读得到就会被约束。

2. **纯 prompt 投喂**——把 `references/doc-spec.md`（规则全文，含章节顺序、命名禁令、分工红线、**产物链接要求**、边界特例）整篇贴进系统提示或项目指令里。这份是自包含的，不依赖脚本也能执行，只是没有闸门兜底。

### F. 本机装了多个 agent（Windows 一次铺满）

一条命令把 skill 同步进每个 agent 的技能目录、给有全局指令文件约定的 agent 追加规则块、并给每个工作区铺 `tools/` + `AGENTS.md`：

```powershell
powershell -NoProfile -File <skill目录>\scripts\install-everywhere.ps1 `
  -Source <真源skill目录> -WorkspaceRoots D:\agent_workspace
```

幂等、可重复跑，**只补不删**：已存在同名文件才按 MD5 比对更新，规则块靠「任务双档规范」标记判重（与 `bootstrap.sh` 同一把锁），所以不会追加出第二份。默认覆盖 `.codex` 与 `.qoder-cn` 两个 agent 家目录，`.codex/AGENTS.md`、`.claude/CLAUDE.md` 会被写入全局规则块——**不想改别的 agent 的全局指令文件就别跑它**，改用 `bootstrap.sh` 只铺工作区。

运行需加 `-ExecutionPolicy Bypass`（默认策略拦未签名脚本）。脚本含中文，**文件必须保持 UTF-8 带 BOM**：Windows PowerShell 5.1 把无 BOM 的中文按 GBK 误读，轻则「任务双档规范」判重失效、追加出重复规则块，重则直接语法报错——2026-10-12 实测踩过，脚本已内置防御（显式 UTF-8 读写），但二次编辑后请保持 BOM。

### G. 全局规则 + 每日看门狗：让规矩不依赖 agent 自觉

skill 与 `AGENTS.md` 解决的是「agent 读不读得到」；读到了仍可能不执行——实测有 agent 以「当前目录不在 agent workspace」为由绕过聊天链接规则。两层补丁：

1. **全局规则块（每次会话必读层）**：Codex 必读 `~/.codex/AGENTS.md`，Claude Code 对应 `~/.claude/CLAUDE.md`。走 F 会自动写入；手工装就把 `references/agents-rule.md` 的要点压成 5 条贴进去。规则块里点名「禁止以当前目录不在工作区为由跳过」，把这个借口预先封死。
2. **定时巡检（终审权交给调度器）**：把 `check-docs.sh` 挂成每日任务，全绿则安静、转红才通知——闸门从「agent 收工时自觉跑」变成「调度器每天一定跑」。Codex 自动化（heartbeat/cron）直接给提示词：「跑 `check-docs.sh` 不加管道，全绿保持安静，转红用 `file:///` 链接报告违规」；Windows 任务计划 / Linux cron 同理，退出码非 0 即告警。
### 装完生效的是哪几条

不管走 A–F 哪条，最终约束 agent 的都是同样五条（详见下一节「它强制了什么」）：

1. 每个任务目录同时有 `README.md`（面向使用者）和 `CONTEXT.md`（面向下一个 agent），六节顺序固定、不许删；
2. `设计思路` 必须是「决策 / 理由 / 代价」三列表，只写结论不写代价视为没写；
3. **向用户呈现的文件一律写成可点击链接 `[名字](file:///绝对正斜杠路径)`**，裸文件名和反引号路径点不开；
4. **除双档与 `AGENTS.md` 外的输出文档必须中文命名**（`设计总览.md` 而非 `design-overview.md`）；与双档职责重复的说明/进度文件仍然禁止；
5. 收工前 `check-docs.sh` 退出码 0 才算本次会话结束。

差别只在**由谁兜底**：A/B/C 是 agent 主动加载 skill；D/E 是规则落进 `AGENTS.md`、靠 agent 读到该文件被动生效，所以 D/E 建议把第 5 条的自检当成硬闸门来要求。

补充：2026-10-12 起 `SKILL.md` 的 `description` 已改为**每一次会话、任意工作目录无条件触发**，并点名「当前目录不在 agent workspace」为无效借口。A/B/C 类 agent 只要装了 skill，聊天链接规则与收工 `CONTEXT.md` 更新即默认生效——不再有「换个目录就不算数」的缝隙。

### 装完验证一次

```bash
bash <工作区根>/tools/check-docs.sh --root <工作区根>   # exit 0 说明闸门可用
bash <工作区根>/tools/init-task.sh smoke-test          # 应报 [空] 不合规——拦空骨架是它的职责
rm -rf <工作区根>/smoke-test                           # 清掉测试目录
```

## 它强制了什么

**两份文档，职责不许混。**

| 文件 | 读者 | 回答的问题 | 变化频率 |
|---|---|---|---|
| `README.md` | 用户 | 这是什么、**为什么这么设计**、怎么用 | 稳定，设计或用法变了才改 |
| `CONTEXT.md` | 下一个 agent | 做到哪了、还剩什么、有什么坑 | **每次会话都要改** |

进度、验证记录、待办只准写 CONTEXT；设计取舍与操作步骤只准写 README。两边都需要的硬事实（端口、路径、磁盘要求）在 CONTEXT 里一行引用、不重述——否则必然失同步。

**章节顺序固定，六节不许删。**

- `README.md`：一句话说明 → 设计思路 → 快速开始 → 使用说明 → 产物与目录 → 限制与注意事项
- `CONTEXT.md`：背景与目标 → 当前状态 → 计划 / 待办 → 关键约束与注意事项 → 变更记录 → 给下一个 agent 的追加区

**`设计思路` 必须是「决策 / 理由 / 代价」三列表。** 只有结论没有代价的表等于没写——这是硬要求，空表会被闸门拦下。

**所有产物写成可点击链接，且链接必须能打开。** 向用户呈现的文件一律是 `[名字](file:///绝对正斜杠路径)`；裸文件名和反引号路径在侧边栏点不开。行号写在链接文字里，不用 `#L` 锚点。`[链]` 同时校验可达性——**改名而不更新引用会直接判失败**，指向工作区之外的链接则跳过（脚本要能发给没有 `D:` 盘的人）。

**其他输出文档必须中文命名。** `README.md` / `CONTEXT.md` / `AGENTS.md` 是固定名不许翻译；除此之外，任务目录里真正属于交付物的文档（设计稿、评审意见书、决策件、评估报告）一律中文名，如 `设计总览.md`、`归属决策件.md`——读者是中文同事，文件要转发进群聊和飞书，英文名对方得先猜是哪个。被禁的是**与双档职责重复**的说明/进度文件（`使用说明.md`、`进度.md`、`notes.txt`），不是"多一个文件"本身。豁免：非 `.md` 交付物（`.docx` / `.pdf` 须与供应商原件同名）、`_` 前缀机器产物、`archive/` 与 `inputs/` 子目录、脚本代码。

## 日常用法

```bash
bash tools/init-task.sh <任务名>              # 开新任务：建目录 + 铺两份骨架
bash tools/check-docs.sh                      # 收工闸门：全量验收
bash tools/check-docs.sh my-task              # 只查一个任务
bash tools/check-docs.sh --root E:/other_ws   # 换工作区根（或 export AGENT_WS_ROOT=…）
```

`check-docs.sh` **退出码 0 才算本次会话收尾完成**。检查项前缀：

| 前缀 | 含义 | 是否导致失败 |
|---|---|---|
| `[缺]` | 文件不存在 | 是 |
| `[构]` | 缺章节 | 是 |
| `[占]` | 模板占位符没替换 | 是 |
| `[空]` | 骨架未填（空取舍表、空待办、缺日期） | 是 |
| `[新]` | 顶部缺「最近更新：YYYY-MM-DD」 | 是 |
| `[链]` | 「产物与目录」没有可点击链接，**或**链接指向的文件不存在 | **是**（2026-10-10 由告警升级） |
| `[名]` | 顶层输出 `.md` 用了纯 ASCII（英文）文件名 | **是** |
| `[期]` | 两档顶部「最近更新」日期不一致 | **是** |
| `[旧]` | 超期未更新（`STALE_DAYS` 可调，默认 30 天） | 否，仅告警 |

只有超期保持告警：已完结的任务本就该停在最后改动那天，历史文档也不可能一夜改净——硬失败只会让人直接绕过整个检查。缺链接与日期不同步则是要守的东西本身，放过去就等于没有这条规矩。

**跑闸门不要加管道。** `check-docs.sh | tail -2` 只会留下结尾那句 `OK`，把前面的 `[链]`/`[旧]` 违规行全部截掉——这是真实发生过的自审失真，别在自己身上重演。

## 目录结构

```
SKILL.md                    skill 入口：工作流、必备章节、产物链接规则
scripts/init-task.sh        建任务目录 + 铺双档骨架
scripts/check-docs.sh       合规闸门
scripts/bootstrap.sh        把整套规矩装进任意工作区根（--force 可重同步副本）
scripts/install-everywhere.ps1  Windows 一次铺满本机所有 agent 的技能目录 + 全局规则 + 工作区（见安装 F）
references/doc-spec.md      规则全文：命名禁令、分工红线、产物链接、边界特例、为什么要有这条规矩
references/agents-rule.md   bootstrap 追加进工作区 AGENTS.md 的规则块原文
assets/README.md.tpl        使用者文档骨架
assets/CONTEXT.md.tpl       agent 交接档案骨架
.github/README.md           本文件（仓库落地页，不属于 skill 内容）
.gitattributes              锁 eol=lf，见末节
```

`SKILL.md` 是给 agent 执行用的；`references/doc-spec.md` 是要质疑或修订规矩时才读的全文。

## 最近更新

跟进方式：`git -C <skill目录> pull`；本机多 agent 时用安装 F 的 `install-everywhere.ps1` 一次铺满。

**2026-10-12**

- **规矩的适用范围写进 `description` / `when_to_use`**：任意工作目录、每一次会话都生效，明确禁止以"当前目录不在 agent workspace"为理由跳过聊天链接规则与收工 `CONTEXT.md` 更新——实测确有 agent 这样绕过过。
- 新增 `scripts/install-everywhere.ps1`（安装路径 F）。提交前修掉一处会坑其他 agent 的缺陷：递归复制没排除 `.git`，而真源目录本身就是 git 工作树，会把整个 `.git` 灌进另一个 agent 的技能目录。
- `[链]` 的反引号裸写检查补上"目录/文件改名后遗留的死链"分支；文档内的行号锚点一律改写进**链接文字**，不留 `#L42`。
- README 全局刷新：安装决策表把 **F 提为 Windows 多 agent 首选**、补 Codex 明示行，新增 **G（全局规则块 + 每日看门狗）**——回答「规矩能不能不靠 agent 自觉」：能，把闸门挂给调度器。A–E 保留：F 只覆盖 Windows 且会改其他 agent 的全局文件，单 agent / 非 Windows / 最小安装仍走原路。

**2026-10-10**

- **`[链]` 由"仅告警"升级为失败项**，并新增 `[期]`（两档顶部「最近更新」必须一致）。起因是真实事故：agent 跑 `check-docs.sh | tail -2`，把告警行截掉当成全绿——**告警在没人逐行读输出时等于不存在**。从此文档里也写明"跑闸门不许加管道"。
- `[链]` 增加**可达性校验**：链接指向的文件不存在直接判失败（改名不更新引用会被当场抓住）；指向工作区之外的链接跳过，保证脚本能发给没有 `D:` 盘的人。顺带修掉 Linux 绝对路径的漏报，并把闸门从 38s 优化回 9s。
- 新增 `[名]`：顶层输出文档用纯 ASCII（英文）文件名判失败——读者是中文同事，文件要转发进群聊和飞书。
- 顶部日期**只认 blockquote 那一行**，修掉 `[新]`/`[旧]`/`[期]` 在正文里随便写个日期就蒙过的静默漏检。
- 产物链接改**双轨制**：文档内守 `file:///` 绝对路径，聊天回复在已验证支持跳行的宿主可用工作区相对 `#L` 锚点。

**2026-10-09**

- 首版：双档规范 + `init-task.sh` / `check-docs.sh` / `bootstrap.sh` 三脚本 + 两份模板；仓库落地页放 `.github/` 以保持 skill 根目录纯净。

## 依赖与注意事项

- 需要 bash + GNU coreutils。`check-docs.sh` 用了 `date -d`，**纯 cmd / PowerShell 下不可用**，Windows 请走 Git Bash。
- `install-everywhere.ps1` 仅 Windows（PowerShell 5.1+），运行加 `-ExecutionPolicy Bypass`；脚本含中文，**保存必须 UTF-8 带 BOM**——5.1 对无 BOM 文件按 GBK 误读，会把规则块判重逻辑整段搞坏（2026-10-12 实测）。
- 脚本不联网、不执行删除、不跑 git。它是脚手架与闸门，不是清理工具。
- 文档与默认值里出现的 `D:/agent_workspace`、`C:/Users/…` 只是本机示例路径。非本机首次使用**必须显式传 `--root`**，否则 `check-docs.sh` 会静默检查一个不存在的目录。
- 工作区里的 `tools/` 是**同步副本**，真源在本仓库。只改副本会在下次 `bootstrap.sh --force` 时被覆盖；改逻辑请改仓库再重同步。
- 工作区 `AGENTS.md` 里的章节标题「任务双档规范」是 `bootstrap.sh` 的幂等标记，**不要改名**——改了会让已装过的工作区再跑一次 bootstrap 就追加出重复规则块。

## 这份说明为什么在 `.github/` 而不是仓库根

本仓库的根目录**就是** skill 目录本身：clone 到 `~/.qoder-cn/skills/` 时，根目录应当只有 `SKILL.md` 和它引用的 `scripts/`、`references/`、`assets/`。而 skill 规范禁止文档类附属文件（`README` / `CHANGELOG` 之类），所以这份说明放在 `.github/`——GitHub 查找 README 的优先级是 `.github` > 根目录 > `docs`，渲染效果完全一样，但不污染 skill 结构。

根目录只允许一个非 skill 文件：`.gitattributes`（`* text=auto eol=lf`）。它不能删——仓库里是 bash 脚本，而 Windows Git 默认 `autocrlf=true`，一旦转成 CRLF，脚本里的 `then` 带回车会让接收方直接语法报错。
