# multi-agent-task-handoff · 会话上下文与进展

> 本文件是任务交接档案，供 Qoder / ZCode / 其他 agent 实时跟进。改动产物后请更新「当前状态」「变更记录」。
> 最近更新：2026-10-15（Qoder）
> 面向使用者的说明见同目录 `README.md`，工具自身的设计取舍与契约见 `DESIGN.md`。

## 背景与目标

`D:\agent_workspace` 要求每个任务子目录都有**三档**文档：`README.md`（使用者视角：怎么跑、有什么限制）、`DESIGN.md`（评审/二次开发视角：为什么这么设计、已定语义）、`CONTEXT.md`（agent 视角：上下文 + 计划 + 进展）。本目录提供把这条规矩落到实处的最小工具：骨架生成 + 合规自检，避免"规范写在 AGENTS.md 里但没人执行"。

## 当前状态

- 2026-10-08 创建，本会话内完成并验证：
  - [README.md.tpl](assets/README.md.tpl)、[CONTEXT.md.tpl](assets/CONTEXT.md.tpl) 六节骨架；
  - [init-task.sh](scripts/init-task.sh) 生成骨架（已实测：建目录、注入任务名与当天日期、已存在文件不覆盖）；
  - [check-docs.sh](scripts/check-docs.sh) 检查文件存在性、章节完整性、模板占位符、空骨架、顶部「最近更新」日期，`STALE_DAYS`（默认 30）控制过期告警；
  - 已对全工作区跑通：5 个任务目录（ai-model-transfer / opengrok-transfer / uno-online / uno-webgame / vhal-hld-rewrite）全部 exit 0。
- 检查器对**自身脚手架**的拦截已验证：刚生成的空骨架会被 `[空]` 判不合规，填完才通过。
- 2026-10-09 加「产物链接」规矩 + `[链]` 检查项，已 `bootstrap.sh --force` 从 skill 同步到本目录。**（当时记为"只告警不失败、不做批量改写"——该结论已于 2026-10-10 作废，见下面那条加严记录：`[链]` 现在是失败项，且全工作区历史目录已一次性改净。）**

## 计划 / 待办

- [x] ~~`check-docs.sh` 目前要求任务名目录与文档标题里的名字**人工保持一致**，可加一条自动比对~~ → 2026-10-14 落地为 `[题]`（判失败）：H1 必须含目录名，中文别名写成「目录名（别名）· 使用说明」
- [x] ~~未做内容质量检查（例如「设计思路」表是否真的有取舍）~~ → 2026-10-14 只加到**结构**这一层：DESIGN「设计思路」三列表任一格留空即 `[空]`。**语义质量仍刻意不查**——"这条取舍是不是废话"没有零误报的判法，加上去只会逼人绕过闸门
- [x] ~~未接 git hook（工作区当前不是 git 仓库）~~ → 2026-10-14 按裁定**关闭且不做**：工作区不是 git 仓库；skill 仓库的 pre-commit 去检查别人的任务目录方向不对。**2026-10-15 装的两个钩子不是翻这个案**：它们是 `post-merge`/`pre-push`，只做「铺满」这一件与目录合规无关的事；"收工必跑闸门"仍靠规则约束，没有提交级强制。
- [x] ~~「改了没铺」只靠 agent 自觉，机制上没人守~~ → 2026-10-15 两层兜底落地：`pre-push` 钩子在推送前铺满（脏树跳过、真失败阻断 push），`scripts/watchdog.sh` 挂 Windows 每日计划任务比对副本与工作树。**残留的小窗**：工作树脏时 pre-push 不铺（等下次干净推送或看门狗），以及本机 commit 后不 push 的那段——已由看门狗按天兜住。
- [x] ~~跨平台：`date -d` 依赖 GNU date~~ → 2026-10-14 去掉该依赖（纯 bash civil→days 算法，与 `date -u` 对拍 14 组）。**不做 PowerShell 版**：`[空]/[档]/[链]` 全靠 grep/awk，两套判定逻辑必然漂移，等于造第二个真源
- [x] ~~`[链]` 的可达性校验只覆盖 README「产物与目录」~~ → **这条待办的前提早已过期**：`check_links` 是 `find "$dir" -name "*.md"` 全目录递归，CONTEXT 变更记录与交付物正文本就在查（2026-10-12 那次"闸门放过死链"是围栏/行内代码剥离之前的旧行为）。本轮真正的缺口在反方向——**假阳性**，已修（见变更记录）
- [x] ~~**安装器只补不删**：仓库里删掉的文件在各副本里留着~~ → 2026-10-14 实现 `-Prune`（先列待删清单再删，`-Prune -DryRun` 只列不删），作用域限两个受管子树、真源目录拒绝执行、不碰任务目录与 `AGENTS.md`。**同日留下的那个小坑已于 2026-10-15 关掉**：`post-merge` 钩子现在默认带 `-Prune`，pull 那一趟就顺手清残留，不再需要手动补跑（脚本自身的手动调用仍是保守的"只补不删"，见 [DESIGN.md](DESIGN.md) 的「设计思路」）。
- [ ] 遗留：`.review/` 归档记录与若干历史「变更记录」行里仍写着旧路径 `D:/agent_workspace/tools/…`。**历史记录不改写**（那是当时事实），但读的人会以为是现行路径——下次有人踩到再考虑在 `.review/` 里放一行说明
- [x] 本机两份全局规则文件（`~\.codex\AGENTS.md`、`~\.claude\CLAUDE.md`）**没有出处戳**：它们是 2026-10-15 之前的手抄，比源头多了几条 Codex 特有的告诫（复合名 `[档]`、`| tail` 假绿灯、`path:line` 禁令）——**那些措辞已先上收进 `agents-rule.md` 的 global-block 段**，所以重写不会丢东西。迁移脚本已就位：`powershell -NoProfile -ExecutionPolicy Bypass -File scripts\sync-global-rules.ps1`（默认 DryRun 只报告，`-Apply` 才写并先留 `.bak-<时间戳>`）。**用户要自己执行**，所以我没跑 `-Apply`。DryRun 报告里有一处要人自己定：`.codex` 那份第 5 行的「权威来源：…（`~\.codex\skills\…\SKILL.md`）」会被换掉——新版第 1 条只说"先读它的 `SKILL.md`"、不带绝对路径；想把路径长期留住，写在**锚点标题之上**，脚本永久保留那一段。
  → **2026-10-15 20:31 用户自己跑了 `-Apply`，我这面复验过**：两份都带戳 `@ 3208e4b`（== 源头当前 sha），`watchdog.sh` 的 `[出处]` 从"无出处戳"变「与原文同步」，备份各在 `AGENTS.md.bak-20261015-203113` / `CLAUDE.md.bak-20261015-203113`；`.codex` 那句带绝对路径的"权威来源"如预告被换掉（第 1 条改成"先读 `SKILL.md`，再读 `references/agents-rule.md`"，不带路径），要找回看 `.bak`。派生文件与源头之间的第二真源到此清零。
