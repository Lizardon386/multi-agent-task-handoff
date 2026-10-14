#!/usr/bin/env bash
# check-docs.sh — 校验每个任务目录的 README.md / DESIGN.md / CONTEXT.md 三档是否齐全且结构合规
# 用法：bash check-docs.sh [--root <工作区根>] [<任务目录名>]
# 退出码：0 全部合规；1 有缺项（agent 收工自查闸门）
#
# 性能是这一版的功能之一，别退化掉。Windows 起一个子进程实测 ≈25ms，收工闸门每天被跑很多次，
# 而"慢的闸门没人跑"是本仓库记过的教训（38 秒那版就是被人绕过去的）。2026-10-14 两轮优化把
# 每个任务目录的进程数从上百次压到 **4 次**：
#   ① 三档结构判定合并成**一次 awk**（原先每份文档 10~15 次 grep）
#   ② 链接提取按目录一次 awk（原先每个 .md 一条三段管道）
#   ③ 反引号裸名按目录一次 awk，存在性一律交给 bash 原生 [ -e ]（原先每个 token 一次 system()）
#   ④ 名字/别名/日期/章节判定全在 bash 里做（原先 grep、basename、sort、wc 满天飞）
# 判定语义与输出文本没动：由 scripts/selftest.sh 的 47 条断言、scripts/muttest.sh 的 18 个变异，
# 以及"真工作区输出与基线逐字节相同"三件事钉住。要改判定，先改夹具。
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

# 工作区脚本副本目录 2026-10-14 起改名 multi-agent-task-handoff（旧名 tools）。老工作区里铺的
# 还是 tools/（如 D:/agent_workspace/dsp-hal-eval/tools），只认新名会让它们认不出自己的根、
# 退到硬编码默认值上——与 AGENTS.md 幂等标记 `任务[双三]档规范` 同一手法：两个名字都接受。
if [ -z "$ROOT" ]; then
  # 三种布局都要认：① 下游扁平副本 <root>/tools/check-docs.sh 或 <root>/multi-agent-task-handoff/…
  # ② skill 仓库/工作副本布局 <root>/multi-agent-task-handoff/scripts/check-docs.sh
  # ③ agent 的技能安装目录 …/skills/multi-agent-task-handoff/scripts/ —— 那**不是**工作区，
  #    误判会把 ~/.qoder-cn\skills 当成工作区根去检查。
  _selfbase="${SELF_DIR##*/}"
  case "$_selfbase" in
    tools|multi-agent-task-handoff) ROOT="$(cd "$SELF_DIR/.." && pwd)" ;;
    scripts)
      case "$SELF_DIR" in */skills/*|*/.codex/*|*/.claude/*) : ;;
        *) _parentbase="${SELF_DIR%/*}"; _parentbase="${_parentbase##*/}"
           case "$_parentbase" in
             tools|multi-agent-task-handoff) ROOT="$(cd "$SELF_DIR/../.." && pwd)" ;;
           esac ;;
      esac ;;
  esac
fi
ROOT="${ROOT:-D:/agent_workspace}"

# 结尾提示给真实路径，别再教人跑一个已经不在的 tools/init-task.sh。
if [ -d "$ROOT/multi-agent-task-handoff" ]; then COPY_DIR="multi-agent-task-handoff"
elif [ -d "$ROOT/tools" ]; then COPY_DIR="tools"
else COPY_DIR="multi-agent-task-handoff"; fi
# 真源工作树用的是仓库布局（脚本在 scripts/ 下），下游副本才是扁平的。
[ -f "$ROOT/$COPY_DIR/scripts/init-task.sh" ] && COPY_DIR="$COPY_DIR/scripts"

