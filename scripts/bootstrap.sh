#!/usr/bin/env bash
# bootstrap.sh — 把「任务三档规范」装进一个工作区根目录（换机器 / 换 agent / 新工作区时用）
# 用法：bash bootstrap.sh --root <工作区根> [--force]
# 做三件事：1) 复制 init-task.sh / check-docs.sh 到 <root>/tools/
#           2) 复制三份模板到 <root>/tools/templates/
#           3) 若 <root>/AGENTS.md 没有「任务三档规范」章节，则追加规则全文（不存在则创建）
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
mkdir -p "$ROOT/tools/templates"

installed=0
copy_to() {  # $1=src $2=dst
  if [ -e "$2" ] && [ "$FORCE" = 0 ]; then
    echo "已存在，跳过: ${2#$ROOT/}（--force 覆盖）"
  else
    cp "$1" "$2"; echo "已写入: ${2#$ROOT/}"; installed=1
  fi
}

for s in init-task.sh check-docs.sh; do
  copy_to "$SKILL_DIR/scripts/$s" "$ROOT/tools/$s"
done
for t in README.md.tpl DESIGN.md.tpl CONTEXT.md.tpl; do
  copy_to "$SKILL_DIR/assets/$t" "$ROOT/tools/templates/$t"
done

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
echo "下一步：bash \"$ROOT/tools/init-task.sh\" <任务名> 建任务；bash \"$ROOT/tools/check-docs.sh\" 自检。"