- [ ] **探针噪声**：入口模式的 `AGENTS.md` 被 `[出处]` 报成"无出处戳（下次重写才会带上）"，但它**永远不该有戳**（里面没有派生条款，戳只会误导）。改成：命中入口锚的文件 `[出处]` 打「不适用（入口模式）」。（三行改动，下次动 `watchdog.sh` 时顺手做）
- [ ] 入口模式的那 9 行本机政策**彻底没有兜底**（不在 git、闸门不查、探针只管锚与指针）。要兜只能上 C 方案：`D:\agent_workspace` 起仓库、`.gitignore` 只放行根级规则文件。这会改掉"工作区不是 git 仓库"这个前提，等用户点头。
- [ ] 遗留：`watchdog.sh` 的三条边界（名单全落空 exit 2、假 `HOME` 仍查到真名单、`C:\` 与 `C:/` 两种写法）是**手测**的，没进 `selftest.sh`——那个夹具只覆盖 `check-docs.sh`。要不要给看门狗单开一组断言（它带写文件与删自己产物的副作用，夹具得用临时根隔离），下次动它时再定。本轮的双锚 / 整行匹配 / 出处戳这三条判据同理，目前靠一次性沙箱实测（见变更记录），**没进夹具**。
- [x] ~~遗留：`strip_code` 是逐字符扫描，全量闸门从 ~9s 涨到 ~11s~~ → 2026-10-14 的性能改造已把它连带解决（每目录 4 次进程，真工作区 ≈0.9s）。剩下的代价只有一条：合并成单次 awk 后，判定语义只能靠夹具与变异测试守，不能靠读代码。

## 关键约束与注意事项

- **本会话的职责边界（2026-10-15 用户定）**：只管这个 skill 仓库的维护。别的任务目录里的事——它们的 git 与否、副本残留、文档改动、`tools/` 里有什么——**不介入、不评价、不建议**；只有当那个会话把"与本 skill 有关的结论"发过来（交接）时才算我的活。理由：范围一放开就变成"出了问题无尽兜底"，每发现一个边角就加一条检查，成本全落在后续每次改动上。
- **不要再提"防御性检查"**（例：给闸门加 `[拷]` 查任务目录里的脚本副本、给工作区根加仓库做快照）。这类提案默认撤回，除非用户点名要。判断标准是这条纪律：**一条新检查要能被存量改净、要被夹具钉住、要永久维护**——收益盖不住这三笔开销才做。

- **判重锚是一把锁的两份钥匙（2026-10-15）**：老锚 `任务[双三]档规范` + 新锚**整行** `^<!-- agents-entry -->$`，`bootstrap.sh`（bash grep）与 `install-everywhere.ps1`（PowerShell `-match`）各写一遍。**只改一处就会给某类工作区追加出第二份规则块**，而且新锚必须整行匹配——`agents-rule.md` 正文里就出现 `agents-entry` 这串字，裸子串会把"提到过锚"当成"装了锚"（该追加的不追加＝假绿灯）。
- **探针与安装器都只报告、不自动覆盖派生物**：`watchdog.sh` 的 `[出处]` 落后只告警。自动重写会连工作区自己写的「工作目录约定」那章一起冲掉，那是不可逆的本地数据。
- **入口模式只对"装了 skill 且 agent 会读 `SKILL.md`"的工作区成立**：README 的 D/E 档（没有 skill 机制、只读规则文件的 agent）那里 `AGENTS.md` 必须仍是整份——那是它们唯一的规矩来源。`bootstrap.sh` 默认整份、`--entry` 才是入口。

- **真源就是本目录（2026-10-14 起）**：`.git` 已从 `~/.qoder-cn/skills/multi-agent-task-handoff\` 移到这里，本目录是 skill 仓库的 git 工作树，布局是 `SKILL.md` + `scripts/` + `assets/` + `references/`（2026-10-14 同日删掉了多一份落地页 `.github/README.md`，合并进根 README）。三个 agent 的 skills 目录（`.qoder-cn`/`.codex`/`.claude`）与其它工作区的脚本副本目录**都是下游副本**，改它们等于等着被覆盖。改完的顺序固定：本目录改 → `git commit` + `git push` → 跑 `scripts/install-everywhere.ps1` 铺满。
- **本目录的三档（README/DESIGN/CONTEXT）随仓库一起提交**（用户 2026-10-14 裁定），所以它们是**公开可见**的：写的时候记住里面的本机路径与进度对别人没有意义，规范以 `SKILL.md` 与 `references/` 为准。GitHub 首页就是根 [README.md](README.md)——2026-10-14 把原 `.github/README.md` 合并进来删掉了（渲染优先级 `.github` > 根目录 > `docs`，前者不存在时首页落到根）。对外 changelog 在本文的「发布更新记录」节，README 里指过来。
- **跑闸门/建任务的命令在本目录多一层 `scripts/`**：`bash scripts/check-docs.sh`；下游工作区是扁平副本，写 `bash <副本目录>/check-docs.sh`。两种布局 root 解析都认，`…/skills/…`、`….codex…`、`….claude…` 下的那份**不**反推成工作区根。
- **`D:\agent_workspace\AGENTS.md` 已降级成"入口 + 指针"（2026-10-15，149 行 → 32 行）**：顶部「工作目录约定」那章本机政策照留，细则只指向工作树的 `references/agents-rule.md`。**别再往那儿贴全文规则块**——那正是我们刚甩掉的第二真源。它标题里的「任务三档规范」是安装器判重锚，改文件时必须留住那四个字，实测改完跑 `install-everywhere.ps1` 输出"工作区规则已存在，跳过"且行数不变才算对。**`dsp-hal-eval\AGENTS.md` 仍是全文副本**，而且**现在不在任何 git 里**（2026-10-15 该会话把 `.git` 迁到 `dsp-hal-eval\coding\android\vendor\chery\proprietary\ExtDsp\`，新仓库只跟踪 `dspcontrol-hal/`，外层 `dsp-hal-eval` 不再是仓库）——原先"漂了可回滚"的前提已经不成立，它和根级那份一样是裸文件，手工同步义务照旧、风险更高。
- **skill 仓库自 2026-10-09 起即 git 工作树**（私有仓库 `Lizardon386/multi-agent-task-handoff`，真源即发布源）：改完不推 = 别人拿不到；分发不走 zip/tar.gz（当年那个 `skill-export/` 目录已不在工作区，故此处不带链接——死链比裸名更坏）。
- **副本目录名是新的硬契约（2026-10-14）**：工作区脚本副本目录新名 `multi-agent-task-handoff`、旧名 `tools`，**四处**都得同时认：`check-docs.sh` 的 root 解析、`check-docs.sh` 的跳过名单（改成按内容判）、`init-task.sh` 的模板查找、`bootstrap.sh` + `install-everywhere.ps1` 的目标目录解析。少改一处就会出现"一次铺满铺出两份脚本"或"根退化成硬编码 D 盘"。手法与幂等标记 `任务[双三]档规范` 一致：新旧两名都接受，不做一刀切改名。
- **AGENTS.md 的章节标题是幂等标记**：`bootstrap.sh` 与 `install-everywhere.ps1` 都拿它判重、只补不覆盖。2026-10-14 标题从「任务双档规范」改成「任务三档规范」，标记同步改成正则 `任务[双三]档规范`**同时接受旧标题**——否则留着旧标题的工作区再跑一次就追加出重复规则块。以后改标题必须连脚本正则一起改。skill 自身改名与此无关。
- **章节名是硬契约**：`check-docs.sh` 的 `README_SECTIONS` / `DESIGN_SECTIONS` / `CONTEXT_SECTIONS` 与 `AGENTS.md` 各档章节顺序、`templates/*.tpl`（三份）三处必须同步改，改一处不改其余会让所有任务目录误判不合规。`[链]` 检查还额外硬编码了「产物与目录」这个节名（awk 靠它切章节范围），改节名要连 awk 正则一起改。
- 任务脚本**只补不覆盖**：`init-task.sh` 遇到同名 md 只打印跳过，没有 `--force`（`--force` 只属于 `bootstrap.sh`，且只作用于副本目录里的脚本与模板）。
- `check_doc` 用 `grep -qE "^## +.*<节名>"` 做子串匹配，正文里出现"设计思路"等字样的普通二级标题会被误判为已具备该节；新增节名时避免与既有正文标题重名。
- 跳过名单：`templates`、`node_modules`、`.git`（基础设施与素材）；脚本副本目录（`multi-agent-task-handoff` / `tools`）**只在没有 `README.md` 时**跳过——它铺了三档就照任务目录检查。**别顺手把任务目录加进跳过名单**，那等于关掉规矩。旧版是无条件跳过 `tools`，本目录改名后正好被那条放过 20 条死链，别再犯。
- `[链]` 提取链接前会剥掉 ` ``` ` 围栏与行内 `` `code` ``，**反引号按等长 run 配对**。改这段 awk 前先造一个 ```` ```` ``` ```` `` 的夹具——简单成对匹配在这种写法上会配错位，让本该被剥掉的 span 漏出来变成假阳性（本目录 README 就这么被自己判红过）。
- 不要在 `check-docs.sh` 里执行任何删除或 `git` 操作——它是验收闸门，不是清理工具。
- **`watchdog.sh` 与 `check-docs.sh` 是两类东西**：前者会写文件、删自己生成的待处理件、被计划任务调度，后者只读只判。**别把两者合并**，合并后"闸门"就带副作用了，别人发到别的机器上就不敢每次收工跑。
- **`watchdog.sh` 刻意不进工作区扁平副本清单**（`bootstrap.sh` 与 `install-everywhere.ps1` 那两处 6 个脚本的名单）：它比对的是"工作树 vs 副本"，铺到下游扁平副本里既没有 `.git` 也没有权威源，跑起来只会假报错。它随仓库走、由 `-Prune` 的镜像比对同步进三个技能目录。**要加新脚本进副本时三处名单一起改**，漏一处就会被 `-Prune` 当残留删掉。
- **看门狗的产物落在 `D:\agent_workspace\.watchdog\`**（`propagation.log` 追加、`_需要处理.md` 只在不绿时存在、绿了自动删）。这个目录**必须是点开头**：闸门的 `for taskdir in "$ROOT"/*/` 不匹配点目录，起了 `watchdog-log` 这种名字就会被当任务目录查、当场 `[缺]` 三档红。
- **`pre-push` 的脏树守卫不是可有可无**：铺满脚本拷的是**工作树**而不是 HEAD，脏树时 push 会把未提交内容铺进每个 agent 的技能目录。所以钩子里先 `git status --porcelain`，非空就跳过铺满只警告。

## 变更记录

- 2026-10-15 Qoder（本会话，**撤掉"让闸门查越出仓库根的链接"这条待办**，用户一个字"撤"）：理由按刚定的三笔账——存量今天刚好是 0 条（不是常态，是巧合）、脚本要新增"这个目录是不是 git 仓库"的分支并永久维护、夹具要造两套 + 加变异，而它防的只是"我自己又写了一条 `../` 链接"，手工 5 秒能改。**知识留下、检查不加**：`README` 的限制节仍写着"闸门绿 ≠ 链接点得开"的三种形态，`DESIGN` 的已定语义仍写着这条边界，谁写文档谁读一眼。至此待办从 5 条降到 4 条。

- 2026-10-15 Qoder（本会话，**用户划边界，撤掉一条我加多的东西**）：用户明确"不要加意义不大的规则，不然出了问题无尽兜底；本会话只关注本目录 skill 的维护，别的设计此 skill 的内容由那个会话发过来才算我的活"。据此**删掉刚加的待办 `[拷]`（任务目录里的第二份脚本副本 → 让闸门报错）**——它同时违反两条：范围越界（那是别的会话的目录）与"用新检查兜旧问题"。上一条记录里关于 `dsp-hal-eval/tools/` 的事实描述留着（那是观测记录，不是规则），但结论"建议加检查"作废。同时把这条边界写进「关键约束」，防止下次又顺手加。

- 2026-10-15 Qoder（本会话，**并行会话把 `dsp-hal-eval` 的 `.git` 迁走了，核现状 + 清我文档里的旧前提**）：
  ① 事实：`.git` 现在在 `dsp-hal-eval\coding\android\vendor\chery\proprietary\ExtDsp\`，新仓库根 = 那里，只跟踪 `dspcontrol-hal/`（21 个文件、工作树干净）；迁之前先把外层 407 项改动提交成终态（`b083904`），迁根是 `50b1d72`。`git -C dsp-hal-eval rev-parse` 现在直接 `fatal: not a git repository`。
  ② 用户猜"`tools/` 副本是这次迁移造成的"——**不对一半**：那份副本迁移前就在（停在 `7c09c5b` 版，即截图里的 `047dfa71`），是当年有人把 `dsp-hal-eval` 当工作区根跑安装器留下的。迁移改变的是它的性质：以前 5 个文件被外层仓库跟踪、旧版能从 `HEAD` 复活；现在外层不是仓库，`git show HEAD:tools/check-docs.sh` 在新仓库里已无此路径，**复活路径消失，代价是整个 `dsp-hal-eval`（含三档、`documents/`、它的 `AGENTS.md` 全文副本）彻底没有版本控制**。
  ③ 我这边跟着修：`CONTEXT` 关键约束里"dsp-hal-eval 那份在自己仓库里、漂了可回滚"这句已改成"现在不在任何 git 里"；新增一条待办记 `[拷]` 检查（任务目录里的第二份脚本副本，闸门现在看不见）与它的三个后果。
  ④ 全工作区扫描结论：除 `dsp-hal-eval/tools/` 外**没有第二处**（3178 / ai-model-transfer / douyin-shop-tax-study / opengrok-transfer / uno-online / uno-webgame 全 0），根级 `tools/` 也已不存在。

- 2026-10-15 Qoder（本会话，**规矩收回单一源头：入口模式 + 双锚 + 出处戳 + 探针**，用户拍板"AGENTS.md 只留政策，内容从源头跟踪"）：
  ① **承重墙先做**：判重从"只有标题锚"改成**双锚**——老锚 `任务[双三]档规范`、新锚**整行** `^<!-- agents-entry -->$`，`bootstrap.sh` 与 `install-everywhere.ps1` 两套实现一起改。为什么必须整行：`agents-rule.md` 正文自己就写着 `agents-entry` 这串字，裸子串会把"提到过锚"当成"装了锚"，于是**该追加的不追加**——正是这套东西最怕的假绿灯。
  ② 回归实测九条（真跑）：bootstrap 侧「入口文件重复跑不动 / 老式整份不动 / 无锚+`--entry` 报错且不写 / 无锚+整份追加并带戳 / 全新根生成入口壳」；ps1 侧「入口跳过 / 老式跳过 / 无锚只警告不灌 / 不存在则创建」；**两条反向对照**「删掉入口锚 → 立刻从跳过变警告」「散文里提 `agents-entry` → 不算锚」。过程中一条隐藏坑自己冒出来了：**PowerShell `-File` 会把多余的位置参数绑到第一个未按名绑定的参数**，我用 `-WorkspaceRoots a b c d` 时 `b` 成了 `$Source`，报"找不到 r-legacy\references\agents-rule.md"——不是脚本坏，是测试方法坏；一次传一个根才对。
  ③ **`$globalBlock` 这份第二真源被消掉**：第②步改为从 `agents-rule.md` 的 `<!-- global-block:start/end -->` 段截取，截不到直接 `throw`（绝不用脆弱正则猜着拼）。顺带修掉一个只有发给别人才暴露的缺陷：原先把 `~\.codex`/`~\.claude` **写死**在脚本里，别人机器上这步整体空转、全局规则文件根本没被写——现在按 `-AgentHomes` 的目录名推导。
  ④ **派生物一律带出处戳** `<!-- generated-from: references/agents-rule.md @ <sha> (日期) -->`；`watchdog.sh` 加 `[锚] / [出处] / [指针]` 探针（无锚、指针指向真源里不存在的文件＝失败；落后或无戳＝只告警——自动重写会把工作区自己写的政策那段冲掉，不可逆）。`_homes` 归一抽成 `norm_win` 复用，删掉重复的 `WS_ROOT` 计算。
  ⑤ 本机迁移：`D:\agent_workspace\AGENTS.md` 149 → **16 行**（9 行政策 + 锚 + 一行指针；连上一轮留的"三条硬要求"也删了——那句里的 `multi-agent-task-handoff/scripts/check-docs.sh` 在下游扁平副本里根本不存在，本身就是会漂的细节）。现存两份全局文件**没动**：重写别的 agent 的全局配置被策略拦了（拦得对），而它们比源头多了几条 Codex 特有告诫（复合名 `[档]`、`| tail` 假绿灯、`path:line` 禁令）——**已先上收进源头的 global-block 段**，所以源头不比派生物少东西，重写只是等用户点头。
  ⑥ `check-docs.sh` 结尾提示不再教人去 `$ROOT/AGENTS.md` 看「任务三档规范」（入口模式那里没有条款），改指 `references/agents-rule.md`。动了闸门文案就按验收线跑：`selftest.sh` **47/47**、`muttest.sh` **18/18 全部被抓到**。
  ⑦ **同类错误第三次**：用下一条 bullet 的开头当 `old_string`，把 DESIGN「手工同步已装 `AGENTS.md` 的判据」整条起句吃掉、尾句粘到新 bullet 上（本轮还有一次把标题改成了重复标题）。三次同一个模式，说明"改完回读 diff"这个提醒不够用——固定动作升级成：**改文档后立刻 `grep -n` 清点关键标题/判据短语的条数**，对不上当场修。已写进用户级记忆与本节。
  ⑧ 补一个**给人自己执行**的迁移工具 `scripts/sync-global-rules.ps1`（用户："1 给我个脚本我自己执行"）：把两份 agent 全局文件重写成源头当前的 global-block 段 + 出处戳。安全边界是设计重点——默认 DryRun 打印"保留第几行 / 删掉第几行 / 被删内容前 3 行"，`-Apply` 才动且先留 `.bak-<时间戳>`；只替换「第一个命中锚的标题行 → 文件末尾」，锚点之后若还有别的 `# ` 一级标题就中止不猜；有锚字样但不在标题行也拒绝动手；保留原文件 BOM 有无与换行风格；已带戳且 sha 相同就跳过。实测 DryRun 输出正确（`.codex` 保留 1-2 行、替换 3-12；`.claude` 保留 1 行、替换 2-11），并因此发现 `.codex` 第 5 行那条带绝对路径的"权威来源"会被换掉——已把这件事连同"想长期留住就写在锚点之上"写进待办。**它不进工作区扁平副本清单**（要读 `references/` 与 `git`，扁平副本里没有），BOM 已补并 `od` 验过 `ef bb bf`。

