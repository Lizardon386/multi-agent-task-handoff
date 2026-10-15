#!/usr/bin/env bash
# watchdog.sh — 「副本 == 真源」的终审：逐字节比对每个下游副本，顺带跑一遍收工闸门。
# 只在有问题时留下可见产物（日志 + .watchdog/_需要处理.md），全绿就把待处理件撤掉。
# 用法：bash watchdog.sh [--source <工作树>] [--copies <目录1,目录2>] [--gate] [--no-mark]
# 退出码：0 无漂移；1 有漂移或闸门红；2 配置错（找不到真源，或给了个不是工作树的路径）
# 为什么需要它：post-merge 只在**别人 pull**时跑，pre-push 只在**本机 push**时跑，
# 而"改了没铺"恰恰发生在既不 pull 也不 push 的那条缝里——本仓库为这条缝记过两次事故。
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SELF_DIR/check-docs.sh"
SOURCE=""
COPIES=""
RUN_GATE=1
MAKE_MARK=1

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE="${2:?--source 需要工作树路径}"; shift 2 ;;
    --copies) COPIES="${2:?--copies 需要逗号分隔的目录列表}"; shift 2 ;;
    --no-gate) RUN_GATE=0; shift ;;
    --no-mark) MAKE_MARK=0; shift ;;
    -h|--help) echo "用法: bash watchdog.sh [--source <工作树>] [--copies d1,d2] [--no-gate] [--no-mark]"; exit 0 ;;
    *) echo "未知参数: $1（-h 看用法）"; exit 2 ;;
  esac
done

# 真源必须是**工作树**：拿一份下游副本当源去比副本，两边都是旧的，结果是假绿灯。
# 判据用 .git 目录存在，不看目录名——改名或搬机器时目录名靠不住。
if [ -z "$SOURCE" ]; then
  SOURCE="$(cd "$SELF_DIR/.." && pwd)"
fi
SOURCE="${SOURCE%/}"
if [ ! -f "$SOURCE/SKILL.md" ] || [ ! -e "$SOURCE/.git" ]; then
  echo "不是 skill 仓库的工作树: $SOURCE"
  echo "  （需要 SKILL.md + .git；从下游副本里跑没意义，请用 --source 指向工作树）"
  exit 2
fi

if [ -z "$COPIES" ]; then
  HOME_DIR="${HOME:-${USERPROFILE:-}}"
  COPIES="$HOME_DIR/.qoder-cn/skills/multi-agent-task-handoff,$HOME_DIR/.codex/skills/multi-agent-task-handoff,$HOME_DIR/.claude/skills/multi-agent-task-handoff"
fi

problems=""
report=""
IFS=',' read -ra COPY_ARR <<< "$COPIES"
for c in "${COPY_ARR[@]}"; do
  c="${c%/}"
  if [ ! -d "$c" ]; then
    report="${report}  [跳过] $c 不存在
"
    continue
  fi
  # -q 只列不同的文件名，副本多几千行也不至于把日志刷爆；-x .git 两边都排除。
  d="$(diff -rq -x .git "$SOURCE" "$c" 2>&1)"
  if [ -n "$d" ]; then
    problems="${problems}  [漂] $c
$(printf '%s\n' "$d" | sed 's/^/    /')
"
    report="${report}  [漂] $c 与真源不一致（$(printf '%s\n' "$d" | grep -c '^') 行差异）
"
  else
    report="${report}  [绿] $c == 真源
"
  fi
done

if [ "$RUN_GATE" = 1 ]; then
  gate_out="$(bash "$GATE" 2>&1)"; gate_rc=$?
  if [ "$gate_rc" != 0 ]; then
    problems="${problems}  [闸门] 不合规（exit $gate_rc）
$(printf '%s\n' "$gate_out" | sed 's/^/    /')
"
    report="${report}  [闸门] 不合规（exit $gate_rc）
"
  else
    report="${report}  [闸门] 全绿
"
  fi
fi

# 日志与待处理件放工作区根的 .watchdog/：bash 的 */ glob 不匹配点开头目录，
# 所以闸门不会把它当任务目录查（它没有三档，被查必红）。
WS_ROOT="$(cd "$SOURCE/.." && pwd)"
LOG_DIR="$WS_ROOT/.watchdog"
MARK="$LOG_DIR/_需要处理.md"
[ "$MAKE_MARK" = 1 ] && mkdir -p "$LOG_DIR" 2>/dev/null

ts="$(date '+%Y-%m-%d %H:%M:%S')"
if [ "$MAKE_MARK" = 1 ]; then
  {
    echo "---- $ts  source=$SOURCE"
    printf '%s' "$report"
    [ -n "$problems" ] && printf '%s\n' "问题明细:" && printf '%s' "$problems"
  } >> "$LOG_DIR/propagation.log" 2>/dev/null
fi

printf 'watchdog %s\n%s' "$ts" "$report"
if [ -z "$problems" ]; then
  # 只删自己写的那份：别的同名文件不是本脚本的产物，不碰。
  if [ -f "$MARK" ] && [ "$MAKE_MARK" = 1 ]; then rm -f "$MARK"; fi
  echo "OK: 所有下游副本与真源逐字节一致，闸门全绿"
  exit 0
fi

echo "问题明细:"
printf '%s' "$problems"
if [ "$MAKE_MARK" = 1 ]; then
  {
    echo "# 铺满漂移待处理（$ts）"
    echo
    echo "> 由 \`scripts/watchdog.sh\` 生成，全绿时会被自动撤掉。"
    echo
    echo "## 怎么修"
    echo
    echo "- 副本漂移：从工作树跑一次铺满 \`powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\install-everywhere.ps1 -Prune\`"
    echo "  （**如果你在副本里手改过 skill 文件，那份改动会被覆盖——先提回工作树再铺**）"
    echo "- 闸门红：看下面明细里的前缀，规则见工作区根 \`AGENTS.md\` 的「任务三档规范」"
    echo
    echo "## 明细"
    echo
    echo '```'
    printf '%s' "$problems"
    echo '```'
  } > "$MARK" 2>/dev/null && echo "已写待处理件: $MARK"
fi
exit 1
