# multi-agent-task-handoff · 会话上下文与进展

> 本文件是交接卡：只记当前状态、下一步、坑和交接记录；历史与逐条变更见 [压卡备份.md](压卡备份.md)。
> 最近更新：2026-10-29
> 模式：三档
> 状态锚点：接盘时跑 `git log -1 --oneline`；推 GitHub 前跑 `gh auth status`
> 验证命令：`git status -sb`；`bash install.sh --dry-run`（本机 bash 不在 PATH，用 `D:\software\Git\bin\bash.exe`）；装完用 `diff -r` 比对安装副本

## 文档

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](README.md) | 使用者 | 怎么用、命令、限制 |
| [DESIGN.md](DESIGN.md) | 评审 / 二次开发 | 取舍、流程、语义与版本演进 |
| [CONTEXT.md](CONTEXT.md) | 接盘 agent | 当前状态、下一步、坑（本文） |
| [压卡备份.md](压卡备份.md) | 追溯用 | 状态历史、已完成、逐条变更 |

## 背景与目标

默认一份目录内的 `CONTEXT.md`，需要时用 `工程化` 升三档，交接只发状态不复制历史。任何 agent 都能读，不安装、不挂钩子、不起服务；git 可选。版本演进见 DESIGN 的「版本与设计演进」。

- 完成定义：SKILL / README / DESIGN 与安装副本一致；`install.sh --dry-run` 能识别当前宿主并指向正确目录；CONTEXT ≤100 行。

## 当前状态

- 现在：v2 + OpenCode 宿主支持已落地；安装副本与仓库 HEAD 一致；无进行中的代码改动。
- v2 协议已落地：默认单档；`接盘` / `交接`（别名 `收工`）/ `压卡` / `工程化` / `自检`（别名 `更新`）+ 只读自检；所有任务命令只看 cwd；唯一参数是 `交接` 的 ID；`收工` 只整理，带 ID 才发送；支持 `+` 或空格串行组合（如 `压卡+收工`、`压卡 收工`）。
- 安装：`install.sh` 按宿主环境变量只给当前 agent 装（Qoder/Claude/Codex/OpenCode/ZCode；OpenCode/ZCode 也可 `--host` 显式指定），写 `.skill-version`、启用本地钩子、登记 `.skill-sync-paths`；`安装.bat` 是 Windows 双击入口。
- 本机已装薄 skill：Qoder `~/.qoder-cn/skills/multi-agent-task-handoff`、OpenCode `~/.config/opencode/skills/multi-agent-task-handoff`、ZCode `~/.zcode/skills/multi-agent-task-handoff`（均实拷贝）；Qoder 不认目录 junction；提交后由钩子重新导出，或跑 `install.sh`。全局规则/钩子/计划任务仍无。
- 入口是命令不是文件：`接盘` 命令或 `交接` prompt（自带读卡顺序）；不在任务目录铺 `AGENTS.md`；自然语言「接盘」会加载 skill，已验。
- 记录粒度：每次收工 1 条关键动作，交接记录 ≤10 条自动滚动；压卡只做兜底。判定标准见「关键约束」。
- 已验证：收工回填、send/wait/read、工程化命令、压卡（uno-online 183→83 行）、skill 自动加载、OpenCode 实装（`OPENCODE` 自动识别 + `--host opencode`）、ZCode 实装（`ZCODE_APP_VERSION` 自动识别 + `--host zcode`）。
- 未验证：实际跨目录迁移；Codex 行待测；Claude/Codex 未在真宿主实装（只测环境识别 + 临时目录安装）。
- dsp-hal-eval 压卡已由其他 agent 完成，不在本目录处理。
- 本目录是协议真源和 git 工作树；非 git 目录靠 `压卡备份.md` 追溯。
- 远端同步状态以 `git status` / `git log` 为准；网络异常时先推本地提交。

## 计划 / 待办

- [ ] 其他宿主推广后复核能力表（OpenCode 行已补）；实际跨目录迁移仍未实测。
- [ ] 补工程化的迁移清单细节（排除项、hash 校验、删源确认）。
- [ ] 决定是否加可选 `check-handoff.sh`；默认不加。
- [ ] 评估把 `.skill-sync-paths` 移出 git 跟踪（当前随仓库分发本机路径）。

