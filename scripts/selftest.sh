#!/usr/bin/env bash
# selftest.sh — 闸门与判重锁的夹具自检：改 check-docs.sh / bootstrap.sh / watchdog.sh /
#               install-everywhere.ps1 前后都跑它。
# 用法：bash selftest.sh     （在隔离临时根上跑，不碰任何真实任务目录；需要 git，
#        有 powershell.exe 时顺带验 PowerShell 那一套实现，没有则跳过那一组）
# 退出码：0 全部断言通过；1 有断言失败（失败打印期望与实际）
#
# 为什么要有这个文件：2026-10-14 一天之内三个会话各造一遍"跑完即删"的夹具来验
# `[链]`/`[档]`/`[期]`，每次重新想该造哪几条、什么都没留下。断言固化在这里之后，
# "反向验证"从口头承诺变成一条命令。
#
# 结构上的硬要求：**夹具全部先建完，闸门只跑一次**，断言只在那一份输出里按目录切段查。
# 逐条断言各跑一次闸门实测 55 秒（Windows 起子进程 ~25ms，每目录上百次），而
# "慢的检查没人跑"是本仓库自己记过的教训（38 秒那版就是被人绕过去的）。
set -uo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SELF_DIR/check-docs.sh"
[ -f "$GATE" ] || { echo "找不到 check-docs.sh（应与 selftest.sh 同目录）" >&2; exit 1; }

D=$(date +%Y-%m-%d)
Y=$(date -d yesterday +%Y-%m-%d 2>/dev/null || echo "2000-01-01")
TMP=$(mktemp -d) || exit 1
cleanup() { chmod -R u+rwX "$TMP" 2>/dev/null; rm -rf "$TMP" 2>/dev/null; }
trap cleanup EXIT
# 根路径要能被闸门的 _norm 认出来：Git Bash 的 /tmp/… 会被当成盘符路径算错，
# 所以取 Windows 形式（pwd -W）；非 Windows 上退回 POSIX 路径。
ROOT=$( (cd "$TMP" && pwd -W) 2>/dev/null || (cd "$TMP" && pwd) )

# ---------- 夹具：默认三档全合规 ----------
mk_task() {
  local n="$1"
  mkdir -p "$TMP/$n"
  cat > "$TMP/$n/README.md" <<EOF
# $n

> 最近更新：$D

## 一句话说明
夹具。

## 快速开始
见 README。

## 使用说明
见 README。

## 产物与目录
| 文件 | 用途 |
|---|---|
| [夹具说明.md](夹具说明.md) | 说明 |

## 限制与注意事项
- 夹具，跑完即删。
EOF
  cat > "$TMP/$n/DESIGN.md" <<EOF
# $n · 方案设计

> 最近更新：$D

## 问题与目标
验闸门。

## 设计思路
| 决策 | 理由 | 代价 |
|---|---|---|
| 造夹具 | 验规 | 多一份文件 |

## 架构与关键接缝
略。

## 已定语义与边界
- 定了。
EOF
  cat > "$TMP/$n/CONTEXT.md" <<EOF
# $n

> 最近更新：$D

## 背景与目标
验闸门。

## 当前状态
就绪。

## 计划 / 待办
- [x] 造夹具。

## 关键约束与注意事项
无。

## 变更记录
- $D 造夹具。

## 给下一个 agent 的追加区
删掉。
EOF
  printf '# 夹具说明\n\n见 [README.md](README.md)。\n' > "$TMP/$n/夹具说明.md"
  printf '真实文件\n' > "$TMP/$n/在的.md"
}

# 覆盖成"只有两节"的 DESIGN（测 [构]）
two_sec() { cat > "$TMP/$1/DESIGN.md" <<EOF
# $1 · 方案设计

> 最近更新：$D

## 问题与目标
x

## 设计思路
| 决策 | 理由 | 代价 |
|---|---|---|
| a | b | c |
EOF
}
# 覆盖 DESIGN.md 的标题与日期（测 [题]/[占]/[期]）
# $1=目录 $2=H1 $3=日期
redesign() {
  local n="$1" h1="$2" dt="$3"
  cat > "$TMP/$n/DESIGN.md" <<EOF
$h1

> 最近更新：$dt

## 问题与目标
x

## 设计思路
| 决策 | 理由 | 代价 |
|---|---|---|
| a | b | c |

## 架构与关键接缝
x

## 已定语义与边界
- x
EOF
}

# ---------- 建夹具（这一段不许有断言）----------
mk_task base                                     # 基线：应全绿
mk_task nodesig; rm "$TMP/nodesig/DESIGN.md"     # 三档缺 DESIGN
mk_task altok; rm "$TMP/altok/DESIGN.md"
printf '# 架构设计\n\n总-分。\n' > "$TMP/altok/架构设计.md"           # 设计由交付文档承担
mk_task altbad; rm "$TMP/altbad/DESIGN.md"
printf '# 评审\n\n意见书。\n' > "$TMP/altbad/他人设计稿评审意见书.md"   # 名单负向对照
mk_task bothsig; printf '# 架构设计\n\n也在。\n' > "$TMP/bothsig/架构设计.md"   # 并存→只查 DESIGN.md
mk_task twosec; two_sec twosec
mk_task emptyd
cat > "$TMP/emptyd/DESIGN.md" <<EOF
# emptyd · 方案设计