STALE_DAYS="${STALE_DAYS:-30}"
# 三档分工：README=使用者说明书，DESIGN=方案设计（为什么这么设计、定死的语义），CONTEXT=agent 交接。
# 2026-10-14 把「设计思路」从 README 拆到 DESIGN：说明书里塞取舍表会把真正的使用步骤埋掉。
README_SECTIONS="一句话说明|快速开始|使用说明|产物与目录|限制与注意事项"
DESIGN_SECTIONS="问题与目标|设计思路|架构与关键接缝|已定语义与边界"
CONTEXT_SECTIONS="背景与目标|当前状态|计划|关键约束与注意事项|变更记录|给下一个"
# DESIGN.md 可以省：目录里已经有承担「方案设计」职责的交付文档（如 架构设计.md、XX实施方案.md）时，
# 再单立一份 DESIGN 就是制造两个真源。2026-10-14 用户定的这条。
# 名单刻意只收**复合名**——单收"设计"或"方案"会让「他人设计稿评审意见书.md」「问题清单.md」
# 这类根本不是设计档的文件蒙混过关，等于静默豁免。命中哪个会打印在 [档] 行里，让人看得见。
DESIGN_ALT_RE="架构设计|方案设计|设计方案|技术设计|设计总览|实施方案|实施架构|设计规范"

fail=0