- 2026-10-15 Qoder（本会话，**工作区 `AGENTS.md` 从"第二真源"降级成入口**，用户问"还有必要存在吗"）：
  ① 先量化再判断，不凭印象：`AGENTS.md` 非空行 109，与 `references/agents-rule.md` **逐字相同 40 行**，其余"独有"多是同一条款的措辞变体（`### 分工红线` vs `### 分工红线（避免三档互相腐蚀）`、`### 边界与特例` vs `### 特例与边界`）；**真正独有的只有顶部「工作目录约定」9 行**（产物落点、别散到会话临时目录、别搬 `.qoder-cn` 缓存——本机政策，skill 里不该有，发给别人就没有 D 盘）。所以答案是"有必要存在，但没必要整份重复"。
  ② 改成 149 行 → **32 行**：顶部政策章照留 + 幂等锚警告 + 指向工作树/三份原文的路径 + 三条最易出事的硬要求（三档齐、文档内相对链接、收工跑闸门不加管道）+ 本工作区独有的历史事实（`内网部署说明.md` 已并入、`vhal-hld-rewrite` 的 `.docx` 是豁免不是漏改、`dsp-hal-eval` 改净 175 条链接、bootstrap 命令）。**收益是没有同步义务了**——以前每次改条款都得手工跟一次。
  ③ 危险点是幂等锚：安装器靠标题正则 `任务[双三]档规范` 判重，瘦身时把那四个字删掉就会让下次铺满**追加一整份第二块规则**。实测过：改完 `grep -cE` 命中 2 行，跑 `install-everywhere.ps1` 输出"工作区规则已存在，跳过"、文件行数不变。判据写进 DESIGN 的取舍表与 `agents-rule.md`（装了 skill 的工作区都可这么降级；**不加载 skill 的不行**，`bootstrap.sh` 给新工作区仍铺整份）。
  ④ 顺着用户提到的 `../AGENTS.md` 查出一个真缺陷并已改净：仓库历史上**从未提交过任何 `AGENTS.md` 内容**（`git log --all -- '*AGENTS.md'` 空），那些 `../AGENTS.md` 全是**链接**；而 `../` 越出仓库根的目标在 GitHub 上必然 404——README 落地页 2 条 + CONTEXT 历史行 3 条，改成指向 `references/agents-rule.md` 或去链接留文字。闸门不报它，因为它只验**本机**可达，这是"闸门绿 ≠ 链接点得开"的第三种形态，已记进 DESIGN 并留了待办（要不要让 `[链]` 在含 `.git` 的目录里拒绝越根链接）。
  ⑤ 我自己的一次 Edit 事故：给 CONTEXT 加"关键约束"那条时，`old_string` 用的是下一条 bullet 的**开头**，结果把 `- **skill 仓库自 2026-10-09 起即 git 工作树**` 整条的起句吃掉、尾句接到我的新 bullet 上。是**逐条 `git diff` 复核**时发现的（`grep -c` 原句 = 0 才暴露），已拆回两条。教训：**整行锚点插入必须回读 `git diff`**，别信"编辑成功"。
  ⑥ README 的「更新即铺满」与「限制与注意事项」两节重排版（用户点名的）：铺满那节从 6 条巨型 bullet 改成「谁触发」四行表 + `### 铺满那一趟刷了什么 / 已装的规则块不会被自动更新 / 只补不删是默认 / 钩子与计划任务的配方`，钩子按 ①②③ 编号、**把 `pre-push` 的脚本正文也贴进文档**（原先只描述不给配方，而 `.git/hooks/` 不被跟踪，换机器等于没有）；限制那节按 运行环境 / 谁会删东西 / 闸门拦什么 / 不能删的配置 / 根目录三份文档 分组，并把"闸门绿≠点得开"补成三种形态（选错形式、指向工作区外被跳过、`../` 越出仓库根在 GitHub 上 404）。200 行 → 260 行，删掉的 26 行全是被我拆行的旧 bullet 与缩进代码块，逐条 grep 验过事实都在。
  ⑦ 重排过程中的两次自伤，都靠"回读 diff / 回读标题"抓到：一次 `Edit` 用下一条 bullet 的起句当锚点，把「skill 仓库自 2026-10-09 起即 git 工作树」整条起句吃掉；一次想给标题前补空行时把 `old_string` 写成上一条的标题，**把「已装的规则块不会被自动更新」改名成了「只补不删…」的重复标题**。教训：单行锚点插入既会误删也会误改名，改完必须 `grep -n "^### "` 看标题列表 + `awk` 查标题前是否有空行，别信"编辑成功"。
  ⑧ 一处我自己造的历史瑕疵，记下来别装作没发生：上一条重排提交的 **subject 复用了更早那次提交的文案**（「docs: agents-rule 补上钩子带 -Prune 与 SKILL.md 豁免…」），而正文写的才是 README 重排。已经 push 出去，`--amend` 要 force-push 才生效——**不改**，宁可留着这条难看但真实的记录。规则：`git commit` 前回显 subject，并和 `git log -1 --format=%s` 对一眼，别把上次复制的模板当这次的标题。