> 最近更新：$D

## 问题与目标
x

## 设计思路
| 决策 | 理由 | 代价 |
|---|---|---|
|  |  |  |

## 架构与关键接缝
x

## 已定语义与边界
- x
EOF
mk_task emptyr
printf '# emptyr\n\n> 最近更新：%s\n\n## 一句话说明\nx\n\n## 快速开始\nx\n\n## 使用说明\nx\n\n## 产物与目录\n| 文件 | 用途 | 备注 |\n|---|---|---|\n|  |  |  |\n\n## 限制与注意事项\n- x\n' "$D" > "$TMP/emptyr/README.md"
mk_task staled; redesign staled "# staled · 方案设计" "$Y"
mk_task aliasok; redesign aliasok "# aliasok（中文别名） · 方案设计" "$D"
mk_task badh1; redesign badh1 "# 方案设计" "$D"
mk_task holder; redesign holder "# <任务目录名> · 方案设计" "$D"
mk_task badrel; printf '# 断链\n\n[在的](在的.md)、[没了](没有这个文件.md)\n' > "$TMP/badrel/断链.md"
mk_task badabs; printf '# 断链二\n\n[里面](file:///%s/badabs/根内不存在.md)\n' "$ROOT" > "$TMP/badabs/断链二.md"
mk_task outabs; printf '# 断链三\n\n[外面](file:///C:/Windows/nope-not-there.ini)\n' > "$TMP/outabs/断链三.md"
mk_task inspans; printf '# span\n\n反例是 `[this](Status result)`，双反引号版是 `` [x](url2) ``，围栏本身写作 ```` ``` ````。\n' > "$TMP/inspans/span.md"
mk_task spanthen; printf '# span2\n\n未闭合的反引号 ` 这里不配对，后面的真死链 [缺二](第二个不存在的文件.md) 不许被吞。\n' > "$TMP/spanthen/span2.md"
mk_task infence; printf '# fence\n\n```markdown\n[围栏里](围栏外不存在.md)\n```\n' > "$TMP/infence/fence.md"
# 「设计思路」节里的**两列表**留空格：不判 [空]（那是正常排版）。
# 把 GAP 的 cells==3 放宽成 >=2，这条就会红——它钉的是"只管三列表"这个边界。
mk_task gap2col
# 必须插在「设计思路」节**之内**（紧跟该节最后一行、下一个 ## 之前）——插到文件末尾就落到
# 别的节里，等于没测（第一版就这么假绿过一次，变异测试才戳穿）。
awk '{ if ($0 == "## 架构与关键接缝") print "| 两列表 |  |"; print }'      "$TMP/gap2col/DESIGN.md" > "$TMP/gap2col/.d" && mv "$TMP/gap2col/.d" "$TMP/gap2col/DESIGN.md"

# 三列表只填两格（代价列漏）→ 必须响。和 gap2col 是一对：一个钉"该响"，一个钉"不该响"。
mk_task gaphalf
awk '{ if ($0 == "## 架构与关键接缝") print "| 只填决策 | 有理由 |  |"; print }'      "$TMP/gaphalf/DESIGN.md" > "$TMP/gaphalf/.d" && mv "$TMP/gaphalf/.d" "$TMP/gaphalf/DESIGN.md"

# SKILL.md 是固定名：既不判 [名]，它里面反复点名的 `README.md`/`CONTEXT.md` 也不判裸名违规
# （工作树搬进本目录后，这两条豁免没被钉住过——变异测试戳穿的第二个洞）
mk_task skillcopy
printf '# skillcopy · 规范原文

本文件反复点名 `README.md` 与 `CONTEXT.md`，但 SKILL.md 是固定名。
' > "$TMP/skillcopy/SKILL.md"

# 正文里出现「最近更新：」而顶部 blockquote 没写：只认顶部那一行，[新] 必须响。
# （把 top_date 的行首锚定去掉，这条就静默不响——2026-10-10 修过的假绿灯，必须钉住）
# 先建齐三档，再用没有顶部日期的 README 覆盖它（mk_task 只补缺失文件，不会覆盖）
mk_task nobodydate
printf '# nobodydate

## 一句话说明
夹具。

## 快速开始
x

## 使用说明
x

## 产物与目录
| 文件 | 用途 |
|---|---|
| [在的.md](在的.md) | x |

## 限制与注意事项
- 举例用的引用块（不在顶部）：> 最近更新：2020-01-01
' > "$TMP/nobodydate/README.md"

# 顶部日期填了占位符模板的样子：^> 锚定去掉的话，正文里那句也会被当成"未填"
mk_task holderbody
printf '
正文里有一句 最近更新：
' >> "$TMP/holderbody/CONTEXT.md"

# 副本目录铺了三档就要照任务目录查（"按内容判"的正面）；只放脚本时才是基础设施
mkdir -p "$TMP/multi-agent-task-handoff"
printf '# multi-agent-task-handoff

> 最近更新：%s

## 一句话说明
夹具。

## 快速开始
x

## 使用说明
x

## 产物与目录
| 文件 | 用途 |
|---|---|
| [在的.md](在的.md) | x |

