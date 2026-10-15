#!/usr/bin/env bash
# bootstrap.sh — 把「任务三档规范」装进一个工作区根目录（换机器 / 换 agent / 新工作区时用）
# 用法：bash bootstrap.sh --root <工作区根> [--force] [--entry]
# 做三件事：1) 复制五份脚本到工作区脚本副本目录（清单须与 install-everywhere.ps1 一致）
#           2) 复制三份模板到 <副本目录>/templates/
#           3) 装 AGENTS.md：老锚「任务三档规范」或新锚 `agents-entry` 命中任一就不动；
#              默认整份追加 references/agents-rule.md（并写出处戳），--entry 只生成
#              "本机政策 + 指针"的入口文件——细则从此不在工作区里，也没有同步义务。
# 副本目录 2026-10-14 起叫 multi-agent-task-handoff；工作区里已有旧名 tools/ 时继续用旧名。
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SELF_DIR/.." && pwd)"
ROOT=""
FORCE=0
ENTRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:?--root 需要目录参数}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --entry) ENTRY=1; shift ;;
    -h|--help) echo "用法: bash bootstrap.sh --root <工作区根> [--force] [--entry]"; echo "  --entry  装了 skill 的工作区：生成\"本机政策 + 指针\"的入口文件，不复述条款（此后无同步义务）"; echo "  默认     整份模式：把 references/agents-rule.md 整段追加进去（D/E 档——没有 skill 机制的 agent 需要这个）"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

[ -n "$ROOT" ] || { echo "用法: bash bootstrap.sh --root <工作区根>" >&2; exit 1; }
[ -d "$ROOT" ] || { echo "[错误] 目录不存在: $ROOT" >&2; exit 1; }
# 副本目录名解析：工作区里已存在旧名 tools/ 且还没有新名时沿用 tools/——否则一次 bootstrap
# 就铺出两份脚本，而"哪份是真副本"没人说得清（2026-10-14 本目录正是因为没人认领而改名成了
# multi-agent-task-handoff，全套文档教的 bash tools/init-task.sh 当场失效）。
if [ -d "$ROOT/tools" ] && [ ! -d "$ROOT/multi-agent-task-handoff" ]; then
  TOOLS_DIR="$ROOT/tools"
else
  TOOLS_DIR="$ROOT/multi-agent-task-handoff"
fi

# 真源自己就是那个"副本目录"时不铺自己：2026-10-14 起 skill 仓库的工作树放在
# D:\agent_workspace\multi-agent-task-handoff\（布局是 scripts/ + assets/），
# 往它根目录铺扁平脚本会造出 scripts/check-docs.sh 与 check-docs.sh 两份真源。
SKIP_SYNC=0
if [ "$(cd "$TOOLS_DIR" 2>/dev/null && pwd)" = "$SKILL_DIR" ]; then
  SKIP_SYNC=1
  echo "副本目录即真源（$TOOLS_DIR），跳过脚本/模板同步——在这里改完直接 commit + push + 铺满"
else
  mkdir -p "$TOOLS_DIR/templates"
fi

installed=0
copy_to() {  # $1=src $2=dst
  if [ -e "$2" ] && [ "$FORCE" = 0 ]; then
    echo "已存在，跳过: ${2#$ROOT/}（--force 覆盖）"
  else
    cp "$1" "$2"; echo "已写入: ${2#$ROOT/}"; installed=1
  fi
}

if [ "$SKIP_SYNC" = 0 ]; then
  # 清单必须与 install-everywhere.ps1 第③步、以及它的 Get-CopyExpectedSet **完全一致**：
  # 三处各写一份文件名，少写一个就会被 -Prune 当成"副本里多出来的文件"删掉。
  for s in init-task.sh check-docs.sh bootstrap.sh install-everywhere.ps1 selftest.sh muttest.sh; do
    copy_to "$SKILL_DIR/scripts/$s" "$TOOLS_DIR/$s"
  done
  for t in README.md.tpl DESIGN.md.tpl CONTEXT.md.tpl; do
    copy_to "$SKILL_DIR/assets/$t" "$TOOLS_DIR/templates/$t"
  done
fi

