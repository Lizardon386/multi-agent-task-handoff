#!/usr/bin/env bash
# check-docs.sh — 校验每个任务目录的 README.md / DESIGN.md / CONTEXT.md 三档是否齐全且结构合规
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

# 工作区脚本副本目录 2026-10-14 起改名 multi-agent-task-handoff（旧名 tools）。老工作区里铺的
# 还是 tools/（如 D:/agent_workspace/dsp-hal-eval/tools），只认新名会让它们认不出自己的根、
# 退到硬编码默认值上——与 AGENTS.md 幂等标记 `任务[双三]档规范` 同一手法：两个名字都接受。
if [ -z "$ROOT" ]; then
  case "$(basename "$SELF_DIR")" in tools|multi-agent-task-handoff) ROOT="$(cd "$SELF_DIR/.." && pwd)" ;; esac
fi
ROOT="${ROOT:-D:/agent_workspace}"

# 结尾提示给真实路径，别再教人跑一个已经不在的 tools/init-task.sh。
if [ -d "$ROOT/multi-agent-task-handoff" ]; then COPY_DIR="multi-agent-task-handoff"
elif [ -d "$ROOT/tools" ]; then COPY_DIR="tools"
else COPY_DIR="multi-agent-task-handoff"; fi

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

# 日期差用纯 bash 的 civil→days 换算（Howard Hinnant days_from_civil），不用 `date -d`：
# 后者是 GNU 扩展，BSD/macOS 与纯 PowerShell 下没有，而它撑的只是 `[旧]` 这一条告警——
# 为一个告警把整个闸门绑死在 Git Bash 上不划算。顺带每条文档少一个子进程。
# 算法以 1970-01-01=0 计天，含闰年与世纪年规则；换错一天 [旧] 就会偏一天，所以留了
# 与 GNU date 的逐项对拍验证（见 SKILL.md 的验证段落）。
_days_from_civil() {  # $1=YYYY-MM-DD，结果写进全局 DAYS（不用命令替换，理由同 _norm）
  local y m d era yoe doy doe
  IFS=- read -r y m d <<< "$1"
  # 强制按十进制读：`08`/`09` 在 bash 算术里是非法八进制，不写 10# 的话八月、九月的
  # 日期整条 `[旧]` 判定直接报错（夹具对拍抓出来的，2026-10-14）。
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

# 顶层「其他输出文档」必须中文命名。README/CONTEXT/DESIGN/AGENTS 是规范固定名，_ 前缀是机器
# 产物（如 _ref-*），非 .md 文件（.docx/.pdf 常需与对方系统里的原件同名）一律豁免。
# 只用 LC_ALL=C 判「含非 ASCII 字节」，不依赖 grep -P（收件方的 grep 未必编译了 PCRE）。
check_names() {
  local dir="$1" f b
  for f in "$dir"*.md; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    case "$b" in README.md|CONTEXT.md|DESIGN.md|AGENTS.md) continue ;; esac
    case "$b" in _*) continue ;; esac
    if ! LC_ALL=C grep -q '[^ -~]' <<< "$b"; then
      echo "  [名] $b 顶层输出文档必须用中文命名（三档与 AGENTS、_ 前缀机器产物除外）"
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

