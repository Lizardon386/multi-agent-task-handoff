#!/usr/bin/env bash
# 变异测试：把闸门逐条改坏，确认 selftest 真的会红。跑完即删，不进仓库。
set -uo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SRC/check-docs.sh"
[ -f "$GATE" ] || { echo "找不到 $GATE（把本脚本放 scripts/ 旁边跑）"; exit 1; }
M=$(mktemp -d /tmp/mut.XXXX)
cp "$SRC/selftest.sh" "$M/selftest.sh"

fails=0
mut() {  # $1=说明 $2=python 替换表达式 old->new
  cp "$GATE" "$M/check-docs.sh"
  python - "$M/check-docs.sh" "$2" <<'PY'
import io, sys
p, expr = sys.argv[1], sys.argv[2]
old, new = [x.strip() for x in expr.split('=>', 1)]
s = io.open(p, encoding='utf-8').read()
if old not in s:
    sys.stderr.write('ANCHOR-MISS: ' + old[:60] + '\n'); sys.exit(3)
io.open(p, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new, 1))
PY
  if [ $? -ne 0 ]; then printf '%-30s !! 锚点没命中，变异未施加\n' "$1"; fails=$((fails+1)); return; fi
  out=$(bash "$M/selftest.sh" 2>&1); code=$?
  first=$(grep -m1 -E 'FAIL|不符' <<<"$out" | cut -c1-50)
  if [ "$code" = 0 ]; then
    printf '%-30s ✗ 没抓到（全绿）\n' "$1"; fails=$((fails+1))
  else
    printf '%-30s ✓ %s\n' "$1" "$first"
  fi
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

rm -rf "$M"
echo
if [ "$fails" = 0 ]; then echo "变异测试：全部被抓到"; else echo "变异测试：$fails 条没抓到或没施加"; exit 1; fi
