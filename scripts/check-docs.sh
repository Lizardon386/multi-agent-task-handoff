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

# 顶层「其他输出文档」必须中文命名。README/CONTEXT/AGENTS 是规范固定名，_ 前缀是机器
# 产物（如 _ref-*），非 .md 文件（.docx/.pdf 常需与对方系统里的原件同名）一律豁免。
# 只用 LC_ALL=C 判「含非 ASCII 字节」，不依赖 grep -P（收件方的 grep 未必编译了 PCRE）。
check_names() {
  local dir="$1" f b
  for f in "$dir"*.md; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    case "$b" in README.md|CONTEXT.md|AGENTS.md) continue ;; esac
    case "$b" in _*) continue ;; esac
    if ! LC_ALL=C grep -q '[^ -~]' <<< "$b"; then
      echo "  [名] $b 顶层输出文档必须用中文命名（双档与 _ 前缀机器产物除外）"
      fail=1
    fi
  done
}

# 平台判定只做一次（一个子进程），供 _norm 决定是否把 /d/x 当 msys 盘符。
case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) ON_WINDOWS=1 ;; *) ON_WINDOWS=0 ;; esac

# 路径归一：msys 的 /d/x 与 Windows 的 D:/x 视为同一个根；file:/// 剥掉三斜杠后
# Linux 路径会丢前导斜杠，这里统一补回。不补这层，非 Windows 的根会让前缀比较全部
# 落空、可达性校验静默跳过（假绿灯）。
# /d/x 的盘符转换仅在 Windows/msys 下做——否则 Linux 上真存在 /u/x 这种根时会被
# 误认成 u: 盘，存在性测试就指向了一个不存在的 Windows 路径。
# 结果写进全局 NORM 而非 echo——本函数每条链接调两次，用命令替换会各起一个子 shell，
# 262 条链接就把闸门从 8 秒拖到 38 秒。纯 bash 字符串操作才留得住收工必跑的意愿。
_norm() {  # $1=路径  $2=lc 则小写（仅用于比较）
  local p="${1#file:///}"
  case "$p" in
    [a-zA-Z]:*) ;;                       # Windows: D:/x
    /[a-zA-Z]/*) if [ "$ON_WINDOWS" = 1 ]; then p="${p:1:1}:/${p#/*/}"; fi ;;
    *) p="/${p#/}" ;;                    # 缺前导斜杠才补，已有则不重复
  esac
  while [ -n "$p" ] && [ "${p%/}" != "$p" ]; do p="${p%/}"; done
  [ "${2:-}" = lc ] && p="${p,,}"
  NORM="$p"
}
canon() { _norm "$1" lc; printf '%s' "$NORM"; }

# [链] 之二：链接可达性。只校验指向本工作区内部的 file:/// 目标——脚本会发给别的机器，
# 对方没有 D: 盘，指向外部的链接一律放过才不会全线误报。
check_links() {
  local dir="$1" f dead raw u rootc
  rootc="$(canon "$ROOT")"
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    dead="$(
      while IFS= read -r raw; do
        u="${raw%%#*}"
        case "$u" in *%*) u=$(printf '%b' "${u//%/\\x}");; esac   # 只在真需要时解码
        _norm "$u" lc
        case "$NORM" in "$rootc"/*) : ;; *) continue ;; esac
        _norm "$u"
        [ -e "$NORM" ] || printf '  [链] %s 链接指向不存在的文件: %s\n' "$(basename "$f")" "$raw"
      done < <(grep -oE '\]\(file:///[^)]+\)' "$f" 2>/dev/null | sed 's|^](||; s|)$||')
    )"
    if [ -n "$dead" ]; then printf '%s\n' "$dead"; fail=1; fi
  done < <(find "$dir" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
}

# [链] 之三：反引号裸文件名。指向本任务目录内真实存在的 .md/.txt 却没有写成 file:/// 链接
# 的行——用户点不开，是死链的姊妹问题（2026-10-10 dsp-hal-eval 改名后 README「产物与目录」
# 的 archive 条目就踩了这个）。已在 markdown 链接 display text（`` [`x.md`](...) ``）里的
# 不算违规。fenced code block 里的不算违规。
check_bare_refs() {
  local dir="$1" f rel bn hit
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    bn="$(basename "$f")"
    case "$bn" in README.md|CONTEXT.md|AGENTS.md) continue ;; esac
    hit="$(
      awk -v file="$f" -v dir="$dir" '
        /^```/ { fence = !fence; next }
        fence { next }
        {
          s = $0
          while (match(s, /`[^`\/:]*\.(md|txt)`/)) {
            tok = substr(s, RSTART, RLENGTH)
            before = substr(s, 1, RSTART-1)
            after = substr(s, RSTART+RLENGTH)
            inner = substr(tok, 2, length(tok)-2)
            # link display text: [`inner`](...) or [`inner`]
            if (before ~ /\[$/ && (after ~ /^\]\(/ || after ~ /^\]/)) {
              # skip
            } else if (system("[ -e \"" dir "/" inner "\" ] || [ -e \"" dir "/archive/" inner "\" ] || [ -e \"" dir "/inputs/" inner "\" ]")==0) {
              printf "%d %s\n", NR, inner
            }
            s = after
          }
        }
      ' "$f" 2>/dev/null
    )"
    if [ -n "$hit" ]; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        echo "  [链] $(basename "$f") 反引号裸文件名应为 file:/// 链接: \`$line\`"
        fail=1
      done <<< "$hit"
    fi
  done < <(find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null)
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
    # 先剥掉 HTML 注释：模板在注释和表头里写了 file:/// 示例，不剥的话空表格也会"命中链接"，
    # 变成假绿灯。
    sect=$(awk '/^## +.*产物与目录/{f=1;next} /^## /{f=0} f' "$p" | sed '/<!--/,/-->/d')
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
  check_names "$taskdir"
  check_links "$taskdir"
  check_bare_refs "$taskdir"
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