# [链] 之二：链接可达性。两类都验：
#   · file:/// 目标——只在指向本工作区内部时校验（脚本会发给别的机器，对方没有 D: 盘）。
#   · 相对链接——按文档自身目录解析。2026-10-14 起因：任务推到 GitHub 后 README 里的
#     file:///D:/... 对别人全是死链，相对链接才是公开仓库的正确写法；既然要鼓励它，
#     就必须同样保证它可达，否则"改闸门"等于"放水"。
check_links() {
  local dir="$1" f dead raw u rootc rel
  rootc="$(canon "$ROOT")"
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    dead="$(
      while IFS= read -r raw; do
        u="${raw%%#*}"
        case "$u" in *%*) u=$(printf '%b' "${u//%/\\x}");; esac   # 只在真需要时解码
        case "$u" in
          file:///*)
            _norm "$u" lc
            case "$NORM" in "$rootc"/*) : ;; *) continue ;; esac
            _norm "$u"
            [ -e "$NORM" ] || printf '  [链] %s 链接指向不存在的文件: %s\n' "$(basename "$f")" "$raw"
            ;;
          http://*|https://*|mailto:*|//*) : ;;
          "") : ;;
          *)
            rel="${f%/*}/${u}"
            [ -e "$rel" ] || printf '  [链] %s 相对链接指向不存在的文件: %s\n' "$(basename "$f")" "$raw"
            ;;
        esac
      # 先剥掉 ``` 围栏内的内容：代码示例里的 C++ lambda `[this](Status result)` 会被
      # `](...)` 误认成链接（2026-10-14 在 dsp-hal-eval/架构设计.md 上假报过一次）。
      # 代价是围栏里的真链接也不验了——产物链接本就不该写在代码块里。
      # 行内 `code` 同法剥掉：本目录 README/DESIGN/CONTEXT 用行内反引号举 `[this](Status result)`
      # 这个反例，闸门把自己写的说明判成了死链（2026-10-14 实跑 4 条假阳性）。
      # 定界符按 CommonMark 的"等长反引号 run 配对"处理，不是简单成对匹配——文档里写
      # ```` ``` ```` 举围栏本身的例子时，成对匹配会把配错位、剩下的反引号让真 span 漏出来
      # （本目录 README 第 70 行实测踩过）。
      done < <(awk '
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
                if (r2 == run) { close_at = k; break }
                k = m
              } else k++
            }
            if (close_at) { out = out " "; i = close_at + run }
            else { out = out substr(s, i, j - i); i = j }   # substr 第三参是长度不是结束下标：写 j-1 会把已输出的片段重复吐回来
          }
          return out
        }
        # [`x.md`](file:///…) 这种"链接显示名带反引号"的写法是合法链接，span 剥离会把它整段吃掉，
        # 所以先把括号里的目标救出来。两个刻意的细节：
        #   · 不用 gsub("\\1") 反向引用——awk 的 gsub 替换串里 $1/\\1 不可靠，这里手工解析。
        #   · 目标一律照救，不放过"看起来像占位符"的目标。散文里裸写 `[文字](url)` 就是一条点不开的
        #     死链，报它是对的；要举格式例子，把例子放进代码段（两个反引号包一个含反引号的例子，
        #     单反引号包不住，span 会配错、留下 ](url) 残形——2026-10-14 本目录的 6 条误报就是这么来的）。
        function unwrap_links(s,   out, m, tp, target) {
          out = ""
          # 字符类里排除 ] 要写 [^]]（] 放最前面）；写成 [^\]] 在 POSIX awk 里是"排除反斜杠"，
          # 整个函数会静默不匹配——第一版就是这样空转的，看起来"通过"其实没执行。
          while (match(s, /`\[[^]]*\]`\([^)]*\)/)) {
            m = substr(s, RSTART, RLENGTH)
            out = out substr(s, 1, RSTART - 1)
            tp = index(m, "]`(")
            target = substr(m, tp + 3, length(m) - tp - 3)
            out = out "[x](" target ")"
            s = substr(s, RSTART + RLENGTH)
          }
          return out s
        }
        BEGIN { inb = 0 }
        /^```/ { inb = !inb; next }
        inb { next }
        {
          if (index($0, "`") == 0 || index($0, "](") == 0) { print; next }   # 没反引号或没链接形状，免扫
          print strip_code(unwrap_links($0))
        }' "$f" 2>/dev/null | grep -oE '\]\([^)]+\)' | sed 's|^](||; s|)$||')
    )"
    if [ -n "$dead" ]; then printf '%s\n' "$dead"; fail=1; fi
  done < <(find "$dir" -name "*.md" -not -name "AGENTS.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
}

# [链] 之三：反引号裸文件名。指向本任务目录内真实存在的 .md/.txt 却没有写成可点链接
# （file:/// 或相对链接）的行——用户点不开，是死链的姊妹问题（2026-10-10 dsp-hal-eval 改名后 README「产物与目录」
# 的 archive 条目就踩了这个）。已在 markdown 链接 display text（`` [`x.md`](...) ``）里的
# 不算违规。fenced code block 里的不算违规。
check_bare_refs() {
  local dir="$1" f rel bn hit
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    bn="$(basename "$f")"
    case "$bn" in README.md|CONTEXT.md|DESIGN.md|AGENTS.md) continue ;; esac
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
          # 改名遗留死链：archive/、inputs/ 前缀的反引号路径已不存在。
          # 其他带路径引用（如 skill 的 references/x.md）指向工作区外，不判——与可达性豁免同理。
          s2 = $0
          while (match(s2, /`(archive|inputs)\/[^`:]*\.(md|txt)`/)) {
            tok = substr(s2, RSTART, RLENGTH)
            before = substr(s2, 1, RSTART-1)
            after = substr(s2, RSTART+RLENGTH)
            inner = substr(tok, 2, length(tok)-2)
            if (before ~ /\[$/ && (after ~ /^\]\(/ || after ~ /^\]/)) {
              # link display text, skip
            } else if (system("[ -e \"" dir "/" inner "\" ]") != 0) {
              printf "%d DEAD:%s\n", NR, inner
            }
            s2 = after
          }
        }
      ' "$f" 2>/dev/null
    )"
    if [ -n "$hit" ]; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        case "$line" in
          *" DEAD:"*) echo "  [链] $(basename "$f") 反引号裸路径指向不存在的文件（改名遗留死链）: \`${line#* DEAD:}\`" ;;
          *) echo "  [链] $(basename "$f") 反引号裸文件名应写成可点击链接（file:/// 或相对链接）: \`$line\`" ;;
        esac
        fail=1
      done <<< "$hit"
    fi
  done < <(find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null)
}

# DESIGN 档可以有两种存在形式：单独立档的 DESIGN.md，或目录里本来就有的方案设计类交付文档
# （dsp-hal-eval 的「架构设计.md」就是后者）。后者存在时不再要求前者——同一件事维持两份真源
# 必然失同步。命中的文件名会打印在 [档] 行里，豁免是可见的，不是静默的。
check_design() {
  local dir="$1" f b hits=""
  if [ -f "$dir/DESIGN.md" ]; then
    check_doc "$dir/DESIGN.md" "$DESIGN_SECTIONS" DESIGN
    return
  fi
  # 命中多个时**全部列出来**：只报第一个是 ls 的顺序决定的，下一个 agent 会看到
  # 「实施方案.md 承担设计」而实际该看的是「架构设计.md」——偶然性要消掉。
  for f in "$dir"*.md; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    case "$b" in README.md|CONTEXT.md|DESIGN.md|AGENTS.md) continue ;; esac
    LC_ALL=C grep -qE "$DESIGN_ALT_RE" <<< "$b" && hits="${hits:+$hits、}$b"
  done
  if [ -n "$hits" ]; then
    echo "  [档] 方案设计已由交付文档「$hits」承担，不再单立 DESIGN.md（不计失败；该档按交付物自己的规范写，顶部日期不参与 [期] 比对）"
    return
  fi
  echo "  [缺] DESIGN.md 不存在，目录里也没有承担方案设计职责的交付文档（如「架构设计.md」「XX实施方案.md」）"
  fail=1
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
  # [题]：H1 必须含任务目录名——下一个 agent 靠标题认自己打开的是哪份文档，2026-10-14 前这条
  # 全靠人工守（实跑发现 8 个目录里 2 个的标题与目录名对不上）。中文别名不违规，但必须写成
  # 「目录名（别名）· 使用说明」；只写别名判不过。占位符没填的情况 [占] 已经报过，不重复判红。
  if ! grep -q "<任务目录名>" "$p"; then
    local h1 dn
    h1="$(grep -m1 '^# ' "$p" 2>/dev/null | sed 's/^# *//')"
    dn="$(basename "$(dirname "$p")")"
    if [ -z "$h1" ]; then
      echo "  [题] $label.md 没有 H1 标题（应为「# $dn · 文档角色」）"; fail=1
    else
      case "$h1" in
        *"$dn"*) : ;;
        *) echo "  [题] $label.md 标题「$h1」不含目录名「$dn」（中文名写成「$dn（别名）」）"; fail=1 ;;
      esac
    fi
  fi
  if grep -qE "^> 最近更新：(YYYY-MM-DD|)$" "$p"; then
    echo "  [占] $label.md 顶部「最近更新」未填"; fail=1
  fi
  # 表格里留全空行 = 骨架没填。原来只判 README，2026-10-14 拆出 DESIGN 后改成三档都判：
  # 只判 DESIGN 会让 README 里空着的「产物与目录」表失去这条覆盖（它原先正是被这条抓住的）。
  if grep -qE "^\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*\|$" "$p"; then
    if [ "$label" = DESIGN ]; then
      echo "  [空] DESIGN.md 「设计思路」三列表还是空行，取舍没写"
    else
      echo "  [空] $label.md 表格里还有空行，骨架没填"
    fi
    fail=1
  fi
  # [空] 第二层（2026-10-14 收紧，待办第 2 条）：设计思路的三列表只要有一个 cell 空就是取舍没写全。
  # 原先只判「整行三格全空」，`| 用 A | |` 这种半填的过去是绿的，而代价列正是最常漏的那一格。
  # 只切「设计思路」这一节、且只管三列表——两列表留空格是正常排版，一并判会误伤；
  # 整行全空由上面那条报，这里跳过，免得同一个缺陷出两行。
  if [ "$label" = DESIGN ]; then
    local gap
    gap="$(awk '
      /^## +.*设计思路/ { f = 1; next }
      /^## /            { f = 0 }
      f && /^\|/ {
        if ($0 ~ /^\|[ :|-]+\|$/) next
        n = split($0, c, "|")
        if (n - 2 != 3) next
        has_empty = 0; all_empty = 1
        for (i = 2; i <= 4; i++) {
          v = c[i]; gsub(/[ \t]/, "", v)
          if (v == "") { has_empty = 1 } else { all_empty = 0 }
        }
        if (has_empty && !all_empty) { print NR; exit }
      }' "$p" 2>/dev/null)"
    if [ -n "$gap" ]; then
      echo "  [空] DESIGN.md「设计思路」表第 $gap 行有留空 cell（决策/理由/代价缺一不可）"; fail=1
    fi
  fi
  if [ "$label" = README ]; then
    local sect
    # 先剥掉 HTML 注释：模板在注释和表头里写了 file:/// 示例，不剥的话空表格也会"命中链接"，
    # 变成假绿灯。
    sect=$(awk '/^## +.*产物与目录/{f=1;next} /^## /{f=0} f' "$p" | sed '/<!--/,/-->/d')
    # 2026-10-14：接受 file:/// 或相对链接。README 会被推到 GitHub 给别人看，那里 file:///D:/...
    # 全是死链；"能不能点开"由上面的 check_links 统一验可达，这里只要求"有可点的链接"。
    if [ -n "$sect" ] && ! printf '%s' "$sect" | grep -qE '\]\([^)]+\)'; then
      echo "  [链] $label.md 「产物与目录」没有任何可点击链接（file:/// 或相对链接都算），全是裸路径"
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
    _days_from_civil "$d"
    local age=$(( TODAY_DAYS - DAYS ))
    [ "$age" -gt "$STALE_DAYS" ] && echo "  [旧] $label.md 上次更新 $d（${age} 天 > ${STALE_DAYS}天）— 确认已归档还是需要补记（仅告警）"
  fi
}

