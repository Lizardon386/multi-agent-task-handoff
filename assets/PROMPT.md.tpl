# 交接指针

> 本文件由 `--suspend` 自动生成，每次覆盖；不要手改。最近生成：YYYY-MM-DD HH:MM

## 项目目录
> 绝对路径；接手 agent 用它定位 `handoff/`。

<绝对路径>

## 读卡顺序
> 按顺序读；冲突以 `CONTEXT.md` 为准。已决策 / 勿动 / 坑都在 CONTEXT，不在这里重复。

1. 本文件
2. `handoff/CONTEXT.md`（含 MEMORY 提炼）
3. 跨任务规则：<路径>（按需）
4. 能力表：<路径>（按需）

## 交接文档
> 只列交接文档；本文件自身不在此表。

| 文档 | 路径 |
|---|---|
| CONTEXT | handoff/CONTEXT.md |
| 压卡备份 | handoff/COMPACT_BACKUP.md |

## 状态锚点
> 只写可复核的锚点；不写主观判断。

- git HEAD：以 `git log -1 --oneline` 为准（不写固定 SHA）；非 git 项目写哨兵串：
- 工作树 / 副本：以 `git status -sb`、`scripts/handoff.sh --printpath` 现读

## 验证命令
> 必跑 `git status -sb`；按需项由可观察信号触发，未跑的在汇报中注明。

- 锚点不可核对（非命令式 / 无上次 HEAD / 与当前 HEAD 不符）或副本无法确认（非本次收工、行为异常、点名宿主、超 30 天 / 版本变化）：`bash install.sh --dryrun`；`bash scripts/handoff.sh --printpath`；`bash scripts/handoff.sh --syncall --dryrun`
- 文档动过（`--doc` / 迁移 / 布局变更）：`bash scripts/handoff.sh --doc --guard --target .`
- 用户明确要求：按命令执行

## 下一步（1–3 条）
> 只写 1–3 条可执行动作。

1.

## 规则与能力表指针
> 只给路径；不复制正文。

- 跨任务规则：<路径>
- 能力表：<路径>

<!-- multi-agent-task-handoff: scope=handoff -->
