#!/usr/bin/env bash
# watchdog.sh — 三件事的终审：① 各下游副本 == 真源（diff 逐字节）② 派生规则文件的 [锚]/[出处]/[指针]
#                ③ 顺带跑一遍收工闸门。只在有问题时留下可见产物（日志 + .watchdog/_需要处理.md），
#                全绿就把待处理件撤掉；全绿也每类打一行，让"跑过"这件事本身有痕迹。
# 用法：bash watchdog.sh [--source <工作树>] [--copies d1,d2] [--entries f1,f2] [--no-gate] [--no-mark]
# 退出码：0 无漂移；1 有漂移/探针红/闸门红；2 配置错（找不到真源，或一个副本都没比对到）
# 为什么需要它：post-merge 只在**别人 pull**时跑，pre-push 只在**本机 push**时跑，
# 而"改了没铺"恰恰发生在既不 pull 也不 push 的那条缝里——本仓库为这条缝记过两次事故。
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SELF_DIR/check-docs.sh"
SOURCE=""
COPIES=""
RUN_GATE=1
MAKE_MARK=1
ENTRIES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE="${2:?--source 需要工作树路径}"; shift 2 ;;
    --copies) COPIES="${2:?--copies 需要逗号分隔的目录列表}"; shift 2 ;;
    --no-gate) RUN_GATE=0; shift ;;
    --entries) ENTRIES="${2:?--entries 需要逗号分隔的文件列表}"; shift 2 ;;
    --no-mark) MAKE_MARK=0; shift ;;
    -h|--help) echo "用法: bash watchdog.sh [--source <工作树>] [--copies d1,d2] [--entries f1,f2] [--no-gate] [--no-mark]"; exit 0 ;;
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

# HOME 归一：计划任务里 HOME 常指向 MSYS 的 /home/<user>，而技能与全局规则文件只装在
# USERPROFILE（C:\Users\<user>）下面。两个都收进 _homes 并去重，让副本名单与入口名单共用。
norm_win() { local h="${1//\\//}"; case "$h" in ?:[/]*) h="/$(printf '%s' "${h:0:1}" | tr 'A-Z' 'a-z')${h:2}" ;; esac; printf '%s' "${h%/}"; }
_homes=()
for _raw in "${HOME:-}" "${USERPROFILE:-}"; do
  [ -n "$_raw" ] || continue
  _h="$(norm_win "$_raw")"
  [ -n "$_h" ] || continue
  _dup=0
  for _e in "${_homes[@]}"; do [ "$_e" = "$_h" ] && { _dup=1; break; }; done
  [ "$_dup" = 0 ] && _homes+=("$_h")
done

if [ -z "$COPIES" ]; then
  for _h in "${_homes[@]}"; do
    for _ag in .qoder-cn .codex .claude; do
      COPIES="${COPIES:+$COPIES,}$_h/$_ag/skills/multi-agent-task-handoff"
    done
  done
  [ -n "$COPIES" ] || { echo "HOME 与 USERPROFILE 都取不到，无法推断副本目录——请用 --copies 显式给出"; exit 2; }
fi

problems=""
report=""
checked=0
IFS=',' read -ra COPY_ARR <<< "$COPIES"
for c in "${COPY_ARR[@]}"; do
  # 名单也接受 Windows 写法：C:\Users\x 与 C:/Users/x 都归一到 /c/Users/x，
  # 否则计划任务里手填的反斜杠路径会让每个目录都"不存在"。
  c="${c//\\//}"
  case "$c" in
    ?:[/]*) c="/$(printf '%s' "${c:0:1}" | tr 'A-Z' 'a-z')${c:2}" ;;
  esac
  c="${c%/}"
  [ -z "$c" ] && continue
  if [ ! -d "$c" ]; then
    report="${report}  [跳过] $c 不存在
"
    continue
  fi
  checked=$((checked + 1))
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

if [ "$checked" = 0 ]; then
  # 一个副本都没比对不等于全绿——计划任务里 HOME 常常指向 /home/<user> 而不是 C:\Users\<user>，
  # 名单因此整批落空。这种"没查"必须响，否则看门狗自己就成了假绿灯的制造者。
  echo "没有可比对的副本目录（名单里全是「不存在」）——这是没查，不是绿。用 --copies 显式传路径。"
  printf '%s' "$report"
  exit 2