# ─────────────────────────────────────────────────────────────────────────────
# 一次 awk 扫完一个目录里的三档，输出 LABEL<TAB>KEY<TAB>VALUE 供 bash 判。
# KEY：MISS / PLACEHOLDER / H1 / DATEUNFILLED / EMPTYROW / GAP / NOLINK / EMPTYTODO / TOPDATE
# 每个键都与"逐条 grep 版本"逐字等价，坑都写在注释里。
# ─────────────────────────────────────────────────────────────────────────────
DOC_AWK='
function flush(   i) {
  if (!seen) return
  for (i = 1; i <= n; i++) if (!have[i]) printf "%s\tMISS\t%s\n", lab, want[i]
  if (placeholder)  printf "%s\tPLACEHOLDER\t\n", lab
  printf "%s\tH1\t%s\n", lab, h1
  if (dateunfilled) printf "%s\tDATEUNFILLED\t\n", lab
  if (emptyrow)     printf "%s\tEMPTYROW\t\n", lab
  if (gap != "")    printf "%s\tGAP\t%s\n", lab, gap
  # 原实现是 sect=$(awk 切片 | sed 剥注释)，命令替换会剥掉结尾换行，所以"整节都是空行"
  # 等于空串 = 不判 [链]。这里只数非空行来复现那个语义（prodempty 夹具钉住）。
  if (lab == "README" && prodlines > 0 && !prodlink) printf "%s\tNOLINK\t\n", lab
  if (emptytodo)    printf "%s\tEMPTYTODO\t\n", lab
  printf "%s\tTOPDATE\t%s\n", lab, topdate
}
BEGIN { split(order, labs, " "); seen = 0 }
FNR == 1 {
  flush()
  fi++; lab = labs[fi]; seen = 1
  n = split(lab == "README" ? rs : (lab == "DESIGN" ? ds : cs), want, "|")
  delete have
  placeholder = 0; h1 = ""; h1done = 0; dateunfilled = 0; emptyrow = 0; gap = ""
  inprod = 0; indesign = 0; ic = 0; prodlines = 0; prodlink = 0; emptytodo = 0; topdate = ""
}
{
  line = $0

  # [构] 章节命中：等价于 grep -qE "^## +.*<节名>"
  if (line ~ /^##[ ]/) { for (i = 1; i <= n; i++) if (line ~ ("^## +.*" want[i])) have[i] = 1 }

  # [占] 模板占位符（固定串，任意位置）
  if (index(line, "<任务目录名>") > 0) placeholder = 1

  # [题] 第一行 H1：等价 grep -m1 "^# " 再 sed "s/^# *//"
  if (!h1done && line ~ /^#[ ]/) { h1done = 1; h1 = line; sub(/^#[ ]*/, "", h1) }

  # [占] 顶部日期没填：^> 锚定 + 行尾锚定，两个都不能放开（nobodydate / holderbody 夹具钉住）
  if (line ~ /^> 最近更新：(YYYY-MM-DD|)$/) dateunfilled = 1

  # [空] 三格全空的表格行
  if (line ~ /^\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*\|$/) emptyrow = 1

  # [空] 第二层：DESIGN「设计思路」节的三列表任一格留空（整行全空由上一条报；两列表不判——
  # 那是正常排版，一并判会误伤，gap2col / gaphalf 一对夹具正反钉住这个边界）
  if (lab == "DESIGN") {
    if (line ~ /^## +.*设计思路/) { indesign = 1 }
    else if (line ~ /^##[ ]/) { indesign = 0 }
    else if (indesign && line ~ /^\|/) {
      if (line !~ /^\|[ :|-]+\|/) {                 # 跳过分隔行
        cells = split(line, c, "|") - 2
        if (cells == 3) {
          has_empty = 0; all_empty = 1
          for (i = 2; i <= 4; i++) {
            v = c[i]; gsub(/[ \t]/, "", v)
            if (v == "") { has_empty = 1 } else { all_empty = 0 }
          }
          if (has_empty && !all_empty && gap == "") gap = FNR
        }
      }
    }
  }

  # [链] README「产物与目录」有没有可点链接。先切节、再剥 HTML 注释（模板在注释与表头里写了
  # file:/// 示例，不剥的话空表格也会"命中链接"通过——2026-10-10 修掉的自造假绿灯）。
  # 注释区间照 sed "/<!--/,/-->/d" 的行为：起始行与结束行都删，结束模式只在后续行上找。
  if (lab == "README") {
    if (line ~ /^## +.*产物与目录/) { inprod = 1 }
    else if (line ~ /^##[ ]/) { inprod = 0 }
    else if (inprod) {
      if (!ic && index(line, "<!--") > 0) { ic = 1 }
      else if (ic) { if (index(line, "-->") > 0) ic = 0 }
      else { if (line != "") prodlines++; if (line ~ /\]\([^)]+\)/) prodlink = 1 }
    }
  }

  # [空] CONTEXT 空复选框
  if (lab == "CONTEXT" && line ~ /^- \[ \]$/) emptytodo = 1

  # 顶部日期只认这一行（与 [占] 的锚定一致）。不锚定的话，正文里出现的「最近更新：日期」
  # 会在顶部缺失时被当成顶部日期，[新] 就静默失效——2026-10-10 真踩过，nobodydate 夹具钉住。
  if (topdate == "" && line ~ /^> 最近更新：[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) {
    s = line; sub(/^> 最近更新：/, "", s); topdate = substr(s, 1, 10)
  }
}
END { flush() }'

# 一次 awk 扫完整个目录的所有 .md，输出"每行一个链接目标"，前面带上是第几个文件。
# 等价于原先的 awk(剥围栏/行内 code) | grep -oE '\]\([^)]+\)' | sed 三段管道。
LINKS_AWK='
function strip_code(s,   out, n, i, run, j, k, r2, m, close_at) {
  out = ""; n = length(s); i = 1
  while (i <= n) {
    if (substr(s, i, 1) != "`") { out = out substr(s, i, 1); i++; continue }
    run = 0; j = i
    while (j <= n && substr(s, j, 1) == "`") { run++; j++ }
    close_at = 0; k = j
    while (k <= n) {
      if (substr(s, k, 1) == "`") {
        r2 = 0; m = k
        while (m <= n && substr(s, m, 1) == "`") { r2++; m++ }
        if (r2 == run) { close_at = k; break }      # 等长 run 才算闭合，见下方说明
        k = m
      } else k++
    }
    if (close_at) { out = out " "; i = close_at + run }
    else { out = out substr(s, i, j - i); i = j }   # substr 第三参是长度不是结束下标：写 j-1 会把已输出的片段重复吐回来（spanopen 夹具钉住）
  }
  return out
}
function emit(s,   t) {
  while (match(s, /\]\([^)]+\)/)) {
    t = substr(s, RSTART + 2, RLENGTH - 3)
    print fi "\t" t
    s = substr(s, RSTART + RLENGTH)
  }
}
BEGIN { inb = 0; fi = 0 }
FNR == 1 { fi++ }
/^```/ { inb = !inb; next }
inb { next }
{
  if (index($0, "`") == 0) { emit($0); next }        # 没反引号，直接抽链接
  emit(strip_code($0))
}'
# 注：**没有**"先把 [`x.md`](目标) 的目标救出来"那一步（曾有一版 unwrap_links，已删）。
# 实测两结论：① 对真链接它是多余的——strip_code 按等长 run 剥掉 display 里的 `x.md` 之后，
#    剩下 `[ ](目标)`，`](目标)` 这个形状照样被抽到，可达性一点没漏（夹具 btlink 钉住）；
# ② 对"两个反引号包住的格式例子" `` ``[`x.md`](url)`` `` 它有害——外层 run 的第二个反引号会被
#    当成 display 的起始，把例子从代码里拽出来当链接验（本目录 6 条 url 假阳性就是这么造的，
#    quotecase 夹具钉住它别回来）。
# 反引号定界必须按**等长 run** 配对，不能简单成对：文档里写 ```` ```` ``` ```` `` 举围栏本身的
# 例子时，成对匹配会配错位、把后面的真 span 漏出来（spanrun / inspans 两条夹具钉住）。

# 反引号裸名候选：awk 只**吐候选**，存在性交给 bash 原生 [ -e ]（原来每个 token 一次 system()）。
# 输出 FILEIDX<TAB>H<TAB>行号<TAB>名字   —— 目录内可能真实存在的裸 .md/.txt
#       FILEIDX<TAB>D<TAB>行号<TAB>archive/…  —— 改名遗留的死链
BARE_AWK='
/^```/ { fence = !fence; next }
fence { next }
{
  s = $0
  while (match(s, /`[^`\/:]*\.(md|txt)`/)) {
    tok = substr(s, RSTART, RLENGTH)
    before = substr(s, 1, RSTART-1)
    after = substr(s, RSTART+RLENGTH)
    inner = substr(tok, 2, length(tok)-2)
    # link display text: [`inner`](...) or [`inner`] —— 已在链接里的不算违规
    if (!(before ~ /\[$/ && (after ~ /^\]\(/ || after ~ /^\]/))) {
      printf "%d\tH\t%d\t%s\n", fi, FNR, inner
    }
    s = after
  }
  # 改名遗留死链：archive/、inputs/ 前缀的反引号路径已不存在。
  # 其他带路径引用（如 skill 的 references/x.md）指向工作区外，不判——与可达性豁免同理。
  s2 = $0
  while (match(s2, /`(archive|inputs)\/[^`:]*\.(md|txt)`/)) {
    tok = substr(s2, RSTART, RLENGTH)
    before = substr(s2, 1, RSTART-1)
    after = substr(s2, RSTART+RLENGTH)
    inner = substr(tok, 2, length(tok)-2)
    if (!(before ~ /\[$/ && (after ~ /^\]\(/ || after ~ /^\]/))) {
      printf "%d\tD\t%d\t%s\n", fi, FNR, inner
    }
    s2 = after
  }
}
FNR == 1 { fi++ }'

# 日期差用纯 bash 的 civil→days 换算（Howard Hinnant days_from_civil），不用 `date -d`：
# 后者是 GNU 扩展，BSD/macOS 与纯 PowerShell 下没有，而它撑的只是 `[旧]` 这一条告警——
# 为一个告警把整个闸门绑死在 Git Bash 上不划算。顺带每条文档少两个子进程。
# 算法以 1970-01-01=0 计天，含闰年与世纪年规则；换错一天 [旧] 就偏一天，所以 selftest.sh 里
# 留了与 date -u 的 12 组对拍（含 08/09 这种零补齐日期——不写 10# 时那是非法八进制）。
_days_from_civil() {  # $1=YYYY-MM-DD，结果写进全局 DAYS（不用命令替换，理由同 _norm）
  local y m d era yoe doy doe
  IFS=- read -r y m d <<< "$1"
  y=$((10#$y)); m=$((10#$m)); d=$((10#$d))
  (( m <= 2 )) && (( y -= 1 ))
  era=$(( (y >= 0 ? y : y - 399) / 400 ))
  yoe=$(( y - era * 400 ))
  doy=$(( (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1 ))
  doe=$(( yoe * 365 + yoe / 4 - yoe / 100 + doy ))
  DAYS=$(( era * 146097 + doe - 719468 ))
}
_days_from_civil "$(date +%Y-%m-%d)"
TODAY_DAYS=$DAYS

# 名字里含非 ASCII 字符（即"用了中文命名"）——bash 原生逐字符判，替掉每文件一次
# LC_ALL=C grep '[^ -~]'。字符类 [\ -~] 就是原来那条可打印 ASCII 区间（空格要转义，
# 否则 [[ ]] 里会被当成词分隔）。
has_nonascii() {
  local s="$1" i
  for (( i = 0; i < ${#s}; i++ )); do
    [[ "${s:i:1}" != [\ -~] ]] && return 0
  done
  return 1
}

# 顶层「其他输出文档」必须中文命名。README/CONTEXT/DESIGN/AGENTS 是规范固定名，_ 前缀是机器
# 产物（如 _ref-*），非 .md 文件（.docx/.pdf 常需与对方系统里的原件同名）一律豁免。
# SKILL.md 同列豁免：它是 skill 加载器强制的文件名（改成中文就加载不到），且内容是规范原文、
# 必然反复点名 README.md/DESIGN.md/CONTEXT.md——2026-10-14 skill 仓库的工作树搬进
# D:\agent_workspace\multi-agent-task-handoff\ 后，它第一次被当成交付文档查，[名] 加 35 条
# 反引号裸名一起冒出来，全是这个原因。与 AGENTS.md 早就拿到的豁免同理，不是新开的口子
# （skillcopy 夹具钉住这两条豁免别掉）。
check_names() {
  local dir="$1" f b
  for f in "$dir"*.md; do
    [ -f "$f" ] || continue
    b="${f##*/}"
    case "$b" in README.md|CONTEXT.md|DESIGN.md|AGENTS.md|SKILL.md) continue ;; esac
    case "$b" in _*) continue ;; esac
    if ! has_nonascii "$b"; then
      echo "  [名] $b 顶层输出文档必须用中文命名（三档与 AGENTS、SKILL、_ 前缀机器产物除外）"
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
# 工作区根的归一形式：每条链接都要和它比前缀，所以全局算一次（原先放在 check_links
# 里，每个目录一次命令替换 + 一个子 shell）。
_norm "$ROOT" lc; ROOTC="$NORM"

# [链] 之二：链接可达性。两类都验：
#   · file:/// 目标——只在指向本工作区内部时校验（脚本会发给别的机器，对方没有 D: 盘）。
#   · 相对链接——按文档自身目录解析。2026-10-14 起因：任务推到 GitHub 后 README 里的
#     file:///D:/... 对别人全是死链，相对链接才是公开仓库的正确写法；既然要鼓励它，
#     就必须同样保证它可达，否则"改闸门"等于"放水"。
check_links() {
  local raw u rel idx
  [ "${#LINK_FILES[@]}" -gt 0 ] || return 0
  while IFS=$'\t' read -r idx raw; do
    [ -n "$idx" ] || continue
    f="${LINK_FILES[$((idx - 1))]}"
    u="${raw%%#*}"
    case "$u" in *%*) u=$(printf '%b' "${u//%/\\x}");; esac   # 只在真需要时解码
    case "$u" in
      file:///*)
        _norm "$u" lc
        case "$NORM" in "$ROOTC"/*) : ;; *) continue ;; esac
        _norm "$u"
        [ -e "$NORM" ] || { echo "  [链] ${f#"$TASKDIR"} 链接指向不存在的文件: $raw"; fail=1; }
        ;;
      http://*|https://*|mailto:*|//*) : ;;
      "") : ;;
      *)
        rel="${f%/*}/${u}"
        [ -e "$rel" ] || { echo "  [链] ${f#"$TASKDIR"} 相对链接指向不存在的文件: $raw"; fail=1; }
        ;;
    esac
  done < <(awk "$LINKS_AWK" "${LINK_FILES[@]}" 2>/dev/null)
}

# [链] 之三：反引号裸文件名。指向本任务目录内真实存在的 .md/.txt 却没有写成可点链接
# （file:/// 或相对链接）的行——用户点不开，是死链的姊妹问题（2026-10-10 dsp-hal-eval 改名后 README「产物与目录」
# 的 archive 条目就踩了这个）。已在 markdown 链接 display text（`` [`x.md`](...) ``）里的
# 不算违规。fenced code block 里的不算违规。
check_bare_refs() {
  local idx kind ln tok f
  [ "${#BARE_FILES[@]}" -gt 0 ] || return 0
  while IFS=$'\t' read -r idx kind ln tok; do
    [ -n "$idx" ] || continue
    f="${BARE_FILES[$((idx - 1))]}"
    case "$kind" in
      H) if [ -e "$TASKDIR$tok" ] || [ -e "$TASKDIR/archive/$tok" ] || [ -e "$TASKDIR/inputs/$tok" ]; then
           echo "  [链] ${f#"$TASKDIR"} 反引号裸文件名应写成可点击链接（file:/// 或相对链接）: \`$ln $tok\`"
           fail=1
         fi ;;
      D) if [ ! -e "$TASKDIR$tok" ]; then
           echo "  [链] ${f#"$TASKDIR"} 反引号裸路径指向不存在的文件（改名遗留死链）: \`${tok}\`"
           fail=1
         fi ;;
    esac
  done < <(awk "$BARE_AWK" "${BARE_FILES[@]}" 2>/dev/null)
}

# 按原顺序打印一份文档的判定结果（事实由 scan_docs 一次性扫好）。
report_doc() {  # $1=label
  local label="$1" miss h1 placeholder dateunfilled emptyrow gap prodnolink emptytodo d dn
  miss="${FACT["$label:MISS"]:-}"
  h1="${FACT["$label:H1"]:-}"
  placeholder="${FACT["$label:PLACEHOLDER"]:-0}"
  dateunfilled="${FACT["$label:DATEUNFILLED"]:-0}"
  emptyrow="${FACT["$label:EMPTYROW"]:-0}"
  gap="${FACT["$label:GAP"]:-}"
  prodnolink="${FACT["$label:NOLINK"]:-0}"
  emptytodo="${FACT["$label:EMPTYTODO"]:-0}"
  d="${FACT["$label:TOPDATE"]:-}"
  dn="${TASKNAME}"

  if [ -n "$miss" ]; then echo "  [构] $label.md 缺章节:$miss"; fail=1; fi
  if [ "$placeholder" = 1 ]; then
    echo "  [占] $label.md 仍带 <任务目录名> 占位符"; fail=1
  fi
  # [题]：H1 必须含任务目录名——下一个 agent 靠标题认自己打开的是哪份文档，2026-10-14 前这条
  # 全靠人工守（实跑发现 8 个目录里 2 个的标题与目录名对不上）。中文别名不违规，但必须写成
  # 「目录名（别名）· 使用说明」；只写别名判不过。占位符没填的情况 [占] 已经报过，不重复判红。
  if [ "$placeholder" = 0 ]; then
    if [ -z "$h1" ]; then
      echo "  [题] $label.md 没有 H1 标题（应为「# $dn · 文档角色」）"; fail=1
    else
      case "$h1" in
        *"$dn"*) : ;;
        *) echo "  [题] $label.md 标题「$h1」不含目录名「$dn」（中文名写成「$dn（别名）」）"; fail=1 ;;
      esac
    fi
  fi
  if [ "$dateunfilled" = 1 ]; then
    echo "  [占] $label.md 顶部「最近更新」未填"; fail=1
  fi
  # 表格里留全空行 = 骨架没填。原来只判 README，2026-10-14 拆出 DESIGN 后改成三档都判：
  # 只判 DESIGN 会让 README 里空着的「产物与目录」表失去这条覆盖（它原先正是被这条抓住的）。
  if [ "$emptyrow" = 1 ]; then
    if [ "$label" = DESIGN ]; then
      echo "  [空] DESIGN.md 「设计思路」三列表还是空行，取舍没写"
    else
      echo "  [空] $label.md 表格里还有空行，骨架没填"
    fi
    fail=1
  fi
  if [ -n "$gap" ]; then
    echo "  [空] DESIGN.md「设计思路」表第 $gap 行有留空 cell（决策/理由/代价缺一不可）"; fail=1
  fi
  if [ "$prodnolink" = 1 ]; then
    echo "  [链] $label.md 「产物与目录」没有任何可点击链接（file:/// 或相对链接都算），全是裸路径"
    fail=1
  fi
  if [ "$emptytodo" = 1 ]; then
    echo "  [空] CONTEXT.md 待办还是空复选框，目标没写"; fail=1
  fi
  if [ -z "$d" ]; then
    echo "  [新] $label.md 顶部无「最近更新：YYYY-MM-DD」"; fail=1
  else
    _days_from_civil "$d"
    local age=$(( TODAY_DAYS - DAYS ))
    [ "$age" -gt "$STALE_DAYS" ] && echo "  [旧] $label.md 上次更新 $d（${age} 天 > ${STALE_DAYS}天）— 确认已归档还是需要补记（仅告警）"
  fi
}

# DESIGN 档可以有两种存在形式：单独立档的 DESIGN.md，或目录里本来就有的方案设计类交付文档
# （dsp-hal-eval 的「架构设计.md」就是后者）。后者存在时不再要求前者——同一件事维持两份真源
# 必然失同步。命中的文件名会打印在 [档] 行里，豁免是可见的，不是静默的。
check_design() {
  local dir="$1" f b hits=""
  if [ -f "$dir/DESIGN.md" ]; then report_doc DESIGN; return; fi
  # 命中多个时**全部列出来**：只报第一个是 ls 的顺序决定的，下一个 agent 会看到
  # 「实施方案.md 承担设计」而实际该看的是「架构设计.md」——偶然性要消掉。
  for f in "$dir"*.md; do
    [ -f "$f" ] || continue
    b="${f##*/}"
    case "$b" in README.md|CONTEXT.md|DESIGN.md|AGENTS.md|SKILL.md) continue ;; esac
    [[ $b =~ $DESIGN_ALT_RE ]] && hits="${hits:+$hits、}$b"
  done
  if [ -n "$hits" ]; then
    echo "  [档] 方案设计已由交付文档「$hits」承担，不再单立 DESIGN.md（不计失败；该档按交付物自己的规范写，顶部日期不参与 [期] 比对）"
    return
  fi
  echo "  [缺] DESIGN.md 不存在，目录里也没有承担方案设计职责的交付文档（如「架构设计.md」「XX实施方案.md」）"
  fail=1
}

for taskdir in "$ROOT"/*/; do
  [ -d "$taskdir" ] || continue
  _tmp="${taskdir%/}"; TASKNAME="${_tmp##*/}"
  # templates/node_modules/.git 永远跳过。脚本副本目录（旧名 tools、新名 multi-agent-task-handoff）
  # 改成**按内容判**：只有脚本时不算任务目录（新装的工作区不该一跑就红），一旦它自己铺了三档
  # 就照任务目录查——2026-10-14 正是这条抓出本目录 20 条指向旧 tools/ 路径的死链
  # （tools / multi-agent-task-handoff 两个夹具各钉住一边）。
  case "$TASKNAME" in templates|node_modules|.git) continue ;; esac
  case "$TASKNAME" in
    tools|multi-agent-task-handoff) [ -f "$taskdir/README.md" ] || continue ;;
  esac
  [ -n "$ONLY" ] && [ "$TASKNAME" != "$ONLY" ] && continue
  echo "== $TASKNAME"
  TASKDIR="$taskdir"

  # ① 三档结构：一次 awk
  declare -A FACT=()
  docs=()
  [ -f "$taskdir/README.md" ]  && docs+=("$taskdir/README.md")
  [ -f "$taskdir/DESIGN.md" ]  && docs+=("$taskdir/DESIGN.md")
  [ -f "$taskdir/CONTEXT.md" ] && docs+=("$taskdir/CONTEXT.md")
  order=""
  for f in "${docs[@]}"; do
    case "${f##*/}" in README.md) order="$order README";; DESIGN.md) order="$order DESIGN";; CONTEXT.md) order="$order CONTEXT";; esac
  done
  if [ "${#docs[@]}" -gt 0 ]; then
    while IFS=$'\t' read -r lab k v; do
      [ -n "$lab" ] || continue
      case "$k" in
        MISS) FACT["$lab:MISS"]="${FACT["$lab:MISS"]:+${FACT["$lab:MISS"]} }«$v»" ;;
        H1|TOPDATE|GAP) FACT["$lab:$k"]="$v" ;;          # 这三个的值本身可能就是空串
        *) FACT["$lab:$k"]=1 ;;                          # 其余是开关，命中即 1
      esac
    done < <(awk -v rs="$README_SECTIONS" -v ds="$DESIGN_SECTIONS" -v cs="$CONTEXT_SECTIONS" \
                  -v order="${order# }" "$DOC_AWK" "${docs[@]}")
  fi
  # 报告顺序与原实现逐字一致：README 缺/判定 → DESIGN（check_design 内部决定 [缺]/[档]/判定）→ CONTEXT 缺/判定
  TOPREADME="${FACT[README:TOPDATE]:-}"; TOPDESIGN="${FACT[DESIGN:TOPDATE]:-}"; TOPCONTEXT="${FACT[CONTEXT:TOPDATE]:-}"
  if [ -f "$taskdir/README.md" ]; then report_doc README; else echo "  [缺] README.md 不存在"; fail=1; fi
  check_design "$taskdir"
  if [ -f "$taskdir/CONTEXT.md" ]; then report_doc CONTEXT; else echo "  [缺] CONTEXT.md 不存在"; fail=1; fi
  unset FACT

  check_names "$taskdir"

  # ② 链接可达性：整个目录一次 awk（AGENTS.md 不参与——规则正文里是语法示例，不是真路径）
  LINK_FILES=()
  while IFS= read -r f; do
    case "$f" in */AGENTS.md) continue ;; esac
    [ -f "$f" ] && LINK_FILES+=("$f")
  done < <(find "$taskdir" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
  check_links "$taskdir"

  # ③ 反引号裸名：顶层 .md 一次 awk
  BARE_FILES=()
  for f in "$taskdir"*.md; do
    [ -f "$f" ] || continue
    case "${f##*/}" in README.md|CONTEXT.md|DESIGN.md|AGENTS.md|SKILL.md) continue ;; esac
    BARE_FILES+=("$f")
  done
  check_bare_refs "$taskdir"

  # ④ 三档顶部「最近更新」必须同日：任何一档改了别的没跟上，说明有一档在说谎。
  # 日期在 ① 里就扫出来了，这里纯 bash 比 distinct（原来是 grep|sort|wc 三个子进程）。
  _seen=""; _nd=0
  for _d2 in "$TOPREADME" "$TOPDESIGN" "$TOPCONTEXT"; do
    [ -z "$_d2" ] && continue
    case " $_seen " in *" $_d2 "*) : ;; *) _seen="$_seen $_d2"; _nd=$((_nd+1)) ;; esac
  done
  if [ "$_nd" -gt 1 ]; then
    echo "  [期] 三档「最近更新」不一致：README=$TOPREADME DESIGN=$TOPDESIGN CONTEXT=$TOPCONTEXT — 有一档改动没同步（必须同日）"
    fail=1
  fi
done

echo
if [ "$fail" = 0 ]; then
  echo "OK: 三档（README / DESIGN / CONTEXT）齐全且结构合规（root: $ROOT）"
else
  echo "不合规见上。规则见 $ROOT/AGENTS.md「任务三档规范」；新任务用 bash \"$ROOT/$COPY_DIR/init-task.sh\" <任务名>"
fi
exit $fail
