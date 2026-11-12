# 工作区约定（入口指针）

> 最近更新：YYYY-MM-DD
> 工作区根 = `$AGENT_WORKSPACE`；未设置时 `$HOME/agent_workspace`（Windows `%USERPROFILE%\agent_workspace`）；本机自定义写在 `$AGENT_CONFIG/config.toml`。

- 工作区根是项目目录的容器，不是写入目标；产物放 `<工作区根>/<项目名>/`。
- 读序：项目 `handoff/PROMPT.md` → `handoff/CONTEXT.md` → `PROJECT_RULES.md` → 需要投递/读回时查 `$AGENT_CONFIG/AGENT_CAPABILITIES.md`；README 与 `docs/` 不在读序，任务需要时按 CONTEXT 文档表打开。
- 协议以 skill 的 `SKILL.md` 为准；本文件只做入口指针，不复制协议正文，不触发自动化。
- 工作区产物规则、同主题分目录、换机/交接、`$AGENT_CONFIG` 路径、Windows/pwsh 与统一布局细节见 `PROJECT_RULES.md`。
