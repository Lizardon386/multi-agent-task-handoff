# multi-agent-task-handoff · 命令参考

> 面向使用者和 agent：逐命令说明语法、默认值、行为边界和常见错误。
> 最近更新：2026-11-06

## 文档
> 只列主要文档与阅读对象；完整索引见 CONTEXT；不复制正文。

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](../README.md) | 使用者 | 这是什么、怎么跑、限制 |
| [DESIGN.md](DESIGN.md) | 评审 / 开发 | 摘要、方案、备选、风险、决策 |
| [COMMANDS.md](COMMANDS.md) | 使用者 | 命令参考（本文） |
| [CONTEXT.md](../handoff/CONTEXT.md) | 接手 agent | 完整文档表、当前状态、下一步、记忆提炼、坑 |

完整文档表（含 PROMPT、SKILL、HELP、压卡备份）见 [CONTEXT.md](../handoff/CONTEXT.md)。

## 命令索引
> 只列命令、用途与默认挡位；详细说明见下文章节。
> 脚本层直接支持 `--printpath` / `--doc` / `--syncall` / `--push` / `--save` / `--gear`；`--resume` / `--suspend` / `--post` / `--check` / `--fix` / `--probe` / `--workspace` 由 agent 按 SKILL 执行；`--probe` 的固定清单见 `assets/PROBE.md`。

| 命令 | 用途 | 默认值 / 挡位 |
|---|---|---|
| `--resume` | 接手：读 PROMPT → CONTEXT，核锚点、跑验证 | — |
| `--suspend [--local \| --commit \| --push]` | 收工：压卡、写 CONTEXT、生成 PROMPT、对齐副本 | `[defaults].suspend`，默认 `local` |
| `--post <message> [--new \| --next <ID \| 会话名>]` | 热交接：把消息投给另一个会话 | `[defaults].post`，默认 `new` |
| `--doc [--guard \| --init]` | 文档整理：布局、标记、迁移；guard 维护/删失效行，init 只新增 | `[defaults].doc`，默认 `guard` |
| `--check` | 只读体检 | — |
| `--fix` | 体检 + 修非文档整理项 | — |
| `--probe [--static \| --live]` | 摸底宿主能力并更新能力表 | `[defaults].probe`，默认 `static` |
| `--printpath [--host NAME \| --target DIR]` | 只读路径诊断 | — |
| `--gear <key>[=<值>] \| --gear list` | 读写 `config.toml` 的 `[defaults]` 挡位 | 见下文 |
| `--workspace <PATH> [--nosave]` | 指定工作区根，默认写回配置 | — |
| `--help` | 输出帮助 | — |

## --resume
> 只说明接手的读取顺序、核对项与输出。

- 语法：`--resume`，无参数；不写命令时默认也是它。
- 行为：读 `handoff/PROMPT.md` → `handoff/CONTEXT.md` → 跨任务规则；核对 cwd 与项目目录、HEAD/工作树/副本锚点；跑 PROMPT 的验证命令；汇报状态、下一步、阻塞。
- 边界：只读；不写卡、不迁移文档、不动 git；冲突以 CONTEXT 为准。
- 常见错误：cwd 与项目目录不一致、PROMPT 缺失或锚点过期、验证命令失败；先报告，不静默按过期状态开工。

## --suspend [--local | --commit | --push]
> 只说明收工、压卡、PROMPT 与挡位。

- 语法：`--suspend`，可选一个挡位。
- 默认：`[defaults].suspend`；未配置按 `local`。
- 挡位：
  - `--local`：写 CONTEXT/PROMPT、按需压卡，不操作 git。
  - `--commit`：额外提交协议管理文档（`handoff/` 与带标记文档及其移动/删除）。
  - `--push`：隐含 commit，提交后推送；普通项目在项目目录运行安装副本的 `scripts/handoff.sh --push`（推当前目录仓库），源仓库环境推源仓库；网络错误重试 3 次 / 3 秒，Windows 再加 HTTP/1.1 + OpenSSL 回退 3 次。
