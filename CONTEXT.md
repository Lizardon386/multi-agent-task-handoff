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
- [x] ~~遗留：`strip_code` 是逐字符扫描，全量闸门从 ~9s 涨到 ~11s~~ → 2026-10-14 的性能改造已把它连带解决（每目录 4 次进程，真工作区 ≈0.9s）。**下一条是这条唯一还剩下的成本**：合并成单次 awk 后，判定语义只能靠夹具与变异测试守。

## 关键约束与注意事项

- **真源就是本目录（2026-10-14 起）**：`.git` 已从 `~/.qoder-cn/skills/multi-agent-task-handoff\` 移到这里，本目录是 skill 仓库的 git 工作树，布局是 `SKILL.md` + `scripts/` + `assets/` + `references/`（2026-10-14 同日删掉了多一份落地页 `.github/README.md`，合并进根 README）。三个 agent 的 skills 目录（`.qoder-cn`/`.codex`/`.claude`）与其它工作区的脚本副本目录**都是下游副本**，改它们等于等着被覆盖。改完的顺序固定：本目录改 → `git commit` + `git push` → 跑 `scripts/install-everywhere.ps1` 铺满。
- **本目录的三档（README/DESIGN/CONTEXT）随仓库一起提交**（用户 2026-10-14 裁定），所以它们是**公开可见**的：写的时候记住里面的本机路径与进度对别人没有意义，规范以 `SKILL.md` 与 `references/` 为准。GitHub 首页就是根 [README.md](README.md)——2026-10-14 把原 `.github/README.md` 合并进来删掉了（渲染优先级 `.github` > 根目录 > `docs`，前者不存在时首页落到根）。对外 changelog 在本文的「发布更新记录」节，README 里指过来。
- **跑闸门/建任务的命令在本目录多一层 `scripts/`**：`bash scripts/check-docs.sh`；下游工作区是扁平副本，写 `bash <副本目录>/check-docs.sh`。两种布局 root 解析都认，`…/skills/…`、`….codex…`、`….claude…` 下的那份**不**反推成工作区根。
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

- 2026-10-15 Qoder（本会话，**铺满的机械化：pre-push + 每日看门狗**，用户选 A+C、铺满失败阻断 push、调度走 Windows 任务计划）：
  ① 先答清语义：**`git commit` 到今天为止仍不触发任何东西**；能触发的只有别人 pull 时的 `post-merge` 和本机手动跑。所以补两层——`.git/hooks/pre-push`（推送前铺满 `-Prune`）与 `scripts/watchdog.sh`（每日比对副本 vs 工作树 + 跑闸门，只在有问题时写 `.watchdog/_需要处理.md`，全绿自动撤）。没选 `post-commit`：中间态规矩会被铺出去。
  ② `pre-push` 两条语义分开写死：工作树脏 → 跳过铺满、放行 push；铺满失败 → 阻断 push。前者是**正确性**要求（铺满拷工作树，脏树会把未提交内容当权威铺进每个技能目录），后者是**可执行性**要求（失败只打在一行没人看的通知里，等于回到"靠自觉"）。
  ③ `watchdog.sh` 起手就用 `SKILL.md` + `.git` 两个条件确认 `--source` 是**工作树**：从下游副本跑它，两边都旧，比结果是假绿灯——这正是本仓库反复出事的那类"看起来通过其实没执行"。默认名单是三个 agent 技能目录；不存在的目录打 `[跳过]` 不报错，脚本因此能发给别的机器/别的 agent 布局用。`diff -rq -x .git`（不用 `--exclude`，BSD diff 没这个长选项），全绿只写一行，出问题才落明细。
  ④ 先证它真会红：新增 `watchdog.sh` 自身还没铺满时跑一次 → 三处都报 `Only in …/scripts: watchdog.sh`、exit 1、待处理件生成。**能抓到自己才算数**。
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
  **`AGENTS.md` 的可达性豁免不是我加的**：并行会话（3178 那个）在 14:47 提交了 `7c09c5b`，把 `AGENTS.md` 从 `check_links` 的 `find` 里排除，理由是规则正文里的示例链接（`[game.js](packages/client/src/game.js)`）不是真路径。用户裁定**以该提交为准**，我这边保留它、不撤（我的 `git diff HEAD` 里那行只作为上下文出现，没有增删）。我这轮加的行内 `` `code` `` 剥离消掉的是**另一类**误报（`[this](Status result)`），两者叠加后 `dsp-hal-eval` 才转绿。
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
- 2026-10-09 Qoder：新增「产物链接（强制）」规矩——向用户呈现的文件一律写成 `[名字](file:///绝对正斜杠路径)` 可点链接，实测只有这种语法能在 Qoder 侧边栏点开预览。改动落在 [SKILL.md](SKILL.md)、[doc-spec.md](references/doc-spec.md)、[agents-rule.md](references/agents-rule.md)、[README.md.tpl](assets/README.md.tpl) 与 [check-docs.sh](scripts/check-docs.sh)（新增 `[链]` 告警项），再 `bootstrap.sh --force` 同步到本目录；[AGENTS.md](../AGENTS.md) 因已含规则块需手工插入，bootstrap 不覆盖。同步存了用户级 memory [artifact-links.md](file:///~/.qoder-cn/memory/artifact-links.md)，使规矩在非工作区会话也生效。
- 2026-10-09 Qoder：skill 改名为「多agent间工作任务交接手顺」（标识 `multi-agent-task-handoff`，目录 `~/.qoder-cn/skills/multi-agent-task-handoff\`）。旧标识不留别名，全链路引用（AGENTS.md、本目录、skill-export 包、memory）一次改净并重导出。Qoder 靠扫描 skills 目录识别，改目录名即时生效、无需重启会话。
- 2026-10-09 Qoder：补「产物链接」规则的三处落地缺口——`assets/CONTEXT.md.tpl` 原本一个字没提（而规则明确要求 CONTEXT 的当前状态/变更记录写链接）、`README.md.tpl` 只有填文档就会被删掉的注释、skill `description` 里完全没提链接所以技能列表看不出来。现模板表格头内嵌要求、CONTEXT 两处加提示、description 补上 clickable 链接字样。
- 2026-10-09 Qoder：分发改走 GitHub 私有仓库 `Lizardon386/multi-agent-task-handoff`（真源目录即 git 工作树，首提交 `5b7af50`），zip/tar.gz 路线作废并已删包。加 `.gitattributes` 锁 `eol=lf`，否则 Windows 接收方 clone 出的 bash 脚本带 `\r` 直接语法报错。流程与验证见 skill-export/CONTEXT.md（该目录现已不在工作区，历史记录里这条是死链，闸门只查 README 产物节的可达性所以没报——按 10-10 的先例改写为不带链接并注明）。
- 2026-10-10 Qoder：**闸门加严 —— `[链]` 由告警升级为失败项，新增 `[期]`（两档顶部「最近更新」必须一致）**。起因是这次自查发现 `check-docs.sh` 明明报了 6 个目录缺产物链接，但因为只是告警、又被 `| tail -2` 截断，会话照样"全绿收尾"。教训：**告警在没人逐行读输出时等于不存在**。改动落在真源 [check-docs.sh](scripts/check-docs.sh)（commit `52b0a80` 已推）+ `SKILL.md` + `references/doc-spec.md` + `references/agents-rule.md` + `.github/README.md` 的严重度表，再 `bootstrap.sh --root D:/agent_workspace --force` 同步本目录，[AGENTS.md](../AGENTS.md) 的「任务双档规范」小节手工同步（标题未动，幂等标记仍在）。随后按新闸门整改全工作区：6 个目录的「产物与目录」改成可点链接、6 对文档日期对齐、[uno-online](../uno-online/CONTEXT.md) 另清掉 CONTEXT 复制手册与 README 写进度两处分工越线，并补记了 10-09 那次箭头修复。全量自检 exit 0、零告警，205 条链接逐条验过可达（其中一条指向已删除的 `test/room-unit-test.mjs`，改为不带链接并注明已删——**死链比裸名更坏**）。

- 2026-10-12 Codex：**锚点规则落地 + `[链]` 补死链分支 + 三副本对齐**。① 全链路（SKILL.md / agents-rule.md / doc-spec.md / README.md.tpl / 工作区 AGENTS.md）新增「文档内锚点（§ 节号、表内行号如 C4）写进链接文字」，起因是 dsp-hal-eval 会话把修正落位写成链接后跟裸 `C4 行`——点得开文件但用户不知道看哪。② 真源 `check_bare_refs`（5144aea 只查"名字还在却没写成链接"）补上"改名遗留死链"半边：`archive/`、`inputs/` 前缀的反引号裸路径已不存在即判 `[链]` 失败；skill 内部引用（如 `references/doc-spec.md`）指向工作区外，不判。③ 发现 `.codex` 副本是 10-10 中午的旧克隆、落后于真源双轨制提交（3041b91）——本已将真源策略重写了一遍，发现后改为以真源为准、只把增量（锚点规则 + 死链分支）合入真源。真源 commit `ce7e9d6` 已推 GitHub；`.codex` 副本整体重同步，本目录 `bootstrap.sh --force` 同步。阴性测试 5 场景全对，全量闸门 exit 0。

- 2026-10-12 Qoder：**修复「更新即铺满」自身的三个漏洞**（真源 commit `6b190df` 已推 GitHub，四个 blob 逐一比对远端一致）。① `install-everywhere.ps1` 第③步不铺它自己 → 本目录 `tools/install-everywhere.ps1` 长期停在旧版（真源 `30a4af` vs 本目录 `d466de`，旧版 `-Source` 还硬编码 `.codex`），已加进同步清单，现本目录 `bb058c2e` 与真源/`.codex`/`.claude` 四方一致，BOM 未丢；② `.claude` 会被写全局规则块却不在 `-AgentHomes`，Claude 侧引用的 skill 根本没装，已补（实测新增 11 个文件）；③ 铺满条款只在 `SKILL.md` 与落地页，`references/agents-rule.md` 整条缺失，已补「真源与更新即铺满」一节，并写明**已有规则块的工作区只补不覆盖**——[AGENTS.md](../AGENTS.md) 的规则来源节已手工补入两段。本目录 [README.md](README.md) 的产物与使用说明同步补 `install-everywhere.ps1`/`bootstrap.sh` 两行，并修掉"`bootstrap.sh` 不落工作区"的过期说法（它一直在）。
- 2026-10-12 Qoder：**发现 `[链]` 可达性校验的覆盖面缺口**——它只校验 README「产物与目录」里的链接，CONTEXT 变更记录与交付物正文里的死链不查；顺手把本文件 10-09 那条 `skill-export/CONTEXT.md` 死链按 10-10 先例改为不带链接的裸文本。是否把可达性校验扩到 CONTEXT/正文待定（扩了会一次性抓出多少历史死链，未知）。

## 给下一个 agent 的追加区

（后续会话请在此追加一行 `- YYYY-MM-DD <来源>：<结论/改动/遗留问题>`，或直接更新上面各节）

## 发布更新记录（对外 changelog）

> 2026-10-14 起这一节从仓库落地页（原 `.github/README.md`）挪到这里：按三档分工，历史记录归 CONTEXT；落地页只剩 [README.md](README.md) 一份。跟进方式永远是：`git pull` → 跑 `scripts/install-everywhere.ps1` 铺满。

跟进方式：`git -C D:/agent_workspace/multi-agent-task-handoff pull` 后**必须**按「更新即铺满」跑一次 `scripts/install-everywhere.ps1`（本机已装 `post-merge` 钩子，pull 完自动铺满，且钩子带 `-Prune`，仓库里删掉的文件当场从各副本清掉）。手动跑的那一趟默认仍不带 prune，需要清理自己加开关，或先用 `-Prune -DryRun` 只看清单。

**2026-10-15**

- **`post-merge` 钩子默认带 `-Prune`**：pull 那一趟自动铺满时顺带清掉各副本里仓库已删除的文件，不用事后手动补跑一趟 prune。铺满脚本本身保持"默认只补不删"——手动那一趟由跑的人决定要不要删。删除作用域没有放宽：只有技能目录的 skill 子树和各工作区的脚本副本目录两处，真源目录拒绝执行，不碰 `AGENTS.md`、全局规则文件与任务目录，且**待删清单先打进输出再删**。钩子配方（四行，带 `-Prune`）现在写在 README 的「更新即铺满」一节；`.git/hooks/` 不被 git 跟踪，换机器照那段自建。
- **铺满机械化：`pre-push` 钩子 + `scripts/watchdog.sh` 每日看门狗**。语义先说清：`git commit` 本身不触发任何同步，能触发的只有别人 pull 时的 `post-merge` 与手动跑那一次——"改了没铺"这条缝一直靠 agent 自觉，而它出过两次事。现在：推送前自动铺满（工作树脏则跳过、铺满失败则**阻断本次 push**），另加一个每日计划任务逐字节比对「各下游副本 == 工作树」并顺带跑闸门，**只在出问题时**在工作区根 `.watchdog/` 留一份待处理件，全绿自动撤掉。看门狗脚本随仓库走（不进工作区扁平副本清单——它需要工作树才有意义）。
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