## 关键约束与注意事项

- 交接卡 ≤100 行；交接记录 ≤10 条；不写完整变更记录。
- 三档只在任务目录根；没有用户明确要求，不往更深子目录铺。
- 本目录只维护本 skill；其他任务（含 dsp-hal-eval 压卡）在各自目录处理，不在这里接。
- 关键判定：不知道这条，下一家会不会做错或重做？会才写；能从 CONTEXT/README/DESIGN/git 得到的不写。记录满 10 条时，先把最旧那条仍有效的内容提升到状态/坑，再删。
- 一个目录同一时间只允许一个写者；交接后旧会话停写。
- git 只负责回滚，不负责交接：不在卡里抄 commit 历史；格式提交不算关键动作。
- 非 git 目录不另建备份；压卡前原文附在 `压卡备份.md` 末尾，没有可追溯材料就不要声称“状态可复现”。
- 不复制完整会话历史；新会话按旧 ID 用 `read_chat_session` 按需查。
- 打开工作区只能手动：没有 create/open workspace 工具或 CLI。
- 入口靠指令：接盘命令/交接 prompt；不铺任务级 `AGENTS.md`，不写全局规则。
- 压卡只改 CONTEXT 和 `压卡备份.md`；其他文档的过期链接先报告，确需改先说明确认。
- 不安装、不挂钩子、不写全局规则、不起后台服务、不调用模型；敏感内容留在本机。
- README / DESIGN 只在 `工程化` 或有外部读者时写，不是每个任务的合规件。

## 交接记录（只记关键动作，≤10 条）

- 2026-10-28 Qoder：记录滚动改为“先沉降再删最旧”，避免早期决策被滚丢。
- 2026-10-28 Qoder：AGENTS 片段改为稳定入口，协议细则不再复制到任务目录。
- 2026-10-28 Qoder：片段文本定为冻结接口，只在协议大版本变更时批量更新。
- 2026-10-28 Qoder：去掉任务级 AGENTS，入口改为接盘命令/交接 prompt；少一份每任务副本。
- 2026-10-28 Qoder：dsp 压卡验收；备份统一为 `压卡备份.md`（历史 + 原件附录），不建目录；压卡不顺手改别的文档。
- 2026-10-28 Qoder：命令改「接盘」；「接续」去掉，`收工` = 不发送的交接，`交接 <ID>` 才发；加 `自检/更新` 比对安装 commit；任务命令只看 cwd，参数只留交接 ID；支持 `+` 或空格串行组合。
- 2026-10-28 Qoder：加 `install.sh`（只装当前宿主）+ `安装.bat`；卡里补 `gh auth status`；修正 `.skill-sync-paths` 是安装目录不是源仓库。
- 2026-10-28 OpenCode：`install.sh` 加 OpenCode 宿主（`OPENCODE`/`OPENCODE_CONFIG_DIR`，`--host opencode`），修 Windows `--target` 路径；OpenCode 副本实装并登记 `.skill-sync-paths`。
- 2026-10-28 OpenCode：补 OpenCode 能力行与卡字段（模式/验证/完成定义）；范围收窄为只维护本 skill，dsp-hal-eval 压卡已在别处完成。
- 2026-10-29 OpenCode：补「现在在哪 / 参考 ID」字段；压卡检查 71 行 / 10 条，无需压卡。
- 2026-10-29 ZCode：`install.sh` 加 ZCode 宿主（`ZCODE_APP_VERSION` 自动识别 + `--host zcode`）；`.skill-sync-paths` 加 ZCode 行，按先例随宿主支持提交；本机副本增至三份。
- 2026-10-29 ZCode：交接投递按能力表本行选手段（去 Qoder 硬编码）；参考 ID 定为 `宿主:ID` 格式（`sess_*` 只在 ZCode 可读，实测）。

## 参考 ID

- 无；本卡自包含，细节按 `git log` 与 [压卡备份.md](压卡备份.md) 查。