for taskdir in "$ROOT"/*/; do
  [ -d "$taskdir" ] || continue
  name=$(basename "$taskdir")
  # templates/node_modules/.git 永远跳过。脚本副本目录（旧名 tools、新名 multi-agent-task-handoff）
  # 改成**按内容判**：只有脚本时不算任务目录（新装的工作区不该一跑就红），一旦它自己铺了三档
  # 就照任务目录查——2026-10-14 正是这条抓出本目录 20 条指向旧 tools/ 路径的死链。
  case "$name" in templates|node_modules|.git) continue ;; esac
  case "$name" in
    tools|multi-agent-task-handoff) [ -f "$taskdir/README.md" ] || continue ;;
  esac
  [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
  echo "== $name"
  check_doc "$taskdir/README.md"  "$README_SECTIONS"  README
  check_design "$taskdir"
  check_doc "$taskdir/CONTEXT.md" "$CONTEXT_SECTIONS" CONTEXT
  check_names "$taskdir"
  check_links "$taskdir"
  check_bare_refs "$taskdir"
  # 三档顶部「最近更新」必须同日：任何一档改了别的没跟上，说明有一档在说谎
  rd="$(top_date "$taskdir/README.md")"
  dd="$(top_date "$taskdir/DESIGN.md")"
  ctxd="$(top_date "$taskdir/CONTEXT.md")"
  ndiff=$(printf '%s\n' "$rd" "$dd" "$ctxd" | grep -v '^$' | sort -u | wc -l)
  if [ "$ndiff" -gt 1 ]; then
    echo "  [期] 三档「最近更新」不一致：README=$rd DESIGN=$dd CONTEXT=$ctxd — 有一档改动没同步（必须同日）"
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