## 限制与注意事项
x
' "$D" > "$TMP/multi-agent-task-handoff/README.md"
# 目录名必须真是那两个名字之一——写成 toolsonly 会被当普通任务目录查（第一版就断言错了这个）
mkdir -p "$TMP/tools"
printf '#!/bin/sh
' > "$TMP/tools/check-docs.sh"

# 两个反引号包住的"格式例子"：它是代码，不许被当成链接去验（曾经有个 unwrap 步骤会把它
# 拽出来验，造出 6 条 url 假阳性；步骤已删，这条钉住它别回来）
mk_task quotecase
printf '格式例子写成 ``[`x.md`](url)`` 这样两个反引号包住的，不该被当链接验。
' >> "$TMP/quotecase/README.md"

mk_task btlink; printf '# 显示名带反引号\n\n[`在的.md`](在的.md) 该过，[`没的.md`](没有这个文件.md) 该报。\n' > "$TMP/btlink/显示名.md"
mk_task rulecopy; printf '# 规则块副本\n\n示例链接 [game.js](packages/client/src/game.js) 与 [归属](file:///D:/nope/归属决策件.md) 都不该被验。\n' > "$TMP/rulecopy/AGENTS.md"
mk_task nolinks
printf '# nolinks\n\n> 最近更新：%s\n\n## 一句话说明\nx\n\n## 快速开始\nx\n\n## 使用说明\nx\n\n## 产物与目录\n| 文件 | 用途 |\n|---|---|\n| a.md | 说明 |\n\n## 限制与注意事项\n- x\n' "$D" > "$TMP/nolinks/README.md"
mk_task barename; printf '# 裸名\n\n正文里反引号提到了 `在的.md`，它在本目录里真实存在。\n' > "$TMP/barename/裸名.md"
mk_task deadarch; mkdir -p "$TMP/deadarch/archive"
printf '# 死档\n\n这里引用了 `archive/旧名.md`，它不存在。\n' > "$TMP/deadarch/死档.md"
mk_task engname; printf '# eng\n\nnotes\n' > "$TMP/engname/design-overview.md"

# 等长反引号 run 配对的钉子：双反引号 span 里套单反引号，后面紧跟一个"举反例"的行内 code。
# 把配对改成"任意长度都算闭合"时，span 会错位、把 [this](Status result) 露出来当死链——
# 2026-10-14 真工作区 DESIGN.md 第 33 行就是这个形状（变异测试证明原来那批夹具钉不住它）。
mk_task spanrun
printf '前文 `` `code` `` 之后举反例 `[this](Status result)`，同段的真死链 [缺的.md](缺的.md) 必须照报。
' >> "$TMP/spanrun/README.md"

# 未闭合反引号：正确实现原样吐出、后面的真死链只报一次；
# 若把 strip_code 里 substr(s,i,j-i) 写成 substr(s,i,j-1)，已输出片段会被重复吐回来，
# 同一条链接就变成报好几次（2026-10-14 实测踩过，靠"次数"才钉得住）。
mk_task spanopen
# 未闭合的那个反引号要**离链接足够远**：bug 版 substr(s,i,j-1) 会从反引号处往后重复吐出
# 约 i 个字符，只有链接落在这段窗口里才会被重复报。前面垫 60 个字符就是为了撑开窗口。
printf '垫场文字%s ` 未闭合，后面这条真死链只该被报一次：[重复.md](重复.md)。
' "$(printf 'x%.0s' $(seq 1 60))" >> "$TMP/spanopen/README.md"

# 「产物与目录」一节一行内容都没有：不该判"没有可点击链接"（节都没填归 [空]/[构] 管，
# 这里钉的是 prodlines>0 那个条件——去掉它，空节也会被报 [链]）。
mkdir -p "$TMP/prodempty"
printf '# prodempty

> 最近更新：'"$D"'

## 一句话说明
夹具。

## 快速开始
见 README。

## 使用说明
见 README。

## 产物与目录

## 限制与注意事项
- 夹具。
' > "$TMP/prodempty/README.md"
printf '# prodempty · 方案设计

> 最近更新：'"$D"'

## 问题与目标
夹具。

## 设计思路
| 决策 | 理由 | 代价 |
|---|---|---|
| a | b | c |

## 架构与关键接缝
略。

## 已定语义与边界
- 定了。
' > "$TMP/prodempty/DESIGN.md"
printf '# prodempty · 会话上下文与进展

> 最近更新：'"$D"'

## 背景与目标
夹具。

## 当前状态
略。

## 计划 / 待办
- [x] 无

## 关键约束与注意事项
略。

## 变更记录
- '"$D"' Qoder：夹具。

## 给下一个 agent 的追加区
（空）
' > "$TMP/prodempty/CONTEXT.md"

# [旧] 只告警不失败：三档同用远古日期 → 只有 [旧] 响，[期]/[新] 都不该响
# 用 08-09 这种零补齐月日：去掉 `10#` 前缀时 bash 会把它当非法八进制直接报错，
# 这条夹具就是钉那个的（2026-10-14 对拍抓出来的坑，平时十月测不出来）。
_DSAVE=$D; D=2000-08-09; mk_task stalewarn; D=$_DSAVE

