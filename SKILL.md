---
name: multi-agent-task-handoff
description: 多agent间工作任务交接手顺 — Enforce the two-document handoff convention (README.md for users + CONTEXT.md for agents) in every task subfolder of an agent workspace such as D:\agent_workspace, and require every file artifact shown to the user to be a clickable [名字](file:///绝对路径) link. Use when starting work in a workspace task folder, creating a new task/project folder, updating progress or handoff notes, ending a session, or when the user asks to set up / bootstrap / enforce this handoff procedure on another agent or machine.
when_to_use: Working inside an agent workspace root that has task subfolders; creating or updating task docs; before claiming a session's work is finished.
argument-hint: [task-folder-name]
---

# 多agent间工作任务交接手顺

## Overview

Every task subfolder of the workspace must carry **two** Markdown files, and they have strictly different jobs:

| File | Reader | Answers | Changes |
|---|---|---|---|
| `README.md` | the human | what it is, **why it is designed this way**, how to use it | only when design or usage changes |
| `CONTEXT.md` | the next agent | how far it got, what is left, what will bite you | **every session** |

The convention exists because sessions are volatile: without a handoff file the next agent re-derives intent from a directory listing and gets it wrong.

## Workflow

1. **Before touching files in a task folder**, read its `CONTEXT.md`, then `README.md`. Do not infer intent from file names.
2. **New task folder** → scaffold it immediately, do not defer:
   ```bash
   bash scripts/init-task.sh <task-folder-name>
   ```
3. **Work.**
4. **Before ending the session**, update both files, then verify:
   ```bash
   bash scripts/check-docs.sh            # all folders; append a name to check one
   ```
   Exit code must be `0`. An empty scaffold, a missing section, or an unfilled `最近更新：` date fails the check on purpose — filling it is the point of the step.

## Required sections

Order is fixed. Extra sections are allowed; these are not deletable.

`README.md`: `一句话说明` → `设计思路` → `快速开始` → `使用说明` → `产物与目录` → `限制与注意事项`

`CONTEXT.md`: `背景与目标` → `当前状态` → `计划 / 待办` → `关键约束与注意事项` → `变更记录` → `给下一个 agent 的追加区`

Both files start with an H1 (`# <task-folder> · 设计思路与使用说明` / `# <task-folder> · 会话上下文与进展`) and a blockquote carrying `> 最近更新：YYYY-MM-DD`.

`设计思路` must be a three-column trade-off table: **决策 / 理由 / 代价**. A conclusion without its cost is not a design note.

## Content division (the part agents get wrong)

- Progress, verification logs, TODOs, open issues → `CONTEXT.md` **only**.
- Design rationale and operating steps → `README.md` **only**.
- Facts both need (ports, paths, hard disk limits): one cross-reference line in `CONTEXT.md`, never a restated copy.
- Record *why* and *what hurts* (irreversible operations, in-place edits, idempotency, external constraints). Do not transcribe code that explains itself.
- `变更记录` / append区 lines are additive: `- YYYY-MM-DD <agent>: <summary>`.

Full spec, including naming bans and edge cases: `references/doc-spec.md`.

## Artifact links (required)

Any file artifact shown to the user must be a **clickable Markdown link with a `file:///` absolute URL**. Bare filenames, backticked paths, and `path:line` prose are not clickable in Qoder's sidebar preview — the user has to hunt for the file himself.

```markdown
[game.js](file:///D:/agent_workspace/uno-webgame/game.js)
```

- Forward slashes always, Windows too: `D:\x\y.js` → `file:///D:/x/y.js`.
- Put the line number in the link **text**, not a `#L42` fragment (fragments are unverified): `[game.js:42](file:///D:/agent_workspace/uno-webgame/game.js)`.
- Applies to chat replies, to `产物与目录` in `README.md`, and to status / change-log lines in `CONTEXT.md`.
- `check-docs.sh` reports `[链]` when a `README.md` lists artifacts with no such link.

## Target workspace

Root resolution, first match wins: `--root <dir>` → `$AGENT_WS_ROOT` → the `tools/` parent this script is installed in → `D:/agent_workspace`.

## Bootstrapping another agent or machine

To install the convention (rules block in `AGENTS.md`, `tools/` scripts, templates) into a workspace root that lacks it:

```bash
bash scripts/bootstrap.sh --root <workspace-root>
```

Idempotent: existing files are left untouched, and `AGENTS.md` gains the rule block only if it does not already contain it.

## Source of truth

This skill is the canonical implementation. A workspace's `tools/` folder holds a synced copy (which is why a session that never loads the skill still finds working scripts). After editing `scripts/` or `assets/` here, re-sync the workspace:

```bash
bash scripts/bootstrap.sh --root <workspace-root> --force
```

Never fix a bug only in the workspace copy — it will be overwritten on the next sync.
`tools/` and `templates/` are infrastructure and are excluded from the check; a real task folder always is.

## Resources

- `scripts/init-task.sh` — create a task folder with both skeletons.
- `scripts/check-docs.sh` — compliance gate (existence, sections, placeholders, empty scaffolds, freshness).
- `scripts/bootstrap.sh` — install / re-sync the convention into a workspace root.
- `assets/README.md.tpl`, `assets/CONTEXT.md.tpl` — section skeletons (bootstrap copies these into `tools/templates/`).
- `references/doc-spec.md` — the complete written rule (read when writing or reviewing docs).
- `references/agents-rule.md` — the exact block bootstrap appends to a workspace `AGENTS.md`.