fi

# ── 派生规则文件的探针：[锚] / [出处] / [指针] ────────────────────────────────
# 工作区根 `AGENTS.md` 与各 agent 的全局规则文件是**派生物**：没有版本控制，闸门也刻意不查
# `AGENTS.md`（规则正文里全是语法示例）。它们漂了只有这里能发现，而本机已经漂过三次。
#   [锚]    双锚之一在不在（老锚「任务三档规范」/ 整行的 <!-- agents-entry -->）。
#            两个都没有 → 安装器会拒绝往里灌规矩，读它的 agent 一条规矩也拿不到 → 判失败。
#   [出处]  generated-from 戳 vs 真源当前版本。落后只**告警不算失败**——"只补不覆盖"是刻意的，
#            自动重写会把工作区自己写的本地政策一起冲掉；探针的价值是把"漂了没人知道"变成量。
#   [指针]  文里点名的 references/*.md、scripts/*.{sh,ps1} 必须在真源里存在，指错=规矩找不到。
WS_ROOT="$(cd "$SOURCE/.." && pwd)"
SRC_SHA="$(git -C "$SOURCE" log -1 --format=%h -- references/agents-rule.md 2>/dev/null || echo '')"
if [ -z "$ENTRIES" ]; then
  ENTRIES="$WS_ROOT/AGENTS.md"
  for _h in "${_homes[@]}"; do
    ENTRIES="$ENTRIES,$_h/.codex/AGENTS.md,$_h/.claude/CLAUDE.md"
  done
fi
IFS=',' read -ra ENT_ARR <<< "$ENTRIES"
for e in "${ENT_ARR[@]}"; do
  e="$(norm_win "$e")"
  [ -n "$e" ] || continue
  if [ ! -f "$e" ]; then
    report="${report}  [跳过] 规则文件 $e 不存在
"
    continue
  fi
  # ① 锚（先查新锚：入口文件若顺带提到"任务三档规范"几个字，不该被误标成整份模式）
  if grep -qE '^<!--[[:space:]]*agents-entry[[:space:]]*-->$' "$e"; then
    report="${report}  [锚] $e 入口模式（新锚命中）
"
  elif grep -qE '任务[双三]档规范' "$e"; then
    report="${report}  [锚] $e 整份模式（老锚命中）
"
  else
    problems="${problems}  [锚] $e 既没有「任务三档规范」标题也没有整行的 <!-- agents-entry -->
    → 安装器会拒绝往里灌规矩（怕覆盖你写的东西），结果读它的 agent 一条规矩也拿不到
"
  fi
  # ② 出处戳
  stamped="$(grep -oE 'generated-from: references/agents-rule.md @ [0-9a-f]+' "$e" 2>/dev/null | head -1 | awk '{print $NF}')"
  if [ -z "$stamped" ]; then
    report="${report}  [出处] $e 无出处戳（2026-10-15 之前生成的，下次重写才会带上）
"
  elif [ -z "$SRC_SHA" ] || [ "$stamped" = "$SRC_SHA" ]; then
    report="${report}  [出处] $e 与原文同步（@ ${stamped}）
"
  else
    behind="$(git -C "$SOURCE" rev-list --count "${stamped}..${SRC_SHA}" -- references/agents-rule.md 2>/dev/null || echo '?')"
    report="${report}  [出处] $e 落后原文 ${behind} 个提交（戳 @ ${stamped}，现 @ ${SRC_SHA}）——只补不覆盖是刻意的，要新版请手工同步那一段
"
  fi
  # ③ 指针
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    [ -e "$SOURCE/$p" ] && continue
    problems="${problems}  [指针] $e 指向真源里不存在的文件: ${p}
"
  done < <(grep -oE '(references/[A-Za-z0-9._-]+\.md|scripts/[A-Za-z0-9._-]+\.(sh|ps1))' "$e" 2>/dev/null | sort -u)
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
# 所以闸门不会把它当任务目录查（它没有三档，被查必红）。WS_ROOT 已在上面探针段算过。
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
