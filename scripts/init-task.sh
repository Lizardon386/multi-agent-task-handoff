#!/usr/bin/env bash
# init-task.sh — 创建任务目录并铺好 README.md / DESIGN.md / CONTEXT.md 三档骨架
# 用法：bash init-task.sh [--root <工作区根>] <任务目录名>
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${AGENT_WS_ROOT:-}"
NAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:?--root 需要目录参数}"; shift 2 ;;
    -h|--help) echo "用法: bash init-task.sh [--root <工作区根>] <任务目录名>"; exit 0 ;;
    *) NAME="$1"; shift ;;
  esac
done

[ -n "$NAME" ] || { echo "用法: bash init-task.sh [--root <工作区根>] <任务目录名>" >&2; exit 1; }

if [ -z "$ROOT" ]; then
  # 布局判定与 check-docs.sh 一致：扁平副本在 <root>/<副本目录>/，仓库与工作副本在 <root>/<副本目录>/scripts/，
  # 而 …/skills/… 与 …\.codex\…\.claude\ 下的那份是 agent 的安装目录，不是工作区。
  case "$(basename "$SELF_DIR")" in
    tools|multi-agent-task-handoff) ROOT="$(cd "$SELF_DIR/.." && pwd)" ;;
    scripts)
      case "$SELF_DIR" in */skills/*|*/.codex/*|*/.claude/*) : ;;
        *) case "$(basename "$(dirname "$SELF_DIR")")" in
             tools|multi-agent-task-handoff) ROOT="$(cd "$SELF_DIR/../.." && pwd)" ;;
           esac ;;
      esac ;;
  esac
fi
ROOT="${ROOT:-D:/agent_workspace}"

TPL=""
for c in "$SELF_DIR/../assets" "$ROOT/multi-agent-task-handoff/templates" "$ROOT/tools/templates"; do
  [ -f "$c/README.md.tpl" ] && { TPL="$c"; break; }
done
[ -n "$TPL" ] || { echo "[错误] 找不到模板目录（skill 的 assets/ 或副本目录下的 templates/）" >&2; exit 1; }

TASK="$ROOT/$NAME"
mkdir -p "$TASK"
TODAY=$(date +%Y-%m-%d)

for doc in README DESIGN CONTEXT; do
  dst="$TASK/$doc.md"
  if [ -e "$dst" ]; then echo "已存在，跳过: $doc.md"; continue; fi
  sed "s/<任务目录名>/$NAME/g; s/YYYY-MM-DD/$TODAY/g" "$TPL/$doc.md.tpl" > "$dst"
  echo "已创建: $doc.md"
done

echo
echo "骨架已铺好（空取舍表/空待办会被 check-docs.sh 判不合规）。下一步：填 DESIGN.md 的「设计思路」决策/理由/代价，与 README.md 的使用说明、CONTEXT.md 的「背景与目标」。"