- 2026-10-15 Qoder（本会话，**铺满的机械化：pre-push + 每日看门狗**，用户选 A+C、铺满失败阻断 push、调度走 Windows 任务计划）：
  ① 先答清语义：**`git commit` 到今天为止仍不触发任何东西**；能触发的只有别人 pull 时的 `post-merge` 和本机手动跑。所以补两层——`.git/hooks/pre-push`（推送前铺满 `-Prune`）与 `scripts/watchdog.sh`（每日比对副本 vs 工作树 + 跑闸门，只在有问题时写 `.watchdog/_需要处理.md`，全绿自动撤）。没选 `post-commit`：中间态规矩会被铺出去。
  ② `pre-push` 两条语义分开写死：工作树脏 → 跳过铺满、放行 push；铺满失败 → 阻断 push。前者是**正确性**要求（铺满拷工作树，脏树会把未提交内容当权威铺进每个技能目录），后者是**可执行性**要求（失败只打在一行没人看的通知里，等于回到"靠自觉"）。
  ③ `watchdog.sh` 起手就用 `SKILL.md` + `.git` 两个条件确认 `--source` 是**工作树**：从下游副本跑它，两边都旧，比结果是假绿灯——这正是本仓库反复出事的那类"看起来通过其实没执行"。默认名单是三个 agent 技能目录；不存在的目录打 `[跳过]` 不报错，脚本因此能发给别的机器/别的 agent 布局用。`diff -rq -x .git`（不用 `--exclude`，BSD diff 没这个长选项），全绿只写一行，出问题才落明细。
  ④ 先证它真会红：新增 `watchdog.sh` 自身还没铺满时跑一次 → 三处都报 `Only in …/scripts: watchdog.sh`、exit 1、待处理件生成。**能抓到自己才算数**。
  ⑤ 看门狗自己最容易造的假绿灯是"**一个副本都没比对，却报绿**"，两处加固：名单里目录全不存在 → `exit 2` 并明说"这是没查，不是绿"（计划任务里 `HOME` 常是 MSYS 的 `/home/<user>`，靠默认名单会整批落空，所以默认名单同时试 `HOME` 与 `USERPROFILE`，README 的注册命令则直接写绝对路径）；`--copies` 接受 `C:\…` 与 `C:/…` 两种写法并归一成 `/c/…`，否则手填反斜杠会让每个目录都"不存在"。三条都实测过：假 `HOME` 时真名单照样查得到、全不存在的名单 exit 2、两种写法都能比对。
  ⑥ 端到端跑通了一次真实闭环（不是沙箱）：10:40 计划任务未装、副本落后且 `dsp-hal-eval` 有一条并行会话留下的死链 → 看门狗写待处理件；随后并行会话自己把那条链接改净、我这趟 push 由 `pre-push` 自动铺满；10:44 `schtasks /Run` 触发计划任务 → 日志 `[绿]×3 + [闸门] 全绿`、**待处理件被自动撤掉**、`上次结果 0`。下次自动运行 2026-10-16 10:10。
  ⑦ 两个环境坑记下来：`schtasks.exe /Query` 从 Git Bash 直接调用会被 MSYS 把 `/Query` 转成 `D:/software/Git/Query`，要 `MSYS_NO_PATHCONV=1`；钩子与铺满的输出在 Git Bash 下会一半乱码（PowerShell 走 GBK、`sh` 的 echo 走 UTF-8，同一条流两种编码），不改 `OutputEncoding`（会连带影响 cmd），README 的限制节已写明。
  ⑧ 用户要求把结论通知另外两个会话并等读回：`d85b18c2`（dsp-hal-eval）与 `d8d34e7f`（3178，闸门交接的来向）。两边都自己复跑了我给的数（0.991s / 47 条 / 18 变异 / watchdog `[绿]×3`），**并各自打回了我一处**：d85b18c2 指出"qssi 未跟踪、Product.mk 未提交"是我发送前的旧快照，它已用 `eda7d01` 入库，所以它没照我做 `git add`；d8d34e7f 指出 `7c09c5b` 不是它提交的（它的只有 `2eb6a0a`、`5c6f3a6`，且都在 14:47 之前）——**已按它说的订正上面那行归属**。教训：给正在被别人写的仓库发通知，状态类断言要么发送前一秒重拍并标时间戳，要么写成"请你自己复核这条"的动作项；我已把这条补进用户级记忆 `feedback-cross-session-handoff`。
- 2026-10-15 Qoder（本会话，**`post-merge` 钩子默认带 `-Prune`**，用户定）：
  ① `.git/hooks/post-merge` 的铺满命令加上 `-Prune`。理由：钩子那趟无人值守，不带 prune 就等于「仓库删文件 → 之后有人手动去各副本清残留」这一步永远没人做；2026-10-14 合并落地页后那三份幽灵 `.github/README.md` 正是手动补跑才清掉的。脚本自身的手动调用保持"只补不删"的保守默认（要删自己加开关），`-Prune -DryRun` 仍只列不删；删除范围仍只有两个受管子树，真源目录拒绝执行。待删清单先打进输出再删，所以清单就在 `git pull` 自己的输出里。
  ② 配方同步到两个读面：[README.md](README.md) 的「更新即铺满」（三行改四行，并写明钩子文件不被 git 跟踪、换机器要重建、必须 LF）与 [SKILL.md](SKILL.md) 的 Propagation rule（新增一条带配方的 bullet）。`.git/hooks/` 本身不受 git 跟踪，所以**这次改动推不上去**——别人 clone 后照 README 那段自己建。
  ③ 顺带清掉三处过期散文：README 与 SKILL 里 prune 作用域写的"4 份脚本"改成实际的 6 份（`selftest.sh`/`muttest.sh` 已进清单）；DESIGN「问题与目标」还写着"约 11s"（性能改造后 ≈0.9s）；CONTEXT 关键约束里"GitHub 首页仍是 `.github/README.md`"（那份 2026-10-14 已合并删除）。待办两条收尾：`-Prune` 那个小坑关掉，`strip_code` 拖慢那条标记已被性能改造解决。
  ④ 验证：`selftest.sh` 47/47、`muttest.sh` 18/18、全量闸门无管道 exit 0、三处技能副本 `diff -r --exclude=.git` 为 0，并在真工作区实跑一次带 `-Prune` 的铺满确认输出为"无残留文件"。钩子本身用 `bash .git/hooks/post-merge` 直接执行验证（不靠下次 pull 才第一次跑），另种一个 `ghost-prune-test.md` 进 `.claude` 副本，确认钩子那趟先打「待删」清单再打「已删」——prune 真的咬。
  ⑤ **补做一处本应更早发现的漂移**（我先前判"不值"，查完已装块才看清代价与收益都估错了）：`D:\agent_workspace\AGENTS.md` 与 `dsp-hal-eval\AGENTS.md` 是 2026-10-14 手工同步过链接规矩的那两份，但**真源路径还写着 `~/.qoder-cn/skills/multi-agent-task-handoff\`**——那是 `.git` 搬走**之前**的位置。这条会咬人：agent 照它去 skills 目录改脚本，下次铺满静默覆盖，正是本仓库记过两次的事故。顺手把两份已装块与原文对齐：`[名]` 的固定名豁免从四个补成"四个 + `SKILL.md`"（原文 `agents-rule.md` 自己也没改，这是真源里的一处漏，已改）、`[链]` 补上"行内 `` `code` `` 也不验、反引号按等长 run 配对"、副本目录改成按内容判、`-Source` 缺省改成"脚本所在 `scripts\` 的上一级"、`bash tools/bootstrap.sh` 换成真实路径、并各加 `-Prune`/钩子那一条；两份末尾都标了"本章最后一次手工同步：2026-10-15"。工作区根 `AGENTS.md` **不在任何 git 仓库里**（`D:\agent_workspace` 不是仓库），改完只能落盘；`dsp-hal-eval` 自己是仓库（无 remote），单独提交。判断依据记进 [DESIGN.md](DESIGN.md)：旧文本导致**错误动作**才值得手改两份，纯补充说明不值得——这次是前者。

- 2026-10-14 Qoder（本会话，**闸门性能优化 + 夹具落地**，接 d8d34e7f 的交接）：
  ① 收下 `scripts/selftest.sh`（29 条断言）并扩到 **47 条**：新增 `[旧]` 告警、`days_from_civil` 与 `date -u` 的 12 组对拍、两列表边界（gap2col）与三列表半填（gaphalf）一对、未闭合反引号只报一次（spanopen，靠 `assert_count` 才钉得住）、等长 run 配对（spanrun）、代码段里的例子不验（quotecase）、`SKILL.md` 两条豁免（skillcopy）、正文日期不算顶部日期（nobodydate/holderbody）、副本目录按内容判的正反两面（multi-agent-task-handoff / tools）。再加一个**断言条数哨兵**（`EXPECT_ASSERTS`）——`10#` 那个变异让日期对拍中途崩掉时，断言数从 38 掉到 37 而 exit 仍是 0，正是这个哨兵把它揪出来的。
  ② 新增 `scripts/muttest.sh`：**18 个变异**逐条把闸门改坏，确认 selftest 每条都会红。它当场戳穿三个"看着有、其实不咬"的断言缺口（`substr` 长度回归、`prodlines>0` 条件、`SKILL.md` 豁免），也戳穿我自己两处错（夹具目录名写成 `toolsonly` 根本不是副本目录名；`gap2col` 的行插到了最后一节、等于没测）。**muttest 全部被抓到之前不提交。**
  ③ 性能：每目录进程数从上百次压到 **4 次**（三档判定一次 awk、链接一次、裸名一次、find 一次，存在性全走 bash 原生）。真工作区 **10.7s → 0.886s**，selftest 整轮 **36.5s → 6.4s**。合并过程中出过三个 bug（数组下标差一、`order` 传了带 `.md` 的标签、flag 键把空值写成 1），**全部是被"与基线逐字节比对"当场抓住的**，不是靠读代码——这条比对因此是验收线的一部分，不是可选项。
  ④ 删掉 `unwrap_links`：实测它对真链接是多余的（span 剥完剩 `](目标)` 照样抽到），对"两个反引号包住的格式例子"反而有害（把例子从代码里拽出来当链接验，本目录 6 条 `url` 假阳性就是这么造的）。删完输出仍与基线逐字节一致，quotecase 夹具钉住它别回来。
  ⑤ `selftest.sh` / `muttest.sh` 已加进 `bootstrap.sh` 与 `install-everywhere.ps1` 的同步清单（**三处清单必须一致**，否则 `-Prune` 会把少列的那个当残留删掉）；实测 bootstrap 铺完再跑 install-everywhere -Prune 报"无残留"，种一个 ghost 又能被抓到。