# 去重锚有**两个**，命中任一就不追加：
#   1) 老锚——标题里含「任务三档规范」（历史上还接受拆分前的旧标题「任务双档规范」，只认新名会让
#      留着旧标题的工作区被追加出第二份规则块）；
#   2) 新锚——一行 `<!-- agents-entry -->`，走"入口模式"的工作区根里没有条款文字，靠它判重。
# install-everywhere.ps1 用同一双锚，两处必须一起改（2026-10-15 加入口模式时就是先改这边）。
RULE_MARK_RE="任务[双三]档规范"
# 新锚必须**整行匹配**：agents-rule.md 正文里就会提到 `agents-entry` 这串字，用裸子串匹配会把
# "提到过锚"当成"装了锚"，于是整份模式的文件被误判成入口模式、该追加的不追加（假绿灯）。
ENTRY_MARK_RE='^<!--[[:space:]]*agents-entry[[:space:]]*-->$'
if [ -f "$ROOT/AGENTS.md" ] && grep -qE "$ENTRY_MARK_RE" "$ROOT/AGENTS.md"; then
  echo "AGENTS.md 已是入口模式（新锚：整行命中「$ENTRY_MARK_RE」），不动——细则只在 skill 里"
elif [ -f "$ROOT/AGENTS.md" ] && grep -qE "$RULE_MARK_RE" "$ROOT/AGENTS.md"; then
  echo "AGENTS.md 已含规则块（老锚：标题命中「$RULE_MARK_RE」），不动"
elif [ "$ENTRY" = 1 ]; then
  if [ -f "$ROOT/AGENTS.md" ]; then
    # 既不认老锚也不认新锚的已存在文件：往里灌整段规则等于覆盖别人写的东西，拒绝，让人明确选模式。
    echo "[错误] $ROOT/AGENTS.md 既没有「任务三档规范」标题也没有 <!-- agents-entry -->，我不往来源未知的文件里灌规则。" >&2
    echo "       要整份模式：去掉 --entry 重跑；要入口模式：在该文件里加一行 <!-- agents-entry --> 再重跑。" >&2
    exit 1
  fi
  {
    printf '# 工作区约定（%s）\n\n' "$(basename "$ROOT")"
    printf '<!-- agents-entry -->\n\n'
    printf '> 这个工作区的 agent 会加载 skill，所以本文件**只写本机政策 + 指针**，不复述条款——\n'
    printf '> 细则的唯一权威是 skill `multi-agent-task-handoff` 的 `references/agents-rule.md`，改规矩只改那里。\n'
    printf '> 上面那行 `agents-entry` 是安装器的判重锚：删掉它，下次铺满会往这里追加整段规则。\n\n'
    printf '## 本工作区自己的约定（人手维护，skill 不管这部分）\n\n'
    printf -- '- 在这里写产物落点、盘符、不许动的目录之类的本机/本工作区事实。\n'
  } > "$ROOT/AGENTS.md"
  echo "已生成入口模式 AGENTS.md（政策段落留给你填，规矩不在这里）: $ROOT/AGENTS.md"
else
  { [ -f "$ROOT/AGENTS.md" ] && printf '\n' >> "$ROOT/AGENTS.md" || printf '# 工作区约定（%s）\n\n' "$(basename "$ROOT")" > "$ROOT/AGENTS.md"; }
  cat "$SKILL_DIR/references/agents-rule.md" >> "$ROOT/AGENTS.md"
  # 出处戳：派生物得能回答"我是从哪个版本的原文生成的"，watchdog 的 [出处] 探针靠它算落后多少。
  sha="$(git -C "$SKILL_DIR" log -1 --format=%h -- references/agents-rule.md 2>/dev/null || echo unknown)"
  printf '\n<!-- generated-from: references/agents-rule.md @ %s (%s) -->\n' "$sha" "$(date +%Y-%m-%d)" >> "$ROOT/AGENTS.md"
  echo "已追加规则块到 AGENTS.md（出处戳 @ ${sha}）"
fi

echo
echo "完成。root = $ROOT"
if [ "$SKIP_SYNC" = 1 ]; then GATE="$TOOLS_DIR/scripts"; else GATE="$TOOLS_DIR"; fi
echo "下一步：bash \"$GATE/init-task.sh\" <任务名> 建任务；bash \"$GATE/check-docs.sh\" 自检。"