- 行为：必要时压卡；覆盖 `handoff/PROMPT.md`；源仓库收工末尾跑 `scripts/handoff.sh --syncall` 对齐安装副本。
- 边界：默认不操作 git；不装钩子；安装副本跳过 syncall；未确认推送成功不写「已推送」。
- 常见错误：CONTEXT 缺失、推送认证失败/非快进、从安装副本跑 `--syncall`；保留本地提交并报告。

## --post <message> [--new | --next <ID | 会话名>]
> 只说明投递目标、新会话约束与不写卡边界。

- 语法：`--post "<message>"`，必须给 message；目标二选一。
- 默认：`[defaults].post`；`new` 或 `next`。配成 `next` 但没给目标时停下问。
- `--new`：新建会话后投递；新会话必须绑定当前项目目录。落 worktree / fork 视为失败；已知会落 worktree 的宿主（如 Claude Code）应改走 UI 新建 + `--next`。
- `--next <ID | 会话名>`：投给已有会话；先按 ID 精确匹配，再按标题匹配；有会话列表工具就直接查，必须按返回项的 `title` 过滤后再判唯一；目标会话的 `workDir` 必须等于项目目录。
- 状态检查：解析到目标后先查会话状态；stopped/completed 且宿主不会自动唤醒时给手动卡（打开/继续目标会话后再投递），不把消息盲目入队。
- 边界：只投消息；不写卡、不改文档、不动 git；报告实际结果，不伪造成功。
- 常见错误：message 为空、目标会话不存在/不唯一、workDir 不一致、宿主不支持跨会话；停下报告或给替代。

## --doc [--guard | --init]
> 只说明 guard/init 分工、布局与标记。

- 语法：`--doc`，可选一个挡位。
- 默认：`[defaults].doc`；未配置按 `guard`。
- `--guard`：维护已有文档；检查缺失角色、被引用文档、README 引用、标记和链接；删除 `## 文档` 表中指向缺失协议角色的整行；其余输出 `OK` / `WARN` / `SUGGEST`，只报告；不新增、不还原、不改正文。
- `--init`：只新增缺失文档，先出清单并确认：
  - `CONTEXT.md`：必生成。
  - `README.md`：仅 GitHub 项目（`git remote -v` 指向 GitHub）或用户明确要发布到 GitHub 时生成。
  - `DESIGN.md`：仅在有设计取舍且用户确认时生成；`--guard` 检出设计/方案类文档时会建议。
  - `COMMANDS.md`：仅在用户明确要求时生成；`--guard` 检出 CLI/多命令迹象时会建议。
  - 一律从模板创建；不从会话记录、历史副本或备份还原。
- 行为：布局整理、角色迁移、补标记、只修迁移造成的链接；内容增删迁移只由 `--doc` 执行。
- 边界：`--guard` 只改 `## 文档` 表（删失效协议行）；正文/历史/项目内容死链只报告；冲突停，不覆盖、不改名、不合并。
- 常见错误：目标已存在且非本协议生成、角色有多份候选、判不准分类；出选择题，未选不动。

## --check
> 只说明只读检查项与报告口径。

- 语法：`--check`，无参数。
- 行为：只读检查安装副本 commit、文档布局与 scope、链接、config/workspace、能力表日期、`sync-paths`、`PROMPT.md` 忽略/跟踪状态、项目内 memory 是否 gitignore、PROMPT 是否过期、工作区文档、CONTEXT 行数/记录数/坑类别；当前宿主能力表仍有「待测」时报 🟡 并列出缺失 P 项（不自动跑 probe）；源仓库额外核对 SKILL/scripts/HELP/模板一致性。
- 边界：不改文件；缺 README/DESIGN 不算错误，只提示 `--doc`；文档整理项只报告，不自动修。
- 常见错误：副本落后、PROMPT 被跟踪、CONTEXT 超限、能力表过期；按报告处理，不把 `--check` 当迁移工具。

## --fix
> 只说明非文档修复项；文档整理交给 --doc。

- 语法：`--fix`，无参数。
- 行为：先跑同一套检查，再修非文档整理项：安装副本对齐、`git rm --cached` 取消 PROMPT 跟踪、补 `.gitignore` 规则、配置/能力表缺失项。
- 边界：不创建、不删除、不移动、不改链；文档布局/分类/标记/链接一律只报告「需跑 `--doc`」。
- 常见错误：把 `--fix` 当文档整理用；它不会迁移旧布局。