- 2026-10-14 Qoder（本会话，**真源搬进本目录 + 纠正产物链接规矩**）：
  ① **`.git` 从 `~/.qoder-cn/skills/multi-agent-task-handoff\` 移到本目录**，本目录成为 skill 仓库的 git 工作树；用 `git checkout -- .` 落地仓库布局（`SKILL.md`/`scripts/`/`assets/`/`references/`/`.github/`），删掉此前铺在这里的 4 份扁平脚本与 `templates/`（**删前逐一 md5 比对确认与 `scripts/`、`assets/` 字节一致**）。三档交接文档按用户裁定**一起提交**（曾打算 `.gitignore` 排除，用户说可以提交，故未加 `.gitignore`）。核对过 GitHub 渲染优先级是 `.github` > 根目录 > `docs`（官方文档原话），根 README 不会盖掉落地页——我先前那句"会被盖掉"是记反了，已纠正。
  ② 配套脚本改动：`bootstrap.sh` 与 `install-everywhere.ps1` 加"**副本目录 == 真源则跳过自铺**"守卫（否则会把扁平脚本铺到工作树根、与 `scripts/` 正主并存两份）；`check-docs.sh`/`init-task.sh` 的 root 解析新增仓库布局一层，并显式排除 `…/skills/…`、`….codex…`、`….claude…`（否则会把 `~/.qoder-cn\skills` 当工作区根去检查）；`-Source` 缺省因此变成"脚本所在 `scripts\` 的上一级"，从工作树跑即正确——搬布局前那个"不能从工作区副本启动"的陷阱**方向反了过来**。
  ③ **产物链接规矩纠正**（来自 dsp-hal-eval 会话 `d85b18c2` 的交接）：文档内一律**相对该文档自身目录**，`file:///` 只留给聊天面。旧口径"本机文档首选 `file:///`"是 2026-10-09 一次只测了聊天侧边栏的实测被外推的结果；用户在 markdown 预览面板复测：`file:///D:/...` 在 VSCode 预览报「文件不存在」（文件其实在）、在 Qoder 文档预览不渲染成链接，改相对后两个面都能跳。改动面：`SKILL.md`（frontmatter description + Artifact links 节 + Pre-output 清单）、`references/doc-spec.md`、`references/agents-rule.md`（各工作区 AGENTS.md 规则块原文）、`.github/README.md`、四份 `assets/*.tpl`。**闸门功能不动**——两种形式它都接受也都验可达，所以在 `doc-spec` 里补了一句"闸门绿不等于链接点得开"。反例清单加两条实测细节：`\[文字\](目标)` 转义方括号渲染成字面文本；链接文字以 `\` 结尾会把 `]` 转义、整条链接解析失败（本会话就被用户截图抓过一次）。
  ④ 本目录三档自己的 30 条 `file:///` 链接全部转成相对路径（历史「变更记录」行里那两条引用旧规矩的原文照留，是当时事实）。
  ⑤ **待手工同步**（installers 对已有规则块只补不覆盖）：`D:\agent_workspace\AGENTS.md` 与 `dsp-hal-eval\AGENTS.md` 里"本机文档首选 `file:///`"那句。
  ⑥ README 合并（根 README 与 `.github/README.md` 内容重复约七成）按用户裁定单独一个提交做，**已完成**：合并成根 README、删 `.github/README.md`，对外 changelog 全部挪进 CONTEXT，README 引用 CONTEXT 时提一句。

- 2026-10-14 Qoder（本会话，**副本目录改名 + 4 条待办落地 + 1 个真 bug**）：起手跑闸门发现 **exit 1、34 条 `[链]`**，与上一条会话记的"全量 exit 0"矛盾——`D:\agent_workspace\tools\` 已被改名成 `multi-agent-task-handoff\`（本目录），而写死旧名的地方遍布四处脚本与全套文档。用户定调「保住新名，改全套约定」，并批准 5 条待办全做。
  **改名落地（真源在 skill，本目录只是副本）**：`check-docs.sh` root 解析认 `tools|multi-agent-task-handoff`、结尾提示打印真实路径；`init-task.sh` 模板查找加新名；`bootstrap.sh` 与 `install-everywhere.ps1` 的副本目录解析统一为「已有旧名 `tools/` 且还没有新名 → 沿用旧名，否则用新名」，**否则下次铺满会另造一个 `tools/`，本目录变成没人认领的第三副本**；跳过名单改成**按内容判**（副本目录有 `README.md` 就照任务目录查——旧版无条件跳过 `tools` 正是这 20 条死链能活下来的原因，新装工作区又不该一跑就红）。
  **待办落地**：① 新增 `[题]`（H1 含目录名，判失败；别名形式 `# 目录名（别名）· 使用说明`）；② `[空]` 加第二层——DESIGN「设计思路」三列表任一格留空即失败，只管这一节、只管三列表，整行全空仍由旧那条报（不重复出两行）；③ `[链]` 剥行内 `` `code` ``；④ 纯 bash civil→days 去掉 GNU `date -d`；⑤ git hook 与 PowerShell 版按裁定**关闭不做**（理由写进 DESIGN 取舍表与待办）。
  **`AGENTS.md` 的可达性豁免不是我加的**：并行会话在 14:47 提交了 `7c09c5b`，把 `AGENTS.md` 从 `check_links` 的 `find` 里排除，理由是规则正文里的示例链接（`[game.js](packages/client/src/game.js)`）不是真路径。用户裁定**以该提交为准**，我这边保留它、不撤（我的 `git diff HEAD` 里那行只作为上下文出现，没有增删）。我这轮加的行内 `` `code` `` 剥离消掉的是**另一类**误报（`[this](Status result)`），两者叠加后 `dsp-hal-eval` 才转绿。**2026-10-15 订正归属**：这一行原先写成"3178 那个会话"，d8d34e7f 本轮明确否认，且它在旧工作树的提交只有 `2eb6a0a`（10-14 10:48）与 `5c6f3a6`（12:01），`7c09c5b` 是 14:47——时序也对不上。git 元数据分不出是哪个会话（`--local` 身份同为 `Lizardon386`），所以**作者归属现在未知**，别再往某个会话头上记这笔账；裁定"以那版为准"不受影响，那针对的是内容不是作者。
  **夹具 15 项断言全过**（`--root` 隔离根、跑完即删），三条关键反向对照：半填行报 / 两列表不报；别名标题放行 / 纯别名报；行内代码假链接放行 / **同一段不写反引号照报**。
  **夹具顺手抓出一个会一路绿到八月才炸的真 bug**：`IFS=-` 拆出的 `08`/`09` 在 bash 算术里是非法八进制，不写 `10#` 时 `[旧]` 判定直接报错——今天是 10 月，测不出来。已修并对拍 14 组（含闰年、世纪年、`2026-08-09` 这类）。另外第一次对拍误报 6 组不一致，是**台子自己的毛病**：拿本地时区（UTC+8）的 `date +%s` 当参考，午夜换算成 UTC 少一天；改用 `date -u` 后归零。
  **散文同步 9 处**：skill 的 `SKILL.md`、`references/doc-spec.md`、`references/agents-rule.md`、`.github/README.md`（含严重度表加 `[题]` 行与新 changelog）、`assets/README.md.tpl`、`assets/DESIGN.md.tpl`；工作区 `D:\agent_workspace\AGENTS.md`（**原地手工补丁 8 处，没有整份覆盖**——本地注解仍在）；`.codex\AGENTS.md` 与 `.claude\CLAUDE.md` 的第 4 条（installers 只补不覆盖，必须手工）。
  **引用整改**：本目录三档 ~20 条 `tools/` 链接改指新名 + H1 三档从 `tools` 改成 `multi-agent-task-handoff`；`3178-battle-platform` 三档 H1 补目录名（README 的 H1 会跟着显示在它那个 GitHub 仓库首页）；`skill-export` 那条按 10-10 先例去掉链接。**`dsp-hal-eval` 一个文件没碰**——它有并行会话正在写（本会话期间 `实施方案.md`、`CONTEXT.md` mtime 一直在动，`coding/.../DspControlCore.{h,cpp}` 是中途才出现的），它的 `[档]` 输出与 `[旧]` 由那边自己收。
  **已知残留**：`.review/` 归档记录与部分历史「变更记录」行里还写着旧路径，属历史记录，不改写（见待办）。
