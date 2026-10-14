---
name: multi-agent-task-handoff
description: 多agent间工作任务交接手顺 — MANDATORY in EVERY session and ANY workspace, not only D:\agent_workspace. (1) Every task-like folder you create or work in must carry the three-document set — README.md (user manual), DESIGN.md (方案设计：为什么这么设计、已定语义), CONTEXT.md (agent handoff, updated every session) — with all three dates kept on the same day. (2) Every file artifact shown to the user, in chat replies AND in documents, must be a clickable Markdown link (file:/// absolute URLs on Codex/Qoder or when unsure; repo-relative links in a README published to GitHub; workspace-relative #L line anchors only on hosts verified to support jump-to-line). Never rationalize that the current directory is outside the agent workspace — the chat-link rule and the session-end CONTEXT.md update apply everywhere. Use at session start, when creating or touching any task or project folder, before any reply that mentions a file path, before ending a session, or when the user asks to set up, bootstrap, or enforce this handoff procedure on another agent or machine.
when_to_use: Every session in any workspace — at session start, when creating or updating task folders or docs, before any chat reply that shows a file path, and before claiming a session's work is finished.
argument-hint: [task-folder-name]
---

# 多agent间工作任务交接手顺

## Overview

Every task subfolder of the workspace must carry **three** Markdown files, each with a strictly different job:

| File | Reader | Answers | Changes |
|---|---|---|---|
| `README.md` | the human who **uses** it | what it is, what it can do, how to run it, what to watch out for | only when usage changes |
| `DESIGN.md` | the human who **reviews or extends** it | why it is designed this way, the architecture and seams, which semantics are frozen | only when the design changes |
| `CONTEXT.md` | the next agent | how far it got, what is left, what will bite you | **every session** |

Splitting README from DESIGN is a 2026-10-14 change: a manual with the trade-off table inlined buries the run instructions, and once a task is published to GitHub the reader wants "how do I use this" first. The filing rule for a new fact — *will this still be true in six months?* yes → `DESIGN.md`, no → `CONTEXT.md`.

The convention exists because sessions are volatile: without a handoff file the next agent re-derives intent from a directory listing and gets it wrong.

## Workflow

1. **Before touching files in a task folder**, read its `CONTEXT.md`, then `README.md`, then `DESIGN.md`. Do not infer intent from file names.
2. **New task folder** → scaffold it immediately, do not defer:
   ```bash
   bash scripts/init-task.sh <task-folder-name>
   ```
3. **Work.**
4. **Before ending the session**, update the three files, then verify:
   ```bash
   bash scripts/check-docs.sh            # all folders; append a name to check one
   ```
   Exit code must be `0`. An empty scaffold, a missing section, or an unfilled `最近更新：` date fails the check on purpose — filling it is the point of the step.

## Required sections

Order is fixed. Extra sections are allowed; these are not deletable.

`README.md` (user manual): `一句话说明` → `快速开始` → `使用说明` → `产物与目录` → `限制与注意事项`

`DESIGN.md` (方案设计): `问题与目标` → `设计思路` → `架构与关键接缝` → `已定语义与边界`

`CONTEXT.md`: `背景与目标` → `当前状态` → `计划 / 待办` → `关键约束与注意事项` → `变更记录` → `给下一个 agent 的追加区`

**`DESIGN.md` may be absent on purpose.** If the folder already carries a deliverable whose role *is* the design (`架构设计.md`, `XX实施方案.md` — the gate matches a whitelist of **compound** names, so `他人设计稿评审意见书.md` does not earn the exemption), the gate prints `[档] 方案设计已由交付文档「X.md」承担` and skips the four sections: two sources of truth for one design always drift. Missing both `DESIGN.md` and such a deliverable is `[缺]`, a failure.

All three start with an H1 (`# <task-folder> · 使用说明` / `· 方案设计` / `· 会话上下文与进展`) and a blockquote carrying `> 最近更新：YYYY-MM-DD` — `[新]`/`[旧]`/`[期]` read **only that blockquote line**, so a date mentioned in body text never counts as the top date. `[期]` compares the three of them and fails when any differs.

`设计思路` — now in `DESIGN.md`, not in the manual — must be a three-column trade-off table: **决策 / 理由 / 代价**. A conclusion without its cost is not a design note; an empty row fails `[空]` on purpose, in all three documents.

## Naming

Four names are fixed and never translated: `README.md`, `DESIGN.md`, `CONTEXT.md`, `AGENTS.md`. `DESIGN.md` stays English because it is convention infrastructure next to the other two, not a deliverable — `[名]` exempts it the same way.

The ban covers **role duplication**, not "one more file". A file whose job is "the manual" belongs inside `README.md`; "why it is built this way" belongs inside `DESIGN.md`; "handoff notes / progress" belongs inside `CONTEXT.md` — so `使用说明.md`, `设计说明.md`, `进度.md`, `notes.txt` are forbidden as duplicates of the three docs. Ask: *is this an explanation for a reader, or the work product itself?*

Any **other output document — a real deliverable** (design draft, review opinion, decision memo, evaluation report, question list) may exist as its own file, and **must have a Chinese filename**: `设计总览.md`, `归属决策件.md`, `他人设计稿评审意见书.md`. Readers are Chinese colleagues and the files get forwarded into group chats and Feishu; an ASCII name makes them guess which file is which.

Exempt from Chinese naming: non-`.md` deliverables (`.docx` / `.pdf` must keep the vendor's filename so versions match), `_`-prefixed machine artifacts, anything under `archive/` or `inputs/`, and code/scripts/config.

`check-docs.sh` enforces this as `[名]` — a **failure** — scanning only top-level `.md` files, which is what lets `archive/` and `inputs/` fall out for free.

## Content division (the part agents get wrong)

- Progress, verification logs, TODOs, open issues → `CONTEXT.md` **only**.
- Design rationale, architecture, frozen semantics → `DESIGN.md` **only**. Operating steps → `README.md` **only**.
- Facts more than one doc needs (ports, paths, hard disk limits): the owning document states them, the others carry one cross-reference line — never a restated copy.
- Record *why* and *what hurts* (irreversible operations, in-place edits, idempotency, external constraints). Do not transcribe code that explains itself.
- `变更记录` / append区 lines are additive: `- YYYY-MM-DD <agent>: <summary>`.

Full spec, including naming bans and edge cases: `references/doc-spec.md`.

## Artifact links (required)

Any file artifact shown to the user must be a **clickable Markdown link** — bare filenames, backticked paths, and `path:line` prose make the user hunt for the file himself. Two tracks, picked by where the link lives:

**Workspace `.md` documents** (`产物与目录` in `README.md`, status / change-log lines in `CONTEXT.md`, artifact references inside deliverables) — always a clickable link, line number in the link **text**, never a `#L42` fragment. Pick the form by whether the document leaves this machine:

- Local-only document (default): a `file:///` absolute URL.
- A repo `README.md` that will be pushed to GitHub or shared: a **repo-relative** link — `file:///D:/...` is a dead link on everyone else's machine.

```markdown
[game.js](file:///D:/agent_workspace/uno-webgame/game.js)
[game.js:42](file:///D:/agent_workspace/uno-webgame/game.js)
[game.js](packages/client/src/game.js)
```

- Forward slashes always, Windows too: `D:\x\y.js` → `file:///D:/x/y.js`.
- Keep `file:///` as the default for local documents; since 2026-10-14 the gate accepts **both** forms and validates **both** for reachability.
- In-document anchors (`§` section numbers, table-row ids such as `C4`) follow the same rule — the anchor goes **in the link text**: `[归属决策件.md · C4行](file:///D:/agent_workspace/dsp-hal-eval/归属决策件.md)`. An anchor left outside the link (a bare `C4 行` after it) is a violation.
- `check-docs.sh` reports `[链]` and **fails** when a `README.md` lists artifacts with no clickable link at all, when any link inside the workspace points at a file that no longer exists (`file:///` targets outside the workspace root are skipped so the scripts stay portable to other machines; content inside ```` ``` ```` fences is not scanned — a C++ lambda like `[this](Status result)` reads like a link), when a top-level deliverable `.md` mentions a workspace `.md`/`.txt` file as a bare backtick reference (`` `foo.md` ``) instead of a link (dead-link's sibling: not clickable, easy to leave behind after a rename), or `[期]` when the two docs' `最近更新` dates disagree.

**Chat replies** — pick by host capability:

- Hosts that follow workspace-relative `#L` line anchors (verified: Claude Code's VSCode extension): `[spidevice.c:489](dsp-hal-eval/finalfile/codecs/ccd5001/spidevice.c#L489)`, ranges `#L217-L240` — one click lands on the line; the preferred form there.
- Other hosts (e.g. Qoder's sidebar preview, Codex) or when unsure: keep the `file:///` form above, with the line number or in-document anchor in the link text.

Why the split (decided 2026-10-10, widened 2026-10-14): a `file:///` link opens the file but cannot carry a line number — the user clicked one and landed at the top of the file. Chat replies therefore use anchor links on hosts that support jumping; documents default to `file:///`, and repo-relative links are equally valid in a README that is published somewhere the reader has no `D:` drive.

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

## Propagation rule (MANDATORY)

Whenever this skill changes — whether you just edited it locally or `git pull` brought in new commits — immediately overwrite every local agent's skill copy with the newest content:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <最新skill目录>\scripts\install-everywhere.ps1
```

- `-Source` defaults to the skill directory the script runs from, so **always run the copy that holds the newest content** (the git clone after a pull; your edited copy after local edits).
- Updating one copy without propagating is a rule violation: the other agents keep enforcing the OLD rules, and their next session silently diverges.
- The same run also re-syncs the `tools/` copy of every workspace in its `-WorkspaceRoots` list — including `install-everywhere.ps1` itself (added 2026-10-12; before that the workspace copy of the propagator silently went stale). Workspaces bootstrapped by hand need `bash scripts/bootstrap.sh --root <workspace-root> --force`.
- **A workspace's existing `AGENTS.md` is NOT rewritten** — both installers dedupe on a heading match and only append when nothing matches. Since 2026-10-14 the marker is the regex `任务[双三]档规范`, so a workspace still carrying the old `任务双档规范` heading is recognized instead of getting a duplicated rule block. After changing rule text here, sync that workspace's `AGENTS.md` (and each agent's global rule file) by hand — the installers never rewrite an existing block.
`tools/` and `templates/` are infrastructure and are excluded from the check; a real task folder always is.

## Resources

- `scripts/init-task.sh` — create a task folder with the three skeletons.
- `scripts/check-docs.sh` — compliance gate (existence, sections, placeholders, empty scaffolds, freshness).
- `scripts/bootstrap.sh` — install / re-sync the convention into a workspace root.
- `scripts/install-everywhere.ps1` — the Windows propagator that executes the Propagation rule below: skill dirs of every agent + global rule files + every registered workspace. Run the copy from the newest source.
- `assets/README.md.tpl`, `assets/DESIGN.md.tpl`, `assets/CONTEXT.md.tpl` — section skeletons (bootstrap copies these into `tools/templates/`).
- `references/doc-spec.md` — the complete written rule (read when writing or reviewing docs).
- `references/agents-rule.md` — the exact block bootstrap appends to a workspace `AGENTS.md`.