## --probe [--static | --live]
> 只说明固定清单、一次确认、L1/L2 与能力表完成定义。

- 语法：`--probe`，可选一个挡位。
- 默认：`[defaults].probe`；未配置按 `static`。
- 清单：读取 skill 安装目录的 `assets/PROBE.md`，按 P 项执行；static 只填 S 项。
- `--live`：先输出完整计划（P 项、副作用、清理、将写的能力表格），确认一次后跑完全部适用项，仅计划外副作用停下。
- L1 只证通道可达；L2 用临时项目真实投递指针，目标读 PROMPT/CONTEXT 后回报项目目录、锚点、下一步、勿动、MEMORY 提炼 5 项并核对；每次 live 都跑 L2。
- 清理：删除临时项目/测试会话，删不掉只报告残留；不写真实会话 ID/凭据。
- 行为：就地更新 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`。
- 完成：当前宿主必测格无「待测」，缺失/策略阻止记 ⛔/🟡 + 证据；未安装宿主整行可留「待测」。
- 常见错误：把 L1（PONG）当 L2；把「建会话成功」当「投递成功」；落 worktree 记 🟡/⛔；把工具缺失留在「待测」。

## --printpath [--host NAME | --target DIR]
> 只说明诊断输出项。

- 语法：`--printpath`，可选显式宿主或安装目录。
- 行为：只读表格输出配置目录、配置文件、工作区根及来源、能力表日期、安装注册表、源仓库、宿主识别来源、当前安装副本和全部副本的路径/commit。
- 边界：不写文件、不生成缓存；`--host` / `--target` 只用于显式指定。
- 常见错误：把路径诊断当安装/修复命令；它只读。

## --gear <key>[=<值>] | --gear list
> 只说明键、允许值与非法值处理。

- 语法：`--gear suspend` / `--gear probe` / `--gear post` / `--gear doc` 读取；`--gear <key>=<值>` 写入；`--gear list` 列出键、默认值与允许值。
- 允许值：`suspend=local|commit|push`、`probe=static|live`、`post=new|next`、`doc=guard|init`。
- 行为：只改 `config.toml` 的 `[defaults]`；键不存在时插在 `[defaults]` 后。
- 边界：值/键不在白名单时报错且不修改文件；配置文件不存在时报错，不自动创建。
- 常见错误：拼错键/值、在未安装配置的机器上直接写；先跑 `install.sh` 或 `--gear list`。

## --workspace <PATH> [--nosave]
> 只说明工作区根来源与写回规则。

- 语法：`--workspace "D:/agent_workspace"`，可搭配一个命令；`--nosave` 只本次生效。
- 行为：设置工作区根；默认写回 `[paths].workspace`。
- 边界：工作区根只是项目目录的容器，不是写入目标；路径含空格必须加引号。
- 常见错误：把项目目录当工作区根；只想本次生效却忘了 `--nosave`。

## --help
> 只说明帮助输出来源。

- 语法：`--help`，单独使用。
- 行为：输出 `assets/HELP.txt` 的速查表；找不到时输出 SKILL 的用法表和边界。
- 边界：不替代本参考；详细语法和示例以本文为准。

## 默认值与配置
> 只列配置键、默认值与允许值。

| 键 | 默认 | 允许值 | 说明 |
|---|---|---|---|
| `[paths].workspace` | `$HOME/agent_workspace` | 路径 | 工作区根；项目目录的容器 |
| `[defaults].suspend` | `local` | `local` / `commit` / `push` | `--suspend` 默认挡位 |
| `[defaults].probe` | `static` | `static` / `live` | `--probe` 默认挡位 |
| `[defaults].post` | `new` | `new` / `next` | `--post` 默认目标模式 |
| `[defaults].doc` | `guard` | `guard` / `init` | `--doc` 默认挡位 |

配置只解析简单 `key = "value"`；不 `source`，不依赖 Python。

<!-- multi-agent-task-handoff: scope=docs -->