- 2026-10-14 Qoder（本会话，**收尾：以 7c09c5b 为准 + 提交铺满**）：用户追问"本机加载的 skill 与 GitHub 是否有差异"，核出来三方互不一致：`origin/master` 停在并行会话（3178 那个，会话 `d8d34e7f`）14:47 提交的 `7c09c5b`「skip AGENTS.md in check_links」；`.codex`/`.claude` 的 `check-docs.sh` 还是 skip 之前的 `c39bafd2`、`.github/README.md` 更停在 `5c6f3a6`——**那次提交没铺满**，等于三个 agent 在跑三种版本。用户裁定**以该提交为准**，于是：我此前写的"没加任何新豁免"三处措辞改成如实记录豁免来自 `7c09c5b`（我的 `git diff` 里那行只作为上下文出现，没被撤）；真源提交 `9022a95`（10 文件 +212/−54）并推到 `origin/master`；跑 `install-everywhere.ps1` 铺满，`.codex`/`.claude` 各更新 10 个文件、工作区副本目录同步。
  **验证**：四份 `check-docs.sh`/`init-task.sh`/`bootstrap.sh`/`install-everywhere.ps1` + 两份模板 md5 全一致，`-not -name "AGENTS.md"` 四处俱在；从**工作区副本**跑全量闸门 exit 0（完整输出、未加管道）。
  **顺带一条渲染教训**：链接文字里不要放以 `\` 结尾的 Windows 路径——`\]` 会被当成转义，整条 markdown 链接解析失败、URL 被原样吐给用户看。写 `D:/agent_workspace/xxx`（正斜杠）或不带尾斜杠。

- 2026-10-14 Qoder（本会话，规范从两档扩成三档）：**新增 `DESIGN.md` 一档**，README 退回纯使用者说明书。动因与上次改 3178 README 是同一件事的两次重复——取舍三列表占住说明书第一节，使用步骤被顶到第二屏；任务推上 GitHub 后读者要的是"我怎么用"。落地七处：① `check-docs.sh` 加 `DESIGN_SECTIONS` 与 `check_design()`，`[空]` 空表格行从"只判 README"改成**三档都判**（原先它顺带抓住了 README 的空产物表，拆档后不许松开），`[期]` 由两档比对改三档比对（`grep -v ^$ | sort -u | wc -l`），`[名]` 豁免 `DESIGN.md`；② **DESIGN 可省**——目录里已有 `架构设计.md`/`XX实施方案.md` 这类承担设计职责的交付文档时打印 `[档]`（新增的**唯一信息性前缀**）而不是 `[缺]`，名单只收复合名，`他人设计稿评审意见书.md` 换不到豁免（拿"名字里带设计就算"是最容易悄悄松掉的口子）；③ 标题「任务双档规范」→「任务三档规范」，**幂等标记同步改成正则 `任务[双三]档规范` 兼容旧标题**，`bootstrap.sh` 与 `install-everywhere.ps1` 都改；④ `assets/DESIGN.md.tpl` 新增、README 模板删设计思路节、CONTEXT 模板改指路，`init-task.sh` 铺三档，`bootstrap.sh` 铺三份模板；⑤ `install-everywhere.ps1` 的 `$globalBlock` 第 3 条改三档（该文件含中文，改完 `od` 验 BOM 仍在）；⑥ 手工同步 `D:\agent_workspace\AGENTS.md`（原地补丁，**没有**用 agents-rule.md 覆盖——那份里攒了工作区本地注解：`内网部署说明.md` 已并入的历史、`vhal-hld-rewrite` 豁免举例、`规则来源` 章、"标题是契约"告诫、不加管道那条等 13 处，覆盖会毁掉）+ `.codex\AGENTS.md` + `.claude\CLAUDE.md` 三个全局规则块；⑦ 7 个历史目录迁移：6 个拆出 DESIGN（3178 用行区间机械搬运 + 逐行核对 111 行内容零丢失；uno-online 另把 README 的 26 条绝对链接改相对链接并把 8 条设计约束移入 DESIGN），`dsp-hal-eval` 走 `[档]` 豁免（且有并行会话正在写，本轮一个文件没碰）。夹具验证 `[缺]/[构]/[空]/[期]/[档]` 五类正反两向各命中，含"评审意见书不获豁免"这条负向对照。
- 2026-10-14 Qoder（本会话，`[链]` 放宽链接形式 + 收紧可达性）：起因是 `3178-battle-platform` 推上 GitHub 后，README 里的 `file:///D:/...` 对读者全是死链，而闸门**只认这个前缀**——规矩在把文档往错的方向推。用户选"放宽闸门"，落地为三条：① 「产物与目录」的判定改为"**有任何可点击 markdown 链接即可**"（`file:///` 与仓库相对链接都算）；② 可达性校验**扩展到相对链接**，按文档自身目录解析——放宽只发生在"有没有链接"这一条，断链检测反而更强；③ 提取链接前先剥掉 ` ``` ` 代码围栏，修掉一处真实假阳性（C++ 的 `[this](Status result)` 被当成链接，在 `dsp-hal-eval/架构设计.md` 上误报过）。
  **反向验证（6 个夹具，`--root` 隔离根，跑完即删）**：t1 产物节纯相对链接且全可达 → 新闸门放行、旧闸门判红（证明放宽确实生效）；t2 断掉的相对链接 → 报（旧闸门看不见，证明不是放水）；t3 断掉的 `file:///` → 照报；t4 产物节全裸路径 → 照报；t5 围栏里的 lambda → 放行；t6 **同一段代码不写围栏 → 报**（这条是关键：证明 t5 的放行是围栏在起作用，不是提取器压根没看见）。散文同步 6 处：`SKILL.md`、`references/doc-spec.md`、`references/agents-rule.md`、skill 的 `.github/README.md`（含 changelog）、`assets/README.md.tpl`（新任务照抄的那份）、`D:\agent_workspace\AGENTS.md`（铺满对已存在文件只补不覆盖，**必须手工同步**）。真源 commit 见 skill 仓库；`install-everywhere.ps1` 跑两次，四处副本（`.qoder-cn`/`.codex`/`.claude`/工作区 tools）md5 全一致；全量闸门 exit 0（7 个任务目录，输出未截断）。
  **一条流程错误，值得下一个 agent 记**：我最初把改动落在 `D:\agent_workspace\tools\check-docs.sh` 上——那是 `install-everywhere.ps1` 第 ③ 步的**下游副本**，真源是 skill 的 `scripts/check-docs.sh`。谁跑一次铺满，我的改动就会被旧版原地覆盖，而且覆盖是静默的（脚本本身没有版本自述）。规矩方向其实是反的：**改闸门改 skill 里那份，再铺满**。另外 `install-everywhere.ps1` 的 `-Source` 缺省 = 脚本自身所在目录的上一级，**只能从 skill 目录里那份启动**；从 `tools/` 那份启动会把整个 `D:\agent_workspace` 当成 skill 源目录。顺带：PowerShell 输出是 GBK，接 `| iconv -f GBK -t UTF-8` 才读得懂，否则一片乱码容易被误判成失败。
