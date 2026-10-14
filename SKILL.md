---
name: multi-agent-task-handoff
description: 多agent间工作任务交接手顺 — MANDATORY in EVERY session and ANY workspace, not only D:\agent_workspace. (1) Every task-like folder you create or work in must carry the three-document set — README.md (user manual), DESIGN.md (方案设计：为什么这么设计、已定语义), CONTEXT.md (agent handoff, updated every session) — with all three dates kept on the same day. (2) Every file artifact shown to the user, in chat replies AND in documents, must be a clickable Markdown link, and the form depends on the SURFACE: inside .md documents use paths RELATIVE to that document's own directory (a file:/// URL does not resolve in markdown preview panes — verified on both VSCode and Qoder previews 2026-10-14); in chat replies use file:/// for the Qoder/Codex sidebar, or workspace-relative #L line anchors only on hosts verified to support jump-to-line. Never rationalize that the current directory is outside the agent workspace — the chat-link rule and the session-end CONTEXT.md update apply everywhere. (3) **Pre-output rules check (MANDATORY)**: before presenting any plan, document change, or deliverable, actively check memory rules (artifact-links, chinese-doc-naming, complete-deliverables, etc.). Treat every output as a deliverable, not a draft. Use at session start, when creating or touching any task or project folder, before any reply that mentions a file path, before ending a session, or when the user asks to set up, bootstrap, or enforce this handoff procedure on another agent or machine.
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

All three start with an H1 (`# <task-folder> · 使用说明` / `· 方案设计` / `· 会话上下文与进展`) and a blockquote carrying `> 最近更新：YYYY-MM-DD` — `[新]`/`[旧]`/`[期]` read **only that blockquote line**, so a date mentioned in body text never counts as the top date. `[期]` compares the three of them and fails when any differs. Since 2026-10-14 `[题]` **fails** when the H1 does not contain the task folder's name: the next agent identifies which task a document belongs to from that heading, and a manual check of it drifted in 2 of 8 folders. A Chinese title is fine — write `# 3178-battle-platform（3178 对战平台）· 使用说明`; a heading that is *only* an alias fails.

`设计思路` — now in `DESIGN.md`, not in the manual — must be a three-column trade-off table: **决策 / 理由 / 代价**. A conclusion without its cost is not a design note; an empty row fails `[空]` on purpose, in all three documents. In `DESIGN.md` the bar is higher since 2026-10-14: **any** blank cell in a three-column row of that section fails, because `| 用 A | 有理由 |  |` used to pass while dropping exactly the column that matters. Two-column tables elsewhere are left alone — a blank cell there is normal layout, not an unfilled scaffold.

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

Any file artifact shown to the user must be a **clickable Markdown link** — bare filenames, backticked paths, and `path:line` prose make the user hunt for the file himself. **Two surfaces, two rules** — they resolve links differently, so picking by surface is the whole rule (decided 2026-10-14 after a `file:///`-first rule turned out to be wrong; see "Why the split" below).

**Inside `.md` documents** (`产物与目录` in `README.md`, status / change-log lines in `CONTEXT.md`, artifact references inside deliverables) — **always a path relative to the document's own directory**, line number or in-document anchor written into the **link text**, never a `#L42` fragment:

- Target below the document: `coding/dspcontrol-hal/core/DspControlCore.h` → `[DspControlCore.h](coding/dspcontrol-hal/core/DspControlCore.h)`.
- Target above the document (workspace root files, sibling tasks): write `../`, e.g. `[AGENTS.md](../AGENTS.md)`.
- A README that gets pushed to GitHub uses the **same** relative form — GitHub resolves it too, so one form covers both readers.
- Do **not** use `file:///` inside documents: the preview panes resolve `href` relative to the document, and an absolute `file://` URL either fails to render as a link at all (Qoder's document preview) or reports "文件不存在" (VSCode's preview).

```markdown
[DspControlCore.h](coding/dspcontrol-hal/core/DspControlCore.h)
[DspControlCore.h:88](coding/dspcontrol-hal/core/DspControlCore.h)
[AGENTS.md · 命名节](../AGENTS.md)
[game.js](packages/client/src/game.js)
```