# ---------- 闸门只跑一次 ----------
N=$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | wc -l)
START=$(date +%s)
GATE_OUT=$(bash "$GATE" --root "$ROOT" 2>&1)
echo "闸门整轮耗时 $(( $(date +%s) - START )) 秒（夹具根 $N 个目录）"

# ---------- 断言 ----------
pass=0; fail=0
declare -a FAILED=()
out_of() {  # $1=目录名 → 该目录那段违规输出
  awk -v t="$1" '
    /^== / { p = ($0 == "== " t); next }
    /^OK:|^不合规见上/ { p = 0 }
    p && NF { print }
  ' <<<"$GATE_OUT"
}
ok() { pass=$((pass+1)); printf '  ok   %-13s %s\n' "$1" "$2"; }
no() { fail=$((fail+1)); FAILED+=("$2"); printf '  FAIL %s\n' "$2"; }
assert_has() { local out; out=$(out_of "$1")
  if grep -qF -- "$2" <<<"$out"; then ok "$1" "响：$2"
  else no "$1" "$1 期望响却没响：$2｜实际：$(tr '\n' ' ' <<<"$out")"; fi; }
assert_hasnt() { local out; out=$(out_of "$1")
  if grep -qF -- "$2" <<<"$out"; then no "$1" "$1 不该响却响了：$2"
  else ok "$1" "不响：$2"; fi; }
assert_count() { local out n; out=$(out_of "$1")
  n=$(grep -cF -- "$2" <<<"$out")
  if [ "$n" = "$3" ]; then ok "$1" "恰好 $3 次：$2"
  else no "$1" "$1 期望 $3 次、实际 $n 次：$2"; fi; }
assert_clean() { local out; out=$(out_of "$1")
  if grep -qE '\[(缺|构|占|空|链|名|期|新|旧|题)\]' <<<"$out"; then
    no "$1" "$1 应全绿却有违规：$(tr '\n' ' ' <<<"$out")"
  else ok "$1" "全绿"; fi; }

echo "== 1. DESIGN 档的存在形式"
assert_clean base
assert_has nodesig "[缺] DESIGN.md 不存在"
assert_has altok "[档] 方案设计已由交付文档「架构设计.md」承担"
assert_hasnt altok "[缺] DESIGN.md 不存在"
assert_has altbad "[缺] DESIGN.md 不存在"   # 拿"设计"两字换不到豁免——整条名单的意义就在这
assert_clean bothsig                        # 并存时只按 DESIGN.md 查，不抱怨

echo "== 2. 章节 / 表格 / 日期 / 标题"
assert_has twosec "«架构与关键接缝»"
assert_has emptyd "[空] DESIGN.md 「设计思路」三列表还是空行"
assert_has emptyr "[空] README.md 表格里还有空行"
assert_has staled "[期] 三档「最近更新」不一致"
assert_hasnt aliasok "[题]"
assert_has badh1 "[题] DESIGN.md 标题"
assert_has holder "[占] DESIGN.md 仍带 <任务目录名> 占位符"

echo "== 3. [链]：可达性、豁免面、行内 code span"
assert_has badrel "相对链接指向不存在的文件: 没有这个文件.md"
assert_hasnt badrel "指向不存在的文件: 在的.md"
assert_has badabs "链接指向不存在的文件: file:///"
assert_hasnt outabs "[链]"                  # 工作区根之外一律跳过：脚本要能发给没有 D: 盘的人
assert_hasnt inspans "Status result"
assert_hasnt inspans "url2"
assert_has spanthen "第二个不存在的文件.md"  # 未闭合反引号不许吞掉后面的真死链
assert_hasnt infence "围栏外不存在.md"
assert_has btlink "相对链接指向不存在的文件: 没有这个文件.md"  # display 带反引号的真链接：剥完 span 剩 ](目标) 照样抽到
assert_hasnt quotecase "url"                                # 代码段里的例子不验
assert_clean gap2col                                  # 两列表留空格不算骨架未填
assert_has nobodydate "[新] README.md 顶部无"               # 顶部日期只认 blockquote 行，正文那句不算
assert_hasnt holderbody "顶部「最近更新」未填"               # ^> 锚定：正文里的"最近更新："不触发 [占]
assert_has multi-agent-task-handoff "[缺] DESIGN.md 不存在"  # 副本目录铺了三档 → 按任务目录查
assert_clean tools                                          # 只有脚本的副本目录（旧名）→ 基础设施，不查
assert_has gaphalf "[空] DESIGN.md「设计思路」表第"        # 三列表半填必须响（钉住 GAP 那整块没被删）
assert_hasnt skillcopy "[名] SKILL.md"                      # 固定名豁免（[名]）
assert_hasnt skillcopy "反引号裸文件名应写成可点击链接"      # 固定名豁免（[链] 裸名分支）
assert_hasnt btlink "指向不存在的文件: 在的.md"
assert_hasnt rulecopy "[链]"                # AGENTS.md 整份不参与可达性：规则正文里全是示例链接
assert_has nolinks "「产物与目录」没有任何可点击链接"
assert_has barename "反引号裸文件名应写成可点击链接"
assert_has deadarch "改名遗留死链"
assert_hasnt spanrun "Status result"          # 反引号必须等长 run 配对，不能"任意长度都算闭合"
assert_has spanrun "相对链接指向不存在的文件: 缺的.md"   # 同一行里的真死链不许被一起吞掉（假绿灯方向）
assert_count spanopen "相对链接指向不存在的文件: 重复.md" 1   # 未闭合反引号不许把同一条链接吐好几遍
assert_hasnt prodempty "「产物与目录」没有任何可点击链接"        # 空节不判 [链]（那是 prodlines>0 的条件）

