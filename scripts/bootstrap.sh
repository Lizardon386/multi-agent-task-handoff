#!/usr/bin/env bash
# bootstrap.sh — 把「任务三档规范」装进一个工作区根目录（换机器 / 换 agent / 新工作区时用）
# 用法：bash bootstrap.sh --root <工作区根> [--force]
# 做三件事：1) 复制五份脚本到工作区脚本副本目录（清单须与 install-everywhere.ps1 一致）
#           2) 复制三份模板到 <副本目录>/templates/
#           3) 若 <root>/AGENTS.md 没有「任务三档规范」章节，则追加规则全文（不存在则创建）
# 副本目录 2026-10-14 起叫 multi-agent-task-handoff；工作区里已有旧名 tools/ 时继续用旧名。
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SELF_DIR/.." && pwd)"
ROOT=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:?--root 需要目录参数}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) echo "用法: bash bootstrap.sh --root <工作区根> [--force]"; exit 0 ;;
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

# 去重标记同时接受旧标题「任务双档规范」：2026-10-14 规范从两档扩成三档、标题改成「任务三档规范」，
# 但 bootstrap 与 install-everywhere 都是"缺才写、有就不动"，老工作区里留的是旧标题——
# 标记只认新名的话，会给它们追加出第二份规则块。
RULE_MARK_RE="任务[双三]档规范"
if [ -f "$ROOT/AGENTS.md" ] && grep -qE "$RULE_MARK_RE" "$ROOT/AGENTS.md"; then
  echo "AGENTS.md 已含规则块（标题命中「$RULE_MARK_RE」），不动"
else
  { [ -f "$ROOT/AGENTS.md" ] && printf '\n' >> "$ROOT/AGENTS.md" || printf '# 工作区约定（%s）\n\n' "$(basename "$ROOT")" > "$ROOT/AGENTS.md"; }
  cat "$SKILL_DIR/references/agents-rule.md" >> "$ROOT/AGENTS.md"
  echo "已追加规则块到 AGENTS.md"
fi

echo
echo "完成。root = $ROOT"
if [ "$SKIP_SYNC" = 1 ]; then GATE="$TOOLS_DIR/scripts"; else GATE="$TOOLS_DIR"; fi
echo "下一步：bash \"$GATE/init-task.sh\" <任务名> 建任务；bash \"$GATE/check-docs.sh\" 自检。"