- Forward slashes in every form, Windows too: `D:\x\y.js` → `x/y.js` (relative) or `file:///D:/x/y.js` (chat only).
- `check-docs.sh` accepts **both** forms and validates **both** for reachability, so a document full of `file:///` is not red — it is silently unclickable in preview, which is exactly why the rule had to change rather than the gate.
- In-document anchors (`§` section numbers, table-row ids such as `C4`) follow the same rule — the anchor goes **in the link text**: `[归属决策件.md · C4行](信息收集/过时信息归档文档/归属决策件.md)`. An anchor left outside the link (a bare `C4 行` after it) is a violation.
- Never escape the brackets: `\[text\](target)` renders as literal text and cannot be clicked. Keep `[` and `]` bare.
- Never end link **text** with a Windows path that carries a trailing backslash — `D:\ws\dir\]` escapes the `]` and the whole link fails to parse. Use forward slashes or drop the trailing separator.
- `check-docs.sh` reports `[链]` and **fails** when a `README.md` lists artifacts with no clickable link at all, when any link inside the workspace points at a file that no longer exists (`file:///` targets outside the workspace root are skipped so the scripts stay portable to other machines; content inside ```` ``` ```` fences **and inline `` `code` `` spans** is not scanned — a C++ lambda like `[this](Status result)` reads like a link, and the three documents of the script folder used backtick spans to describe that very counter-example, so the gate was flagging its own manual. Backtick delimiters are paired by **equal-length run**, not naively: ```` ```` ``` ```` `` needs it. A legitimate display-name-in-backticks link is unwrapped before stripping, so its reachability still gets checked. Quoting such an example needs a code span wide enough to hold backticks (two of them) — and even then a nested example can shift the pairing, so the safe move in prose is to describe the shape in words instead of writing it. A link shape written bare in prose *is* a dead link and the gate says so: a "placeholder" carve-out was tried on 2026-10-14 and reverted the same day because it silently broke the fixture that proves span-stripping works rather than ignoring links) , when a top-level deliverable `.md` mentions a workspace `.md`/`.txt` file as a bare backtick reference (`` `foo.md` ``) instead of a link (dead-link's sibling: not clickable, easy to leave behind after a rename), or `[期]` when the two docs' `最近更新` dates disagree.

**Chat replies** — pick by host capability (this is the chat surface, nothing here applies to what you write into `.md` files):

- Hosts that follow workspace-relative `#L` line anchors (verified: Claude Code's VSCode extension): `[spidevice.c:489](dsp-hal-eval/finalfile/codecs/ccd5001/spidevice.c#L489)`, ranges `#L217-L240` — one click lands on the line; the preferred form there.
- Other hosts (e.g. Qoder's chat sidebar, Codex) or when unsure: a `file:///` absolute link, with the line number or in-document anchor written into the link text.

Why the split (corrected 2026-10-14): the two surfaces resolve `href` **oppositely**. A chat sidebar needs an absolute `file:///` to open anything; a markdown preview pane resolves relative to the document and does not accept a `file://` scheme — it either refuses to render the link (Qoder document preview) or reports "文件不存在" for a file that is there (VSCode preview). The old rule ("local documents prefer `file:///`") was generalized from a 2026-09-09 test that only exercised the chat sidebar, and it produced documents whose links nobody could click; a second session measured both panes on 2026-10-14 and converted 175 links in `dsp-hal-eval` to relative. Line numbers still cannot ride on a `file:///` link, which is the separate reason chat replies use `#L` anchors where the host supports them.

## Pre-output rules check (MANDATORY)

Before presenting any plan, document change, or deliverable to the user, **actively check the relevant memory rules**. Treat every output as a deliverable, not a draft.

**Minimum checklist** (expand based on what you're outputting):

1. **Artifact links** — Every file reference must be a clickable Markdown link, in the form the *surface* resolves: relative to the document inside `.md` files, `file:///` (or `相对路径#L` on hosts that jump to line) in chat replies. Bare filenames, backticked paths, and `path:line` prose are violations; so is a `file:///` link inside a document.
2. **Chinese doc naming** — Output documents (except README/DESIGN/CONTEXT/AGENTS) must have Chinese filenames.
3. **Complete deliverables** — When changing documents, post the full updated content for review, not just the diff.
4. **Self-audit** — Before presenting, ask: "If the user screenshots this and asks me to find errors, what would I catch?" Fix those issues first.

**Why this is mandatory**: Agents tend to write content-first and skip rule compliance, relying on the user to catch errors. This is a delivery quality failure, not a speed trade-off. The 30 seconds spent checking rules prevents rework and maintains trust.

**Complements self-audit**: `feedback-self-audit-with-evidence` is reactive (when asked "did you follow rules?"); this is proactive (check before outputting). Both are required.

## Target workspace

Root resolution, first match wins: `--root <dir>` → `$AGENT_WS_ROOT` → the workspace root inferred from where this script sits (downstream flat copy: `<root>/multi-agent-task-handoff/` or legacy `<root>/tools/`; source worktree layout: `<root>/multi-agent-task-handoff/scripts/`) → `D:/agent_workspace`. A copy living under an agent's install path (`…/skills/…`, `….codex…`, `….claude…`) is **never** treated as a workspace root — that would make `~/.qoder-cn\skills` the workspace.

## Bootstrapping another agent or machine

To install the convention (rules block in `AGENTS.md`, scripts and templates in the workspace copy folder) into a workspace root that lacks it:

```bash
bash scripts/bootstrap.sh --root <workspace-root>
```

Idempotent: existing files are left untouched, and `AGENTS.md` gains the rule block only if it does not already contain it.

## Source of truth

**The git worktree is the canonical implementation** — on this machine `D:\agent_workspace\multi-agent-task-handoff\`, holding the published layout (`SKILL.md` + `scripts/` + `assets/` + `references/` + `.github/README.md`). Edit skill logic **there**, then `git commit` + `git push`, then propagate with `install-everywhere.ps1`. Since 2026-10-14 the agents' skill folders (`~/.qoder-cn`, `~/.codex`, `~/.claude`) are **downstream copies**: editing there gets overwritten on the next propagation, and `git` isn't even present there anymore (the `.git` directory moved to the worktree with this change).

The three handoff documents at the worktree root — `README.md`, `DESIGN.md`, `CONTEXT.md` — are this workspace's own context and are **gitignored**: they describe `D:` paths and session progress, so publishing them would ship machine-specific notes to people who just cloned a skill.

Downstream workspaces keep a flat synced copy in their **script folder** (`multi-agent-task-handoff/`, legacy `tools/`); both names are accepted by every resolver, and `bootstrap.sh` reuses `tools/` where it already exists so one run never lays down two copies. `bootstrap.sh --root <dir>` detects that the target folder **is** the source and skips syncing in that case:

```bash
bash scripts/bootstrap.sh --root <workspace-root> [--force]
```

Never fix a bug only in a downstream copy — it will be overwritten on the next sync.

## Propagation rule (MANDATORY)

Whenever this skill changes — whether you just edited the worktree or `git pull` brought in new commits — immediately overwrite every local agent's skill copy with the newest content. Run the propagator **from the worktree**:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\agent_workspace\multi-agent-task-handoff\scripts\install-everywhere.ps1
```

- `-Source` defaults to the parent of the `scripts\` folder the script runs from, i.e. the worktree — which is why the layout matters: running it from a downstream flat copy used to point `-Source` at the whole workspace.
- Updating one copy without propagating is a rule violation: the other agents keep enforcing the OLD rules, and their next session silently diverges.
- The same run also re-syncs the script folder of every workspace in its `-WorkspaceRoots` list — including `install-everywhere.ps1` itself (added 2026-10-12; before that the workspace copy of the propagator silently went stale) — **except** when that folder is the source, which it skips instead of flattening scripts into it. Workspaces bootstrapped by hand need `bash scripts/bootstrap.sh --root <workspace-root> --force`.
- **A workspace's existing `AGENTS.md` is NOT rewritten** — both installers dedupe on a heading match and only append when nothing matches. Since 2026-10-14 the marker is the regex `任务[双三]档规范`, so a workspace still carrying the old `任务双档规范` heading is recognized instead of getting a duplicated rule block. After changing rule text here, sync that workspace's `AGENTS.md` (and each agent's global rule file) by hand — the installers never rewrite an existing block.
`templates/` is infrastructure and is excluded from the check. The script folder is excluded **only while it holds no `README.md`** — once it carries the three documents they are checked like a task folder's, which is how 2026-10-14 caught 20 links still pointing at the old `tools/` path.

## Resources

- `scripts/init-task.sh` — create a task folder with the three skeletons.
- `scripts/check-docs.sh` — compliance gate (existence, sections, placeholders, empty scaffolds, freshness).
- `scripts/bootstrap.sh` — install / re-sync the convention into a workspace root.
- `scripts/install-everywhere.ps1` — the Windows propagator that executes the Propagation rule below: skill dirs of every agent + global rule files + every registered workspace. Run the copy from the newest source.
- `assets/README.md.tpl`, `assets/DESIGN.md.tpl`, `assets/CONTEXT.md.tpl` — section skeletons (bootstrap copies these into `multi-agent-task-handoff/templates/`).
- `references/doc-spec.md` — the complete written rule (read when writing or reviewing docs).
- `references/agents-rule.md` — the exact block bootstrap appends to a workspace `AGENTS.md`.