echo "== 4. [名] 与固定名豁免"
assert_has engname "[名] design-overview.md"
assert_hasnt base "[名] DESIGN.md"

echo "== 5. [旧] 告警与纯 bash 日期算法"
assert_has stalewarn "[旧] README.md 上次更新"
assert_has stalewarn "[旧] CONTEXT.md 上次更新"
assert_hasnt stalewarn "[期]"
assert_hasnt stalewarn "[新]"
# 闸门里的 days_from_civil 与 date -u 对拍：换错一天 [旧] 就偏一天，而这条只在八月、九月
# 这类零补齐月份才会暴露（08/09 是非法八进制那个坑）。
fn_body="$(awk '/^_days_from_civil\(\)/{f=1} f{print} f&&/^\}/{exit}' "$GATE")"
if ! grep -q 'DAYS=' <<<"$fn_body"; then
  no "date" "没从闸门里抽出 _days_from_civil，对拍不成立（别把断言当成跑过了）"
elif ! date -u -d 2000-01-01 +%s >/dev/null 2>&1; then
  ok "date" "本机 date 不支持 -u -d，跳过对拍（闸门自身不依赖它）"
else
  eval "$fn_body"
  bad=0; tot=0
  for ds in 1970-01-01 1969-12-31 2000-02-29 2000-03-01 1900-03-01 2100-01-01             2024-02-29 2026-08-09 2026-09-01 2026-10-14 2026-11-08 2027-03-07; do
    tot=$((tot+1)); _days_from_civil "$ds"; mine=$DAYS
    gnu=$(( $(date -u -d "$ds" +%s) / 86400 ))
    [ "$mine" = "$gnu" ] || { bad=$((bad+1)); printf '  DIFF %s mine=%s gnu=%s
' "$ds" "$mine" "$gnu"; }
  done
  # 断言必须"跑满"才算数：少了组数说明函数中途报错退出（去掉 10# 就是这个死法，
  # 那时它既不 ok 也不 no，静默少一条——比报错更危险）。
  if [ "$tot" -ne 12 ]; then no "date" "对拍只完成 $tot/12 组，闸门日期函数中途报错"
  elif [ "$bad" = 0 ]; then ok "date" "civil→days 与 date -u 对拍一致（$tot 组）"
  else no "date" "日期算法 $bad/$tot 组不一致"; fi
fi

# ---------- 6. 判重锁：双锚 / 整行匹配 / 出处戳 ----------
# 同一把锁有**三套实现**：bootstrap.sh 的 bash grep、install-everywhere.ps1 的 PowerShell -match、
# watchdog.sh 的 [锚] 探针。它写错的方向永远是假绿灯——把散文里提到的 `agents-entry` 当成"这文件
# 已经装过规矩"，于是该追加规矩的工作区一条也没拿到。所以每条断言都往**错的那一侧**造一个文件。
# 这一段只调真实的三个脚本，测试里**不重述正则**（重述就等于再造第四套实现，照样会漂）。
echo "== 6. 判重锁：双锚 / 整行匹配 / 出处戳"
SKILL_DIR="$(cd "$SELF_DIR/.." && pwd)"
LK="$TMP/anchorlock"
mkdir -p "$LK"
B_ENTRY='# 工作区约定（入口）\n\n<!-- agents-entry -->\n\n- 本机政策：产物放本目录。\n'
B_OLD='# 工作区约定（整份）\n\n## 任务双档规范（强制）\n\n条款正文。\n'
B_PROSE='# 工作区约定（只有提及）\n\n这里提到过 `agents-entry` 这串字，但它不是锚行。\n'
B_TAIL='# 工作区约定（锚行带尾巴）\n\n<!-- agents-entry --> 后面被人顺手写了字\n'
lk_mk() { mkdir -p "$LK/$1"; printf '%b' "$2" > "$LK/$1/AGENTS.md"; }
lk_has() { if grep -qF -- "$2" <<<"$3"; then ok "$1" "响：$2"
  else no "$1" "$1 期望「$2」没出现｜实际：$(tr '\n' ' ' <<<"$3")"; fi; }

# ① 看门狗 [锚]：一次调用查四个文件。--no-mark 保证不落 .watchdog/，--copies 指向真源自己
#    （自己比自己必绿），这样退出码就**只由探针决定**——红了不影响退出码等于没查。
lk_mk wd-entry "$B_ENTRY"; lk_mk wd-old "$B_OLD"; lk_mk wd-prose "$B_PROSE"; lk_mk wd-tail "$B_TAIL"
WD_OUT=$(bash "$SELF_DIR/watchdog.sh" --source "$SKILL_DIR" --copies "$SKILL_DIR" --no-gate --no-mark \
  --entries "$LK/wd-entry/AGENTS.md,$LK/wd-old/AGENTS.md,$LK/wd-prose/AGENTS.md,$LK/wd-tail/AGENTS.md" 2>&1)
WD_CODE=$?
if [ "$WD_CODE" = 1 ]; then ok 锁-看门狗红 "两个无锚文件把退出码判成 1"
else no 锁-看门狗红 "探针红了但退出码是 $WD_CODE——红不落到退出码上，看门狗就是假绿灯"; fi
lk_has 锁-狗-入口 "$LK/wd-entry/AGENTS.md 入口模式（新锚命中）" "$WD_OUT"
lk_has 锁-狗-老锚 "$LK/wd-old/AGENTS.md 整份模式（老锚命中）" "$WD_OUT"
lk_has 锁-狗-散文不算锚 "$LK/wd-prose/AGENTS.md 既没有" "$WD_OUT"
lk_has 锁-狗-尾巴不算锚 "$LK/wd-tail/AGENTS.md 既没有" "$WD_OUT"

# ② bootstrap.sh：三种"已装过"的都不许动；两种"看着像锚"的必须照旧追加
lk_mk bs-entry "$B_ENTRY"; SZE=$(wc -c < "$LK/bs-entry/AGENTS.md")
O=$(bash "$SELF_DIR/bootstrap.sh" --root "$LK/bs-entry" 2>&1)
if grep -qF "已是入口模式" <<<"$O" && [ "$(wc -c < "$LK/bs-entry/AGENTS.md")" = "$SZE" ]; then
  ok 锁-入口不动 "命中新锚 → 一句不动（不追加第二份规矩）"
else no 锁-入口不动 "整行锚没被认出来或文件被改｜$(tr '\n' ' ' <<<"$O")"; fi
lk_mk bs-old "$B_OLD"; SZO=$(wc -c < "$LK/bs-old/AGENTS.md")
O=$(bash "$SELF_DIR/bootstrap.sh" --root "$LK/bs-old" 2>&1)
if grep -qF "已含规则块（老锚" <<<"$O" && [ "$(wc -c < "$LK/bs-old/AGENTS.md")" = "$SZO" ]; then
  ok 锁-老锚不动 "拆分前的旧标题「任务双档规范」也算已装（只认新名会追加出第二份）"
else no 锁-老锚不动 "老锚的 [双三] 没兜住旧标题｜$(tr '\n' ' ' <<<"$O")"; fi
lk_mk bs-prose "$B_PROSE"; SZP=$(wc -c < "$LK/bs-prose/AGENTS.md")
O=$(bash "$SELF_DIR/bootstrap.sh" --root "$LK/bs-prose" 2>&1)
if grep -qF "已追加规则块" <<<"$O" && [ "$(wc -c < "$LK/bs-prose/AGENTS.md")" -gt "$SZP" ]; then
  ok 锁-散文不算锚 "行内 code 里的 agents-entry 没被当成锚 → 照常追加"
else no 锁-散文不算锚 "裸子串匹配（去掉 ^...$ 就是这个结果）把提及当成已装，该追加的没追加"; fi
lk_mk bs-tail "$B_TAIL"; SZT=$(wc -c < "$LK/bs-tail/AGENTS.md")
O=$(bash "$SELF_DIR/bootstrap.sh" --root "$LK/bs-tail" 2>&1)
if grep -qF "已追加规则块" <<<"$O" && [ "$(wc -c < "$LK/bs-tail/AGENTS.md")" -gt "$SZT" ]; then
  ok 锁-尾巴不算锚 "锚行后面带字 → 不匹配整行 → 照常追加"
else no 锁-尾巴不算锚 "行尾锚定 \$ 掉了（或整条锚判据松了）"; fi

# ③ 出处戳的**跨实现契约**：bootstrap 写的戳必须能被 watchdog 的解析正则抓到、且是原文当前版本
GOT_SHA=$(grep -oE 'generated-from: references/agents-rule\.md @ [0-9a-f]+' "$LK/bs-prose/AGENTS.md" 2>/dev/null | head -1 | awk '{print $NF}')
WANT_SHA=$(git -C "$SKILL_DIR" log -1 --format=%h -- references/agents-rule.md 2>/dev/null || echo '')
if [ -n "$GOT_SHA" ] && { [ -z "$WANT_SHA" ] || [ "$GOT_SHA" = "$WANT_SHA" ]; }; then
  ok 锁-出处戳可解析 "bootstrap 写的 @ $GOT_SHA 被 watchdog 的正则读到"
else no 锁-出处戳可解析 "戳行缺失或 sha 对不上（读到「$GOT_SHA」，原文 @ ${WANT_SHA:-无}）——[出处] 从此恒为无戳"; fi

# ④ 两个方向的"不动手"：无锚已存在 + --entry 必须拒绝；无 AGENTS.md + --entry 生成的壳必须
#    被同一个 bootstrap 认成入口模式（生成的锚行格式与匹配器不一致 = 下次铺满追加第二份）
lk_mk bs-refuse "$B_PROSE"; SZR=$(wc -c < "$LK/bs-refuse/AGENTS.md")
O=$(bash "$SELF_DIR/bootstrap.sh" --root "$LK/bs-refuse" --entry 2>&1); RC=$?
if [ "$RC" = 1 ] && grep -qF "我不往来源未知的文件里灌规则" <<<"$O" && [ "$(wc -c < "$LK/bs-refuse/AGENTS.md")" = "$SZR" ]; then
  ok 锁-拒绝灌未知文件 "两锚都不认 + --entry：退出码 1、文件一个字节没变"
else no 锁-拒绝灌未知文件 "退出码 $RC、未拒绝或文件被动过——往来源不明的 AGENTS.md 灌规则是不可逆的"; fi
mkdir -p "$LK/bs-none"
O1=$(bash "$SELF_DIR/bootstrap.sh" --root "$LK/bs-none" --entry 2>&1)
SZ1=$(wc -c < "$LK/bs-none/AGENTS.md" 2>/dev/null || echo 0)
O2=$(bash "$SELF_DIR/bootstrap.sh" --root "$LK/bs-none" --entry 2>&1)
if grep -qF "已生成入口模式 AGENTS.md" <<<"$O1" && grep -qF "已是入口模式" <<<"$O2" \
   && [ "$(wc -c < "$LK/bs-none/AGENTS.md" 2>/dev/null || echo -1)" = "$SZ1" ] && [ "$SZ1" -gt 0 ]; then
  ok 锁-生成的壳自匹配 "第一次生成、第二次被自己的锚认出（幂等）"
else no 锁-生成的壳自匹配 "生成的锚行与自己匹配不上｜一次：$(tr '\n' ' ' <<<"$O1")｜二次：$(tr '\n' ' ' <<<"$O2")"; fi

# ⑤ PowerShell 那一套实现：四根一次跑完（入口/老锚/散文提及/全新），断言四条判定各就各位。
#    -AgentHomes 指向临时假家目录（叶名不在 .codex/.claude 映射里 → 不碰任何真实全局文件）。
if command -v powershell.exe >/dev/null 2>&1; then
  PW_LK="$ROOT/anchorlock"
  PW_PS1="$( (cd "$SELF_DIR" && pwd -W) )/install-everywhere.ps1"
  PW_SRC="$( (cd "$SKILL_DIR" && pwd -W) )"
  mkdir -p "$LK/fakehome" "$LK/ps-none"
  lk_mk ps-entry "$B_ENTRY"; lk_mk ps-old "$B_OLD"; lk_mk ps-prose "$B_PROSE"
  SZPP=$(wc -c < "$LK/ps-prose/AGENTS.md")
  PS_OUT=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; & '$PW_PS1' -Source '$PW_SRC' -AgentHomes @('$PW_LK/fakehome') -WorkspaceRoots @('$PW_LK/ps-entry','$PW_LK/ps-old','$PW_LK/ps-prose','$PW_LK/ps-none')" 2>&1)
  PS_BAD=""
  grep -qE 'ps-entry[/\\]AGENTS\.md（新锚 agents-entry（入口模式）' <<<"$PS_OUT" || PS_BAD="${PS_BAD}入口根没跳过; "
  grep -qE 'ps-old[/\\]AGENTS\.md（老锚「任务三档规范」' <<<"$PS_OUT" || PS_BAD="${PS_BAD}老锚根没跳过; "
  grep -qE 'ps-prose[/\\]AGENTS\.md 既无「任务三档规范」标题' <<<"$PS_OUT" || PS_BAD="${PS_BAD}散文根没警告; "
  [ "$(wc -c < "$LK/ps-prose/AGENTS.md")" = "$SZPP" ] || PS_BAD="${PS_BAD}散文根被灌了规则; "
  PS_SHA=$(grep -oE 'generated-from: references/agents-rule\.md @ [0-9a-f]+' "$LK/ps-none/AGENTS.md" 2>/dev/null | head -1 | awk '{print $NF}')
  [ -n "$PS_SHA" ] || PS_BAD="${PS_BAD}全新根没写出可解析的戳; "
  if [ -z "$PS_BAD" ]; then ok 锁-ps1同锁 "PowerShell 侧四根判定全对（含戳 @ $PS_SHA）"
  else no 锁-ps1同锁 "$PS_BAD｜实际报告：$(tr '\n' ' ' <<<"$PS_OUT" | grep -oE '.{0,240}(ps-entry|ps-old|ps-prose|ps-none).{0,120}')"; fi
else
  ok 锁-ps1同锁 "本机没有 powershell.exe，跳过 PowerShell 侧（bash 侧四条仍在）"
fi

# ---------- 7. 全局文件重写：sync-global-rules.ps1 的 -Apply 写盘路径 ----------
# 这条路径 2026-10-16 第一次被真用就写出过 `\r\r\n`（块内硬写 CR + 写回时整段再转一次）。
# DryRun 报告再全也证明不了字节层不出事，所以这里造两份起手不同的假全局文件（BOM+CRLF / 无BOM+LF），
# 真跑 -Apply 后按**字节**验四件事：没有孤立 CR、BOM 与换行风格各自保持、锚点之上的本地内容还在、
# 戳更新到源头当前版本；再跑一次必须报"已同步、不动"（幂等，否则每次迁移都多一个 .bak）。
echo "== 7. 全局文件重写（-Apply 写盘路径）"
if command -v powershell.exe >/dev/null 2>&1; then
  GH="$LK/glob"; mkdir -p "$GH/gh1/.codex" "$GH/gh2/.codex"
  GBODY='# 全局规则（夹具）\n\n### 任务三档规范（强制，来自 skill multi-agent-task-handoff）\n\n条款正文。\n<!-- generated-from: references/agents-rule.md @ deadbee (2026-10-15) -->\n'
  printf '%b' "$GBODY" > "$GH/gh2/.codex/AGENTS.md"                                # 无 BOM + LF
  printf '\357\273\277' > "$GH/gh1/.codex/AGENTS.md" && printf '%b' "$GBODY" | sed 's/$/\r/' >> "$GH/gh1/.codex/AGENTS.md"   # BOM + CRLF
  PW_GH="$ROOT/anchorlock/glob"
  PW_SYNC="$( (cd "$SELF_DIR" && pwd -W) )/sync-global-rules.ps1"
  GH_R1=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; & '$PW_SYNC' -Apply -AgentHomes @('$PW_GH/gh1/.codex','$PW_GH/gh2/.codex')" 2>&1)
  GH_R2=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; & '$PW_SYNC' -Apply -AgentHomes @('$PW_GH/gh1/.codex','$PW_GH/gh2/.codex')" 2>&1)
  GH_BAD=""
  for pair in "gh1 crlf" "gh2 lf"; do
    set -- $pair; d=$1; want=$2; f="$GH/$d/.codex/AGENTS.md"
    crcnt=$(tr -cd '\r' < "$f" | wc -c); lfcnt=$(tr -cd '\n' < "$f" | wc -c)
    if [ "$want" = crlf ]; then
      [ "$crcnt" -gt 0 ] || GH_BAD="${GH_BAD}$d 原本是 CRLF、写出来变成 LF（风格探测失效）; "
      [ "$crcnt" = "$lfcnt" ] || GH_BAD="${GH_BAD}$d 有孤立 CR（CR=$crcnt 行=$lfcnt）; "
      [ "$(od -An -tx1 -N3 "$f" | tr -d ' \n')" = "efbbbf" ] || GH_BAD="${GH_BAD}$d BOM 丢了; "
    else
      [ "$crcnt" = 0 ] || GH_BAD="${GH_BAD}$d 被塞进了 CR（$crcnt 个）; "
      [ "$(od -An -tx1 -N3 "$f" | tr -d ' \n')" != "efbbbf" ] || GH_BAD="${GH_BAD}$d 被加了本来没有的 BOM; "
    fi
    # 本地那行必须还是**第一行**（BOM 与 CR 先剥掉再比——带 BOM 的文件里 `^#` 是匹配不到的）
    first=$(head -1 "$f" | tr -d '\r' | sed 's/^\xef\xbb\xbf//')
    [ "$first" = "# 全局规则（夹具）" ] || GH_BAD="${GH_BAD}$d 锚点之上的本地内容不在了（首行「$first」）; "
    # 戳必须从 deadbee 换成一个真 sha；知道源头 sha 时还要相等（没 .git 的机器上只验前者）
    if ! grep -qE 'generated-from: references/agents-rule\.md @ [0-9a-f]{7}' "$f" || grep -q 'deadbee' "$f"; then
      GH_BAD="${GH_BAD}$d 戳没被换成源头版本; "
    elif [ -n "$WANT_SHA" ] && ! grep -qF "@ $WANT_SHA" "$f"; then
      GH_BAD="${GH_BAD}$d 戳不是源头当前 sha（应 @ $WANT_SHA）; "
    fi
    ls "$GH/$d/.codex/"AGENTS.md.bak-* >/dev/null 2>&1 || GH_BAD="${GH_BAD}$d 写之前没留 .bak; "
  done
  n_skip=$(grep -cF '已同步（戳 @' <<<"$GH_R2")
  [ "$n_skip" = 2 ] || GH_BAD="${GH_BAD}第二次没报两行「已同步、不动」（$n_skip 行）——幂等破了; "
  if [ -z "$GH_BAD" ]; then ok 锁-全局重写 "两种起手各写过一次：无孤立 CR、BOM/风格各自保持、本地内容在、戳更新、二次幂等"
  else no 锁-全局重写 "$GH_BAD｜首跑：$(tr '\n' ' ' <<<"$GH_R1")"; fi
else
  ok 锁-全局重写 "本机没有 powershell.exe，跳过（其余断言不受影响）"
fi

echo
EXPECT_ASSERTS=61   # 加了/删了断言就改这里；条数对不上说明有断言静默消失或整个夹具没跑
if [ $((pass + fail)) -ne "$EXPECT_ASSERTS" ]; then
  printf 'selftest：断言数 %d 与期望 %d 不符——有断言中途消失（夹具报错、循环被打断都算）
' $((pass + fail)) "$EXPECT_ASSERTS"
  exit 1
fi
echo "selftest：$pass 条通过，$fail 条失败（共 $EXPECT_ASSERTS 条）"
if [ "$fail" -ne 0 ]; then printf '失败明细：\n'; for m in "${FAILED[@]}"; do printf '  · %s\n' "$m"; done; exit 1; fi
exit 0
