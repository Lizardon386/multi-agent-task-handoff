# 项目规则（工作区根 · 跨任务）

> **作者实机调研快照，仅供参考。** 路径、账号、宿主版本均为作者本机环境，不代表通用约定；源文件在工作区根，更新以源文件为准（源文件更新 2026-10-30）。

> 工作区根 = `$AGENT_WORKSPACE`；未设置时用 `D:\agent_workspace`（本机默认）。以下规则对所有任务目录生效。
> 宿主专属规则留在各自全局文件（Zcode/Codex/Claude 的 AGENTS/CLAUDE、Qoder Memory）；任务级事实见各目录的 `CONTEXT.md` / `DESIGN.md`。
> 能力表（`AGENT_CAPABILITIES.md`）是实测缓存：结论和方法随工作区迁移，本机环境块换机重填。
> 最近更新：2026-10-30

## 输出与文档

- 文档内链接用相对路径；聊天回复按宿主：Qoder 侧边栏用 `file:///`，支持跳行的宿主用 `相对路径#L`。文档里不要写 `file:///`。
- 除 `README.md` / `DESIGN.md` / `CONTEXT.md` / `AGENTS.md` / `SKILL.md` 外，输出文档用中文名；用户指定文件名时从其指定。非 `.md` 交付物、机器产物、`archive/`、`inputs/` 豁免。
- 用工程师的直述句：少口号、少破折号、少排比；术语先用一句人话定义。
- 改完贴变更；大改文档给 before/after 行数/字节 + 核心文件全文，别只说“已完成”。
- 宿主差异（memory 位置、会话 ID 格式、投递/读回手段、安装目录）只记 `AGENT_CAPABILITIES.md` 对应行；`SKILL.md` / `README.md` / `DESIGN.md` 只写跨宿主成立的规则，不写单宿主特例。改通用文档前先问：这条换个宿主还成立吗？不成立就写进能力表。

## 工作方式

- 先给计划等批准；交付可逐条标注的清单，不弹 AskUserQuestion。
- 不编造路径/行号/结果；不确定就说不知道；来源矛盾时列出来问。
- 不加无谓检查；文档体积上限/滚动窗口比再加结构检查有效。
- 只强制一份 `CONTEXT.md` 交接卡；`README.md` / `DESIGN.md` 按需。
- 宿主 memory 是辅助回忆，不是交接契约；交接前只把会影响下一家的坑提升到 CONTEXT/DESIGN，不做每轮 diff。
- 一个目录同一时间只允许一个写者；交接后旧会话停写。
- GitHub：每次提交后直接 push 并核对远端 HEAD；禁止 force push；push 偶发 TLS 断，原样重试。

## 工作区与产物

- 产物落在 `<工作区根>/<任务>/`；纯问答可留临时目录；不搬 agent 应用内部缓存。
- 换机/交接：复制 `AGENTS.md`、本文件、`AGENT_CAPABILITIES.md`；设置 `AGENT_WORKSPACE`；按能力表的低成本项先复验。

## 维护

- 规则变了才改本文件并更新日期；测了新 agent/宿主/版本只改能力表对应行；任务状态只进各自 `CONTEXT.md`。
- 读序：`AGENTS.md`（入口）→ 本文件（规则）→ 任务 `CONTEXT.md`（状态）→ 能力表（仅在需要投递/读回时查）。
- 能力表一行一个 agent+host+版本，带「验证方法 / 复验成本」；迁移时整表带走，不重测已测项。
- 快照：改完三份文档后，在 skill 仓库跑 `bash sync-作者实机调研.sh`，再提交推送；`--check` 只比对。`压卡` 不动这三份文档；`自检` 可跑 `--check` 只提示，不自动写。

## 本机环境（换机重填，不属于规则）

- Windows；PowerShell 默认 Restricted，命令整条可粘贴并带 `-ExecutionPolicy Bypass`。
- Git Bash：`D:\software\Git\bin\bash.exe`（本机 bash 不在 PATH）。
- GitHub 登录：gh 已登录 Lizardon386。
