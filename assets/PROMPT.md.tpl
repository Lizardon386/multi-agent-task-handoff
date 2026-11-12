# 交接指针

> 本文件由 `--suspend` 自动生成，每次覆盖；不要手改。最近生成：YYYY-MM-DD HH:MM

## 项目目录
`<绝对路径>`

## 读卡顺序
1. 本文件
2. `handoff/CONTEXT.md`（含 MEMORY 提炼；压卡历史见 `COMPACT_BACKUP.md`）
3. 跨任务规则：<路径>（按需）
4. 能力表：<路径>（按需）

## 状态锚点
- git HEAD：以 `git log -1 --oneline` 为准（不写固定 SHA）；非 git 项目写哨兵串
- 工作树 / 副本：以 `git status -sb`、`scripts/handoff.sh --printpath` 现读

## 验证命令
- 必跑：`git status -sb`
- 按需（锚点不可核对 / 副本无法确认 / 文档动过 / 用户要求）：`--printpath`、`--syncall --dryrun`、`--doc --guard`、`install.sh --dryrun`

## 下一步（1–3 条）
1.

<!-- multi-agent-task-handoff: scope=handoff -->
