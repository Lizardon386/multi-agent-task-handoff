#!/usr/bin/env bash
# 变异测试：把闸门与判重锁逐条改坏，确认 selftest 真的会红。跑完即删，不进仓库。
# 2026-10-16 起靶子不再只有 check-docs.sh：双锚 / 整行匹配 / 出处戳这三条判据各有三套实现
# （bash grep、PowerShell -match、看门狗探针），而它们写错的方向全是**假绿灯**，只能靠"故意改坏
# 一条、看夹具响不响"来证明断言真的钉住了判据。所以这里改成**整树复制**（含 .git）——夹具要读
# references/agents-rule.md 的当前 sha，没有 .git 时戳恒为 unknown，那一批断言会假红，
# 于是每条变异都"像被抓到了"。
set -uo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE="$(cd "$SRC/.." && pwd)"
[ -f "$SRC/check-docs.sh" ] || { echo "找不到 $SRC/check-docs.sh（把本脚本放 scripts/ 旁边跑）"; exit 1; }
[ -d "$TREE/.git" ] || { echo "本脚本要在 skill 的 git 工作树里跑（$TREE/.git 不存在）——出处戳断言依赖 git"; exit 1; }
M=$(mktemp -d /tmp/mut.XXXX)
T="$M/tree"; S="$T/scripts"
mkdir -p "$T"
cp -a "$TREE/." "$T/" || { echo "整树复制失败"; rm -rf "$M"; exit 1; }

fails=0
mut() {  # $1=说明 $2=python 替换表达式 old->new $3=靶子脚本（相对 scripts/，默认闸门）
  local rel="${3:-check-docs.sh}"
  [ -f "$SRC/$rel" ] || { printf '%-30s !! 靶子不存在: %s\n' "$1" "$rel"; fails=$((fails+1)); return; }
  cp "$SRC/$rel" "$S/$rel"   # 每条变异都从干净版本起手，上一条的改动不许串味
  python - "$S/$rel" "$2" <<'PY'
import io, sys
p, expr = sys.argv[1], sys.argv[2]
old, new = [x.strip() for x in expr.split('=>', 1)]
s = io.open(p, encoding='utf-8').read()
if old not in s:
    sys.stderr.write('ANCHOR-MISS: ' + old[:60] + '\n'); sys.exit(3)
io.open(p, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new, 1))
PY
  if [ $? -ne 0 ]; then printf '%-30s !! 锚点没命中，变异未施加\n' "$1"; fails=$((fails+1)); return; fi
  out=$(bash "$S/selftest.sh" 2>&1); code=$?
  first=$(grep -m1 -E 'FAIL|不符' <<<"$out" | cut -c1-50)
  if [ "$code" = 0 ]; then
    printf '%-30s ✗ 没抓到（全绿）\n' "$1"; fails=$((fails+1))
  else
    printf '%-30s ✓ %s\n' "$1" "$first"
  fi
  cp "$SRC/$rel" "$S/$rel"   # 还原，别让下一条变异在坏文件上跑
}

mut "去掉 10# 十进制前缀"        'y=$((10#$y)); m=$((10#$m)); d=$((10#$d)) => y=$((y)); m=$((m)); d=$((d))'
mut "substr 长度写成 j-1"        'out = out substr(s, i, j - i) => out = out substr(s, i, j - 1)'
mut "去掉 prodlines>0 条件"      'prodlines > 0 && !prodlink => !prodlink'
mut "等长 run 改任意长度闭合"    'if (r2 == run) { close_at = k; break } => if (r2 >= 1) { close_at = k; break }'
mut "反引号改成简单成对"        'if (r2 == run) { close_at = k; break } => if (r2 == 1) { close_at = k; break }'
mut "完全不剥行内 code"          'emit(strip_code($0)) => emit($0)'
mut "围栏开关去掉"              'inb { next } => if (0) next'
mut "epoch 常数偏一天"          'doe - 719468 => doe - 719469'
mut "AGENTS.md 豁免去掉"        'case "$f" in */AGENTS.md) continue ;; esac => :'
mut "[题] 改成硬相等"           '*"$dn"*) : ;; => "$dn") : ;;'
mut "SKILL.md 豁免去掉"         'AGENTS.md|SKILL.md) continue => AGENTS.md) continue'
mut "GAP 放宽到两列表"          'if (cells == 3) { => if (cells >= 2) {'
mut "GAP 判定整块去掉"          'if (has_empty && !all_empty && gap == "") gap = FNR => if (0) gap = FNR'
mut "三格全空那条去掉"          'if (line ~ /^\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*\|$/) emptyrow = 1 => if (0) emptyrow = 1'
mut "[占] 日期锚定放宽"          'if (line ~ /^> 最近更新：(YYYY-MM-DD|)$/) dateunfilled = 1 => if (line ~ /最近更新：(YYYY-MM-DD|)$/) dateunfilled = 1'
mut "top_date 不锚定行首"        'line ~ /^> 最近更新：[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ => line ~ /> 最近更新：[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/'
mut "[名] 判反成"                'if ! has_nonascii "$b"; then => if has_nonascii "$b"; then'
mut "副本目录无条件跳过"        'tools|multi-agent-task-handoff) [ -f "$taskdir/README.md" ] || continue ;; => tools|multi-agent-task-handoff) continue ;;'

echo
# ── 判重锁（2026-10-16 加）：三套实现各改坏一处，selftest 第 6 组必须响 ────────
# 这批变异的方向全是**假绿灯**（该追加的不追加、该红的红不了），所以每条都对应一条断言。
mut "bs: 入口锚退化成裸子串"   "ENTRY_MARK_RE='^<!--[[:space:]]*agents-entry[[:space:]]*-->\$' => ENTRY_MARK_RE='agents-entry'" bootstrap.sh
mut "bs: 去掉行尾锚定"        "ENTRY_MARK_RE='^<!--[[:space:]]*agents-entry[[:space:]]*-->\$' => ENTRY_MARK_RE='^<!--[[:space:]]*agents-entry[[:space:]]*-->'" bootstrap.sh
mut "bs: 老锚只认新名"        "RULE_MARK_RE=\"任务[双三]档规范\" => RULE_MARK_RE=\"任务三档规范\"" bootstrap.sh
mut "bs: 出处戳字段名漂了"     "printf '\\n<!-- generated-from: references/agents-rule.md @ %s (%s) -->\\n' => printf '\\n<!-- generated_from: references/agents-rule.md @ %s (%s) -->\\n'" bootstrap.sh
mut "狗: 锚判据退化成裸子串"    "grep -qE '^<!--[[:space:]]*agents-entry[[:space:]]*-->\$' \"\$e\" => grep -qE 'agents-entry' \"\$e\"" watchdog.sh
mut "ps1: 丢掉 (?m) 多行开关"  "\$entryMarker = '(?m)^\\s*<!--\\s*agents-entry\\s*-->\\s*\$' => \$entryMarker = '^\\s*<!--\\s*agents-entry\\s*-->\\s*\$'" install-everywhere.ps1
mut "ps1: 老锚只认新名"        "\$marker = \"任务[双三]档规范\" => \$marker = \"任务三档规范\"" install-everywhere.ps1

rm -rf "$M"
echo
if [ "$fails" = 0 ]; then echo "变异测试：全部被抓到"; else echo "变异测试：$fails 条没抓到或没施加"; exit 1; fi