- 2026-10-10 Qoder（本会话，中文命名规矩）：新增 `[名]` 检查项（顶层输出 `.md` 纯 ASCII 文件名即失败，判失败），豁免非 `.md`、`_` 前缀机器产物、`archive/`/`inputs/` 子目录与脚本。同时把旧版"只有两个名字"的禁令重新表述为**按角色判**（禁的是与双档职责重复的文件，不是多一个文件）。据此把 `dsp-hal-eval` 的 5 份交付文档改成中文名并同步全工作区引用，247 条 `file:///` 链接扫描零死链。**另修掉一个自造假绿灯**：`[链]` 原先不剥 HTML 注释，而模板注释与表头里写了 `file:///` 示例，空表格也能通过；现在先剥注释再判，双向验证过。真源 commit `987ebd2`，已 `bootstrap.sh --force` 同步本目录。
- 2026-10-10 Qoder（本会话，链接可达性）：`[链]` 再加一层——**链接指向的文件不存在也判失败**。收尾扫描发现 `dsp-hal-eval` 有 43 条死链（另一会话改 `archive/` 文件名未改引用），旧闸门看不见。跨平台要点：只校验 `$ROOT` 内链接、`canon()` 归一 msys/Windows 路径、`printf '%b'` 解 `%XX` 保持纯 bash。真源 commit `7f71374`，已同步本目录；修完引用后全量 exit 0。
- 2026-10-10 Qoder（本会话，自查）：**`7f71374` 的可达性校验在 Linux 根上是静默空转的**——`file:///` 剥掉三斜杠后路径丢掉前导斜杠，与 `/tmp/...` 形态的 ROOT 前缀比较永不匹配，全部 `continue` 跳过，死链一条不报还 exit 0。实测用 `--root /tmp/fx` 造死链复现。真源 `257b936` 修了三处：补前导斜杠、`/d/x` 盘符转换加 `uname` 平台判定、`set -u` 下 `$2` 未绑定导致 `NORM` 取到旧值（Windows 不区分大小写于是永远"存在"）。顺带把 38.4s 降回 9.2s（纯 bash 归一化 + 全局变量代替命令替换）。**教训：改完必须重跑严重度矩阵**——性能重写引入的 `set -u` 崩溃只有靠矩阵才发现，光看"真实工作区 exit 0"是绿的。
- 2026-10-10 Qoder（本会话，一致性核验）：另一会话把 `[链]` 升级为失败项并新增 `[期]`（commit `52b0a80`）后，本会话做了三项核验并补一处修复。① 落地页与脚本口径一致：`grep` 中英文两套措辞都查了（对方只查了中文），仓库内 4 处"告警/不失败"全部指 `[旧]`，`.github/README.md` 表格与 `SKILL.md` 的 "fails" 表述无冲突。② git 无在途改动，`local == origin == 52b0a80`、工作树干净、无 `.bak` 残留。③ **修掉 `[期]` 的一处静默漏检**（commit `b8d60f5`）：`top_date` 原先不锚定行首，而 `[占]` 锚定 `^> `，口径不一致——实测构造"顶部无日期 + 正文有日期"的文档，旧实现拿正文那行当顶部日期、`[新]` 不触发、整个闸门判 OK 放过；改为锚 `^> ` 并抽成单一 helper 供 `[新]/[旧]/[期]` 共用。对现有 10 个任务目录新旧输出逐行一致、exit 0，零误伤。已 `bootstrap.sh --force` 同步本目录并复跑全量闸门（完整输出、不加管道）exit 0。
- 2026-10-08 Qoder：创建 `tools/`（模板 + init + check），补齐 5 个任务目录的双档，统一 `内网部署说明.md` → `README.md`，全量自检通过。
- 2026-10-08 Qoder：规则与脚本上移为用户级 skill（新增 `--root`/`AGENT_WS_ROOT` 支持、`bootstrap.sh` 可把整套规矩装到任意工作区）；本目录改为同步副本，`tools` 自身退出自检范围。
- 2026-10-09 Qoder：新增「产物链接（强制）」规矩——向用户呈现的文件一律写成 `[名字](file:///绝对正斜杠路径)` 可点链接，实测只有这种语法能在 Qoder 侧边栏点开预览。改动落在 [SKILL.md](SKILL.md)、[doc-spec.md](references/doc-spec.md)、[agents-rule.md](references/agents-rule.md)、[README.md.tpl](assets/README.md.tpl) 与 [check-docs.sh](scripts/check-docs.sh)（新增 `[链]` 告警项），再 `bootstrap.sh --force` 同步到本目录；工作区根 `AGENTS.md` 因已含规则块需手工插入，bootstrap 不覆盖。同步存了用户级 memory [artifact-links.md](file:///~/.qoder-cn/memory/artifact-links.md)，使规矩在非工作区会话也生效。
- 2026-10-09 Qoder：skill 改名为「多agent间工作任务交接手顺」（标识 `multi-agent-task-handoff`，目录 `~/.qoder-cn/skills/multi-agent-task-handoff\`）。旧标识不留别名，全链路引用（AGENTS.md、本目录、skill-export 包、memory）一次改净并重导出。Qoder 靠扫描 skills 目录识别，改目录名即时生效、无需重启会话。
- 2026-10-09 Qoder：补「产物链接」规则的三处落地缺口——`assets/CONTEXT.md.tpl` 原本一个字没提（而规则明确要求 CONTEXT 的当前状态/变更记录写链接）、`README.md.tpl` 只有填文档就会被删掉的注释、skill `description` 里完全没提链接所以技能列表看不出来。现模板表格头内嵌要求、CONTEXT 两处加提示、description 补上 clickable 链接字样。
- 2026-10-09 Qoder：分发改走 GitHub 私有仓库 `Lizardon386/multi-agent-task-handoff`（真源目录即 git 工作树，首提交 `5b7af50`），zip/tar.gz 路线作废并已删包。加 `.gitattributes` 锁 `eol=lf`，否则 Windows 接收方 clone 出的 bash 脚本带 `\r` 直接语法报错。流程与验证见 skill-export/CONTEXT.md（该目录现已不在工作区，历史记录里这条是死链，闸门只查 README 产物节的可达性所以没报——按 10-10 的先例改写为不带链接并注明）。
- 2026-10-10 Qoder：**闸门加严 —— `[链]` 由告警升级为失败项，新增 `[期]`（两档顶部「最近更新」必须一致）**。起因是这次自查发现 `check-docs.sh` 明明报了 6 个目录缺产物链接，但因为只是告警、又被 `| tail -2` 截断，会话照样"全绿收尾"。教训：**告警在没人逐行读输出时等于不存在**。改动落在真源 [check-docs.sh](scripts/check-docs.sh)（commit `52b0a80` 已推）+ `SKILL.md` + `references/doc-spec.md` + `references/agents-rule.md` + `.github/README.md` 的严重度表，再 `bootstrap.sh --root D:/agent_workspace --force` 同步本目录，工作区根 `AGENTS.md` 的「任务双档规范」小节手工同步（标题未动，幂等标记仍在）。随后按新闸门整改全工作区：6 个目录的「产物与目录」改成可点链接、6 对文档日期对齐、[uno-online](../uno-online/CONTEXT.md) 另清掉 CONTEXT 复制手册与 README 写进度两处分工越线，并补记了 10-09 那次箭头修复。全量自检 exit 0、零告警，205 条链接逐条验过可达（其中一条指向已删除的 `test/room-unit-test.mjs`，改为不带链接并注明已删——**死链比裸名更坏**）。

- 2026-10-12 Codex：**锚点规则落地 + `[链]` 补死链分支 + 三副本对齐**。① 全链路（SKILL.md / agents-rule.md / doc-spec.md / README.md.tpl / 工作区 AGENTS.md）新增「文档内锚点（§ 节号、表内行号如 C4）写进链接文字」，起因是 dsp-hal-eval 会话把修正落位写成链接后跟裸 `C4 行`——点得开文件但用户不知道看哪。② 真源 `check_bare_refs`（5144aea 只查"名字还在却没写成链接"）补上"改名遗留死链"半边：`archive/`、`inputs/` 前缀的反引号裸路径已不存在即判 `[链]` 失败；skill 内部引用（如 `references/doc-spec.md`）指向工作区外，不判。③ 发现 `.codex` 副本是 10-10 中午的旧克隆、落后于真源双轨制提交（3041b91）——本已将真源策略重写了一遍，发现后改为以真源为准、只把增量（锚点规则 + 死链分支）合入真源。真源 commit `ce7e9d6` 已推 GitHub；`.codex` 副本整体重同步，本目录 `bootstrap.sh --force` 同步。阴性测试 5 场景全对，全量闸门 exit 0。

- 2026-10-12 Qoder：**修复「更新即铺满」自身的三个漏洞**（真源 commit `6b190df` 已推 GitHub，四个 blob 逐一比对远端一致）。① `install-everywhere.ps1` 第③步不铺它自己 → 本目录 `tools/install-everywhere.ps1` 长期停在旧版（真源 `30a4af` vs 本目录 `d466de`，旧版 `-Source` 还硬编码 `.codex`），已加进同步清单，现本目录 `bb058c2e` 与真源/`.codex`/`.claude` 四方一致，BOM 未丢；② `.claude` 会被写全局规则块却不在 `-AgentHomes`，Claude 侧引用的 skill 根本没装，已补（实测新增 11 个文件）；③ 铺满条款只在 `SKILL.md` 与落地页，`references/agents-rule.md` 整条缺失，已补「真源与更新即铺满」一节，并写明**已有规则块的工作区只补不覆盖**——工作区根 `AGENTS.md` 的规则来源节已手工补入两段。本目录 [README.md](README.md) 的产物与使用说明同步补 `install-everywhere.ps1`/`bootstrap.sh` 两行，并修掉"`bootstrap.sh` 不落工作区"的过期说法（它一直在）。
- 2026-10-12 Qoder：**发现 `[链]` 可达性校验的覆盖面缺口**——它只校验 README「产物与目录」里的链接，CONTEXT 变更记录与交付物正文里的死链不查；顺手把本文件 10-09 那条 `skill-export/CONTEXT.md` 死链按 10-10 先例改为不带链接的裸文本。是否把可达性校验扩到 CONTEXT/正文待定（扩了会一次性抓出多少历史死链，未知）。

## 给下一个 agent 的追加区

（后续会话请在此追加一行 `- YYYY-MM-DD <来源>：<结论/改动/遗留问题>`，或直接更新上面各节）

## 发布更新记录（对外 changelog）

> 2026-10-14 起这一节从仓库落地页（原 `.github/README.md`）挪到这里：按三档分工，历史记录归 CONTEXT；落地页只剩 [README.md](README.md) 一份。跟进方式永远是：`git pull` → 跑 `scripts/install-everywhere.ps1` 铺满。

跟进方式：`git -C D:/agent_workspace/multi-agent-task-handoff pull` 后**必须**按「更新即铺满」跑一次 `scripts/install-everywhere.ps1`（本机已装 `post-merge` 钩子，pull 完自动铺满，且钩子带 `-Prune`，仓库里删掉的文件当场从各副本清掉）。手动跑的那一趟默认仍不带 prune，需要清理自己加开关，或先用 `-Prune -DryRun` 只看清单。

**2026-10-15**

- **规矩收回单一源头：工作区 `AGENTS.md` 有了"入口模式"，派生物带出处戳**。判重从单个标题锚改成**双锚**（老锚 `任务[双三]档规范` / 新锚整行 `<!-- agents-entry -->`），`bootstrap.sh` 新增 `--entry`：装了 skill 的工作区根只生成"本机政策 + 锚 + 一行指针"，**里面没有任何条款**，因此改规矩不必再同步它（本机那份 149 行 → 16 行）。不加载 skill 的工作区不适用——那里必须仍是整份。同时：`install-everywhere.ps1` 里写死的全局规则块改为从 `references/agents-rule.md` 的锚点段**截取**（第二真源消失），并修掉一个只在别人机器上暴露的缺陷——第②步原先硬编码本机两个 agent 路径。每个派生段落带 `<!-- generated-from: references/agents-rule.md @ <sha> -->`，`watchdog.sh` 的 `[锚]/[出处]/[指针]` 探针据此报"落后几个提交"——**只报告不自动覆盖**，因为重写会冲掉工作区自己写的那段政策。

- **`post-merge` 钩子默认带 `-Prune`**：pull 那一趟自动铺满时顺带清掉各副本里仓库已删除的文件，不用事后手动补跑一趟 prune。铺满脚本本身保持"默认只补不删"——手动那一趟由跑的人决定要不要删。删除作用域没有放宽：只有技能目录的 skill 子树和各工作区的脚本副本目录两处，真源目录拒绝执行，不碰 `AGENTS.md`、全局规则文件与任务目录，且**待删清单先打进输出再删**。钩子配方（四行，带 `-Prune`）现在写在 README 的「更新即铺满」一节；`.git/hooks/` 不被 git 跟踪，换机器照那段自建。
- **铺满机械化：`pre-push` 钩子 + `scripts/watchdog.sh` 每日看门狗**。语义先说清：`git commit` 本身不触发任何同步，能触发的只有别人 pull 时的 `post-merge` 与手动跑那一次——"改了没铺"这条缝一直靠 agent 自觉，而它出过两次事。现在：推送前自动铺满（工作树脏则跳过、铺满失败则**阻断本次 push**），另加一个每日计划任务逐字节比对「各下游副本 == 工作树」并顺带跑闸门，**只在出问题时**在工作区根 `.watchdog/` 留一份待处理件，全绿自动撤掉。看门狗脚本随仓库走（不进工作区扁平副本清单——它需要工作树才有意义）。本机已注册为 Windows 计划任务 `multi-agent-handoff-drift`（每日 10:10，只使用交互方式，为的是待处理件真能被看见），注册命令写在 README 的「更新即铺满」。
- **工作区 `AGENTS.md` 降级成"入口 + 指针"**：本机 `D:\agent_workspace\AGENTS.md` 从 149 行砍到 32 行，只留工作区本地政策（产物落点等，skill 里不该有）、指向 `references/agents-rule.md` 的指针、以及三条最易出事的硬要求；**细则不再抄第二遍**，改条款也就不必再手工同步那份。实测重合数据：非空行里 40 行与原文逐字相同，其余多为措辞变体。装了 skill 且 agent 会读 `SKILL.md` 的工作区都能这么降级；**不加载 skill 的工作区不适用**，`bootstrap.sh` 给它们的仍是整份规则块。降级时必须留住标题里「任务三档规范」那四个字——它是安装器的幂等锚。
- **`references/agents-rule.md`（各工作区 `AGENTS.md` 的规则块原文）四处补正**：真源与 `-Source` 的措辞补上「工作树的 `post-merge` 钩子已默认带 `-Prune`」；`[名]` 的固定名豁免由四个补成"四个 + `SKILL.md`"，并在「命名」一节写明 `SKILL.md` 为什么豁免（它是 skill 加载器强制的文件名，只出现在工作树里，普通任务目录不该有它）。**已装工作区的 `AGENTS.md` 不会被自动更新**，本机那两份（工作区根与 `dsp-hal-eval`）已手工同步——那两份此前的"唯一真源"还写着 `.git` 搬走**之前**的 `~/.qoder-cn\skills\…`，照它改脚本会被下次铺满静默覆盖。

**2026-10-14**

- **`install-everywhere.ps1` 加 `-Prune` / `-DryRun`**：铺满默认只补不删，仓库里删掉的文件会在每个副本里留着当幽灵（2026-10-14 合并落地页后，三份 `.github/README.md` 带着旧规矩活下来了，而铺满输出全绿）——"副本 == 真源"这个前提被静默破坏。现在 `-Prune` 先把待删清单打进输出、再删，`-Prune -DryRun` 只列不删；作用域严格限定两个受管子树（技能目录下的 skill 子树按真源镜像比对；工作区脚本副本目录按「4 份脚本 + templates/」派生布局比对，避免把扁平副本整份当成多余删光），真源目录本身拒绝执行，收尾自底向上清空目录。沙箱实测：DryRun 列 3 个不删、Prune 列后删净、正件与用户笔记与 `AGENTS.md` 全部保留。过程中修掉一个作用域 bug：PowerShell 函数里 `$report +=` 会创建局部变量，导致"删了但不打印清单"，改成 `$script:report +=` 才符合"列出清单再删"。

- **两份 README 合并成根 `README.md` 一份**，删掉 `.github/README.md`。落地页与本目录三档之一的 README 重复约七成（都在讲"这是什么 + 三档规矩 + 前缀表 + 命令"），而且已经漂过：一份写"真源在 skill 目录"、另一份写"clone 到 skills 目录即装"——同一件事两个说法，正是本仓库最反对的两份真源。合并后根 README 兼任仓库首页与三档说明书，「最近更新」这类历史全部挪进本文件的「发布更新记录」节（按三档分工，历史归 CONTEXT），落地页里引用它。GitHub 首页渲染优先级是 `.github` > 根目录 > `docs`，`.github/README.md` 删掉后首页自然落到根 README。

- **纠正产物链接规矩：文档内一律相对路径，`file:///` 只留给聊天面**。旧规矩"本机文档首选 `file:///`"来自 2026-10-09 一次**只测了 Qoder 聊天侧边栏**的实测，被外推到了文档面。用户在 markdown 预览面板复测后结论相反：`file:///D:/...` 在 **VSCode 预览**报「文件不存在」（文件其实在）、在 **Qoder 文档预览**干脆不渲染成链接，改成相对该文档自身目录的路径后两个面都能跳。根因是预览器按"相对文档所在目录"解析 `href`，`file://` scheme 不在其绝对地址白名单里，会被当相对路径拼进工作区根。**两个渲染面解析逻辑相反，不能从一个外推到另一个。** 闸门**功能不动**（两种形式都接受、都验可达），因为这不是可达性问题而是形式问题——同步在 `doc-spec` 里写明"闸门绿不等于链接点得开"。改动面：`SKILL.md` 的 frontmatter description + 「Artifact links」节 + Pre-output 清单第 1 条、`references/doc-spec.md`、`references/agents-rule.md`（各工作区 `AGENTS.md` 规则块原文，**已装工作区不会被自动更新，需手工同步**）、本页。另补两条实测细节进反例清单：方括号被转义成 `\[文字\](目标)` 渲染成字面文本点不开；链接文字以 `\` 结尾会把 `]` 转义、整条链接解析失败。
- **真源从 agent 的 skills 目录搬进工作区**：`.git` 移到 `D:\agent_workspace\multi-agent-task-handoff\`，该目录从此是 skill 仓库的 git 工作树（布局 `SKILL.md` + `scripts/` + `assets/` + `references/` + `.github/`），`~/.qoder-cn`、`~/.codex`、`~/.claude` 下的技能目录**降级为下游副本**。配套改动：`bootstrap.sh` 与 `install-everywhere.ps1` 检测到"副本目录就是真源"时跳过自铺（否则会把扁平脚本铺到工作树根上，造出两份真源）；`check-docs.sh` / `init-task.sh` 的 root 解析新增仓库布局一层（`<root>/multi-agent-task-handoff/scripts/`），且明确 `…/skills/…`、`….codex…`、`….claude…` 下的脚本**不**反推工作区根；`-Source` 缺省因此变成"脚本所在 `scripts\` 的上一级"，从工作树里跑即正确。本目录的三档交接文档按用户裁定**一起提交**（GitHub 渲染优先级 `.github` > 根目录 > `docs`，落地页不受影响）。

- **工作区脚本副本目录改名 `multi-agent-task-handoff`，`tools` 继续接受；副本目录是否算任务目录改成按内容判**。起因是收工跑闸门发现 **exit 1、34 条 `[链]`**：`D:\agent_workspace\tools\` 已被改名成别的目录名，而 `bootstrap.sh`、`install-everywhere.ps1`、`check-docs.sh` 的 root 解析与跳过名单、以及工作区/全局 `AGENTS.md` 和落地页教的命令全写死 `tools/`——下次铺满会另造一个 `tools/`，改名那份变成没人认领的第三副本（"两份真源必然漂移"的翻版）。现在：四处解析器都认两个名字，`bootstrap.sh` 与 `install-everywhere.ps1` 遇到已有 `tools/` 的工作区沿用旧名（一次铺满不会铺出两份脚本），结尾提示打印真实路径而不是失效的 `bash tools/init-task.sh`。跳过名单改为**按内容判**：副本目录只有脚本时跳过（新工作区不该一跑就红），一旦铺了三档就照任务目录检查——正是这条抓出了 20 条指向旧路径的死链。旧名硬跳过是这些死链能活到今天的原因。
- **新增 `[题]`（判失败）**：H1 必须含任务目录名，中文别名写成 `# 目录名（别名）· 使用说明`。原先这条全靠人工守，实测 8 个目录 2 个对不上（含本 skill 自己的工作区副本，标题一直还写着旧名）。
- **`[空]` 加严第二层**：DESIGN「设计思路」的三列表**任一格留空**即失败。只判"整行三格全空"时 `| 用 A | 有理由 |  |` 是绿的，而漏的恰恰是最要紧的代价列。两列表照旧不判，避免误伤架构表。
- **`[链]` 现在也剥行内 `` `code` ``**（此前只剥 ` ``` ` 围栏）：三份文档为了说明这条规则，用行内反引号举 `[this](Status result)` 这个反例，被闸门判红 4 条——**规则误伤了写规则的人**。反引号定界符按**等长 run 配对**，因为文档里存在 ```` ```` ``` ```` `` 这种"反引号套反引号"的写法，简单成对匹配会配错位、把 span 漏出去。display 名带反引号的合法链接先解开再验（这种例子在散文里只用文字描述，真写出来会和 span 剥离互相干扰），可达性覆盖没有因此缩小；格式例子要写成代码段（**两个**反引号包住，单反引号包不住含反引号的例子），散文里裸写的链接形状 `[文字](链接)` 就是一条点不开的死链、照报——2026-10-14 曾给"占位符"开过豁免，结果当场打穿了证明 span 生效的那条反向对照（夹具 c8），已撤销。`AGENTS.md` 的可达性豁免由并行会话的 commit `7c09c5b` 引入（规则正文里的示例链接不是真路径），本轮保留它；两条修叠加之后 `dsp-hal-eval` 才转绿。
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
