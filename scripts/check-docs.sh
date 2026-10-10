#!/usr/bin/env bash
# check-docs.sh — 校验每个任务目录的 README.md / CONTEXT.md 双档是否齐全且结构合规
# 用法：bash check-docs.sh [--root <工作区根>] [<任务目录名>]
# 退出码：0 全部合规；1 有缺项（agent 收工自查闸门）
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${AGENT_WS_ROOT:-}"
ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:?--root 需要目录参数}"; shift 2 ;;
    -h|--help) echo "用法: bash check-docs.sh [--root <工作区根>] [<任务目录名>]"; exit 0 ;;
    *) ONLY="$1"; shift ;;
  esac
done

if [ -z "$ROOT" ]; then
  case "$SELF_DIR" in */tools) ROOT="$(cd "$SELF_DIR/.." && pwd)" ;; esac
fi
ROOT="${ROOT:-D:/agent_workspace}"

STALE_DAYS="${STALE_DAYS:-30}"
README_SECTIONS="一句话说明|设计思路|快速开始|使用说明|产物与目录|限制与注意事项"
CONTEXT_SECTIONS="背景与目标|当前状态|计划|关键约束与注意事项|变更记录|给下一个"

fail=0

have_section() {
  local missing="" s
  IFS='|' read -ra arr <<< "$2"
  for s in "${arr[@]}"; do
    grep -qE "^## +.*$s" "$1" || missing="$missing «$s»"
  done
  printf '%s' "$missing"
}

# 顶部日期只认 blockquote 行（与 [占] 的锚定一致）。不锚定的话，正文里出现的
# 「最近更新：日期」会在顶部缺失时被 head -1 当成顶部日期，[新] 就静默失效。
top_date() {
  grep -oE "^> 最近更新：[0-9]{4}-[0-9]{2}-[0-9]{2}" "$1" 2>/dev/null \
    | head -1 | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}"
}

check_doc() {
  local p="$1" secs="$2" label="$3" miss
  if [ ! -f "$p" ]; then
    echo "  [缺] $label.md 不存在"; fail=1; return
  fi
  miss="$(have_section "$p" "$secs")"
  if [ -n "$miss" ]; then echo "  [构] $label.md 缺章节:$miss"; fail=1; fi
  if grep -q "<任务目录名>" "$p"; then
    echo "  [占] $label.md 仍带 <任务目录名> 占位符"; fail=1
  fi
  if grep -qE "^> 最近更新：(YYYY-MM-DD|)$" "$p"; then
    echo "  [占] $label.md 顶部「最近更新」未填"; fail=1
  fi
  if [ "$label" = README ] && grep -qE "^\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*\|$" "$p"; then
    echo "  [空] README.md 设计思路表还是空行，取舍没写"; fail=1
  fi
  if [ "$label" = README ]; then
    local sect
    sect=$(awk '/^## +.*产物与目录/{f=1;next} /^## /{f=0} f' "$p")
    if [ -n "$sect" ] && ! printf '%s' "$sect" | grep -q 'file:///'; then
      echo "  [链] $label.md 「产物与目录」没有可点击的 file:/// 链接，用户点不开"
      fail=1
    fi
  fi
  if [ "$label" = CONTEXT ] && grep -qE "^- \[ \]$" "$p"; then
    echo "  [空] CONTEXT.md 待办还是空复选框，目标没写"; fail=1
  fi
  local d
  d="$(top_date "$p")"
  if [ -z "$d" ]; then
    echo "  [新] $label.md 顶部无「最近更新：YYYY-MM-DD」"; fail=1
  else
    local age=$(( ( $(date +%s) - $(date -d "$d" +%s) ) / 86400 ))
    [ "$age" -gt "$STALE_DAYS" ] && echo "  [旧] $label.md 上次更新 $d（${age} 天 > ${STALE_DAYS}天）— 确认已归档还是需要补记（仅告警）"
  fi
}

for taskdir in "$ROOT"/*/; do
  [ -d "$taskdir" ] || continue
  name=$(basename "$taskdir")
  case "$name" in tools|templates|node_modules|.git) continue ;; esac
  [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
  echo "== $name"
  check_doc "$taskdir/README.md"  "$README_SECTIONS"  README
  check_doc "$taskdir/CONTEXT.md" "$CONTEXT_SECTIONS" CONTEXT
  # 两档顶部「最近更新」必须同日：一边改了另一边没跟上，说明有一侧在说谎
  rd="$(top_date "$taskdir/README.md")"
  ctxd="$(top_date "$taskdir/CONTEXT.md")"
  if [ -n "$rd" ] && [ -n "$ctxd" ] && [ "$rd" != "$ctxd" ]; then
    echo "  [期] 两档「最近更新」不一致：README=$rd CONTEXT=$ctxd — 有一侧改动没同步（必须同日）"
    fail=1
  fi
done

echo
if [ "$fail" = 0 ]; then
  echo "OK: 双档齐全且结构合规（root: $ROOT）"
else
  echo "不合规见上。规则见 $ROOT/AGENTS.md「任务双档规范」；新任务用 bash tools/init-task.sh <任务名>"
fi
exit $fail
