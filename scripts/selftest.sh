#!/bin/sh
# 机械回归自测：不写仓库、不碰真实 $AGENT_CONFIG、不联网。
# 用法：sh scripts/selftest.sh
# 退出码：0 全部通过；1 有 FAIL。SKIP 不算失败，但会列出原因。

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
repo=$(CDPATH= cd -- "$script_dir/.." && pwd -P) || exit 1
[ -f "$repo/SKILL.md" ] || { echo "错误: 找不到仓库根（上层缺少 SKILL.md）" >&2; exit 1; }

pass=0
fail=0
skip=0
ok() { pass=$((pass + 1)); printf 'PASS  %s\n' "$*"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$*"; }
sk() { skip=$((skip + 1)); printf 'SKIP  %s\n' "$*"; }

tmp=$(mktemp -d) || { echo "错误: mktemp 失败" >&2; exit 1; }
trap 'rm -rf "$tmp"' EXIT INT TERM

cd "$repo" || exit 1

# 真实观察文件长度基线（selftest 不得改动它）
real_cfg=$(AGENT_CONFIG= sh -c '. "$1/scripts/lib.sh"; agent_config_dir' sh "$repo" 2>/dev/null || true)
if [ -n "$real_cfg" ] && [ -f "$real_cfg/OBSERVATIONS.md" ]; then
  real_obs_before=$(awk 'END{print NR+0}' "$real_cfg/OBSERVATIONS.md")
else
  real_obs_before=
fi

# 1. 语法
if sh -n scripts/handoff.sh scripts/lib.sh install.sh scripts/selftest.sh 2>/dev/null; then
  ok "语法: handoff / lib / install / selftest"
else
  bad "语法: sh -n 失败"
fi

# 2. 必需文件
for f in SKILL.md assets/CHECK.md assets/PROBE.md assets/AGENTS.md.tpl assets/PROJECT_RULES.md.tpl handoff/CONTEXT.md handoff/PROMPT.md; do
  if [ -f "$f" ]; then ok "文件: $f"; else bad "文件缺失: $f"; fi
done

# 3. 限额
n=$(awk 'END{print NR+0}' SKILL.md)
if [ "$n" -le 150 ]; then ok "SKILL 行数: $n"; else bad "SKILL 行数: $n > 150"; fi
n=$(awk 'END{print NR+0}' handoff/CONTEXT.md)
if [ "$n" -le 100 ]; then ok "CONTEXT 行数: $n"; else bad "CONTEXT 行数: $n > 100"; fi
n=$(awk '/^## 交接记录/{f=1;next}/^## /{f=0}f&&/^- /{n++}END{print n+0}' handoff/CONTEXT.md)
if [ "$n" -le 10 ]; then ok "交接记录: $n"; else bad "交接记录: $n > 10"; fi
n=$(awk '/^## 坑与约束/{f=1;next}/^## /{f=0}f&&/^- /{n++}END{print n+0}' handoff/CONTEXT.md)
if [ "$n" -le 10 ]; then ok "坑与约束: $n"; else bad "坑与约束: $n > 10"; fi
n=$(awk '/^## 下一步/{f=1;next}/^## /{f=0}f&&/^[0-9]+\. /{n++}END{print n+0}' handoff/CONTEXT.md)
if [ "$n" -le 3 ]; then ok "下一步: $n"; else bad "下一步: $n > 3"; fi

# 4. 引用一致性
if grep -q 'C01.*C16' SKILL.md && grep -q 'C16' assets/CHECK.md; then
  ok "引用: C01–C16 在 CHECK"
else
  bad "引用: SKILL 的 C16 与 CHECK 不一致"
fi
if grep -q 'S08' SKILL.md && grep -q 'S08' assets/PROBE.md && grep -q 'L110' SKILL.md && grep -q 'L110' assets/PROBE.md; then
  ok "引用: S08 / L110 在 PROBE"
else
  bad "引用: SKILL 的 S08 / L110 与 PROBE 不一致"
fi
if grep -q -- '--observe' SKILL.md && grep -q -- '--observe' assets/HELP.txt && grep -q -- '--observe' docs/COMMANDS.md; then
  ok "引用: --observe 三处一致"
else
  bad "引用: --observe 在 SKILL / HELP / COMMANDS 不一致"
fi
if grep -q 'plan/' SKILL.md && grep -q 'plan/' README.md && grep -q 'plan/' docs/COMMANDS.md; then
  ok "引用: plan/ 三处一致"
else
  bad "引用: plan/ 在 SKILL / README / COMMANDS 不一致"
fi
if grep -q '计划产出' assets/AGENT_CAPABILITIES.md.tpl; then
  ok "引用: 能力表模板含计划产出"
else
  bad "引用: 能力表模板缺计划产出"
fi

# 5. gear
mkdir -p "$tmp/gcfg"
cp assets/config.toml.tpl "$tmp/gcfg/config.toml"
gear_list=$(sh scripts/handoff.sh --gear list 2>/dev/null || true)
for k in suspend probe post doc observe; do
  if printf '%s\n' "$gear_list" | grep -q "^$k "; then ok "gear: $k"; else bad "gear 缺少: $k"; fi
done
v=$(AGENT_CONFIG="$tmp/gcfg" sh scripts/handoff.sh --gear observe 2>/dev/null || true)
if [ "$v" = on ]; then ok "gear: observe 默认 on"; else bad "gear: observe 默认值异常（$v）"; fi
AGENT_CONFIG="$tmp/gcfg" sh scripts/handoff.sh --gear nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 1 ]; then ok "gear: 非法键退出 1"; else bad "gear: 非法键退出码 $rc"; fi

# 6. --observe 边界（全部用临时 AGENT_CONFIG）
obs_cfg=$tmp/ocfg
mkdir -p "$obs_cfg"
if AGENT_CONFIG="$obs_cfg" sh scripts/handoff.sh --observe L2 "selftest 正常" >/dev/null 2>&1 \
  && grep -q '写入要求' "$obs_cfg/OBSERVATIONS.md" \
  && grep -q 'selftest 正常' "$obs_cfg/OBSERVATIONS.md"; then
  ok "observe: 正常写入"
else
  bad "observe: 正常写入"
fi
printf '[defaults]\nobserve = "off"\n' > "$obs_cfg/config.toml"
if AGENT_CONFIG="$obs_cfg" sh scripts/handoff.sh --observe L2 "应跳过" 2>/dev/null | grep -q '已关闭'; then
  ok "observe: off 跳过"
else
  bad "observe: off 未跳过"
fi
AGENT_CONFIG="$obs_cfg" sh scripts/handoff.sh --observe L9 x >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 1 ]; then ok "observe: 非法等级退出 1"; else bad "observe: 非法等级退出码 $rc"; fi
AGENT_CONFIG="$obs_cfg" sh scripts/handoff.sh --observe L2 >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 1 ]; then ok "observe: 缺事件退出 1"; else bad "observe: 缺事件退出码 $rc"; fi
printf '[defaults]\nobserve = "on"\n' > "$obs_cfg/config.toml"
: > "$obs_cfg/OBSERVATIONS.md"
AGENT_CONFIG="$obs_cfg" sh scripts/handoff.sh --observe L2 "空文件" >/dev/null 2>&1
if grep -q '写入要求' "$obs_cfg/OBSERVATIONS.md"; then ok "observe: 空文件重建表头"; else bad "observe: 空文件未重建表头"; fi
AGENT_CONFIG="$obs_cfg" sh scripts/handoff.sh --observe L2 "$(printf 'A\r\nB\tC')" >/dev/null 2>&1
if tail -1 "$obs_cfg/OBSERVATIONS.md" | grep -q "$(printf '\r')"; then bad "observe: CRLF 未归一化"; else ok "observe: CRLF/tab 归一化"; fi
long=$(awk 'BEGIN{s="";for(i=0;i<250;i++)s=s"x";print s}')
AGENT_CONFIG="$obs_cfg" sh scripts/handoff.sh --observe L2 "$long" >/dev/null 2>&1
if tail -1 "$obs_cfg/OBSERVATIONS.md" | grep -q 'x\{201\}'; then bad "observe: 未截断到 200"; else ok "observe: 截断到 200"; fi

# 7. 只读命令回归
if sh scripts/handoff.sh --printpath >/dev/null 2>&1; then ok "命令: --printpath"; else bad "命令: --printpath"; fi
if sh scripts/handoff.sh --syncall --dryrun >/dev/null 2>&1; then ok "命令: --syncall --dryrun"; else bad "命令: --syncall --dryrun"; fi
sk "命令: --doc --guard 未跑（会写文档，交 --check 人工核对）"

# 8. 模板
if grep -nE 'D:\\|C:\\|Users/TS|Qoder|ZCode|OpenCode|WorkBuddy|Claude' assets/AGENTS.md.tpl assets/PROJECT_RULES.md.tpl >/dev/null 2>&1; then
  bad "模板: AGENTS / PROJECT_RULES 含本机路径或宿主名"
else
  ok "模板: AGENTS / PROJECT_RULES 通用"
fi
if grep -nE 'scripts/handoff\.sh|(^|[^a-z-])--doc|--probe|--post|--gear' \
  assets/README.md.tpl assets/DESIGN.md.tpl assets/COMMANDS.md.tpl assets/CONTEXT.md.tpl assets/PROMPT.md.tpl >/dev/null 2>&1; then
  bad "模板: 项目文档模板含 skill 专属命令"
else
  ok "模板: 项目文档模板通用"
fi
mkdir -p "$tmp/ws"
cp assets/AGENTS.md.tpl "$tmp/ws/AGENTS.md"
cp assets/PROJECT_RULES.md.tpl "$tmp/ws/PROJECT_RULES.md"
n=$(awk 'END{print NR+0}' "$tmp/ws/AGENTS.md")
if [ "$n" -le 10 ] && grep -q '同一问题连续两次' "$tmp/ws/PROJECT_RULES.md"; then
  ok "模板: 播种结果符合预期"
else
  bad "模板: 播种结果不符合预期"
fi
if grep -qx 'plan/' .gitignore 2>/dev/null; then
  ok "配置: plan/ 已忽略"
else
  bad "配置: plan/ 未忽略"
fi

# 9. 安装副本（从工作树拷贝，避免 install.sh 只装 HEAD）
if command -v tar >/dev/null 2>&1; then
  mkdir -p "$tmp/src"
  if (cd "$repo" && tar -cf - --exclude=.git --exclude=.skill-version --exclude=.skill-sync-paths .) | (cd "$tmp/src" && tar -xf -) 2>/dev/null; then
    if AGENT_CONFIG="$tmp/icfg" sh "$tmp/src/install.sh" --target "$tmp/skills/multi-agent-task-handoff" --noregister >/dev/null 2>&1; then
      dst=$tmp/skills/multi-agent-task-handoff
      if [ -f "$dst/scripts/selftest.sh" ] && grep -q 'C16' "$dst/assets/CHECK.md" && grep -q 'L110' "$dst/assets/PROBE.md"; then
        ok "副本: 文件与清单同步"
      else
        bad "副本: 文件或清单不同步"
      fi
      if AGENT_CONFIG="$tmp/icfg" sh "$dst/scripts/handoff.sh" --observe L2 "副本" >/dev/null 2>&1 \
        && grep -q '写入要求' "$tmp/icfg/OBSERVATIONS.md"; then
        ok "副本: --observe 可用"
      else
        bad "副本: --observe 不可用"
      fi
    else
      bad "副本: install.sh 安装失败"
    fi
  else
    bad "副本: 工作树复制失败"
  fi
else
  sk "副本: 无 tar，跳过"
fi

# 10. 真实观察文件未被污染
if [ -n "$real_obs_before" ]; then
  real_obs_after=$(awk 'END{print NR+0}' "$real_cfg/OBSERVATIONS.md")
  if [ "$real_obs_before" = "$real_obs_after" ]; then
    ok "观察文件: 真实文件未变（$real_obs_after 行）"
  else
    bad "观察文件: 真实文件被改动（$real_obs_before -> $real_obs_after）"
  fi
else
  sk "观察文件: 真实文件不存在，跳过"
fi

# 11. 密钥门禁（临时 git 仓 + 本地 bare remote）
if command -v git >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
  sec=$tmp/sec
  mkdir -p "$sec"
  if (cd "$repo" && tar -cf - --exclude=.git --exclude=.skill-version --exclude=.skill-sync-paths .) | (cd "$sec" && tar -xf -) 2>/dev/null \
    && ( cd "$sec" && git init -q -b main && git config user.email test@example.com && git config user.name test && git add -A && git commit -qm init ) >/dev/null 2>&1; then
    git init -q --bare "$tmp/sec-remote.git"
    ( cd "$sec" && git remote add origin "$tmp/sec-remote.git" && git push -qu origin main ) >/dev/null 2>&1
    before=$(git -C "$sec" rev-list --count HEAD 2>/dev/null || echo 0)
    printf '\n- api_key = "sk-abcdefghijklmnopqrstuvwx"\n- password = "supersecret123"\n' >> "$sec/handoff/CONTEXT.md"
    sleep 1
    touch "$sec/handoff/PROMPT.md"
    sec_out=$( cd "$sec" && sh scripts/handoff.sh --save 2>&1 ); sec_rc=$?
    if [ "$sec_rc" -eq 0 ]; then
      bad "密钥门禁: --save 未阻断"
    else
      after=$(git -C "$sec" rev-list --count HEAD 2>/dev/null || echo 0)
      if [ "$before" = "$after" ]; then ok "密钥门禁: --save 阻断且未提交"; else bad "密钥门禁: --save 阻断但发生提交"; fi
      if printf '%s' "$sec_out" | grep -q 'secret:api_key' \
        && printf '%s' "$sec_out" | grep -q 'secret:credential' \
        && ! printf '%s' "$sec_out" | grep -q 'sk-abcdefghijklmnopqrstuvwx' \
        && ! printf '%s' "$sec_out" | grep -q 'supersecret123'; then
        ok "密钥门禁: 只报类型不泄露内容"
      else
        bad "密钥门禁: 输出包含内容或缺少类型"
      fi
    fi
    ( cd "$sec" && git add handoff/CONTEXT.md && git commit -qm secret ) >/dev/null 2>&1
    sleep 1
    touch "$sec/handoff/PROMPT.md"
    rbefore=$(git -C "$tmp/sec-remote.git" rev-list --count HEAD 2>/dev/null || echo 0)
    if ( cd "$sec" && sh scripts/handoff.sh --push >/dev/null 2>&1 ); then
      bad "密钥门禁: --push 未阻断"
    else
      rafter=$(git -C "$tmp/sec-remote.git" rev-list --count HEAD 2>/dev/null || echo 0)
      if [ "$rbefore" = "$rafter" ]; then ok "密钥门禁: --push 阻断且远端未变"; else bad "密钥门禁: --push 阻断但远端变化"; fi
    fi
    nl=$(awk 'END{print NR+0}' "$sec/handoff/CONTEXT.md")
    awk -v n="$nl" 'NR <= n - 2' "$sec/handoff/CONTEXT.md" > "$sec/handoff/CONTEXT.md.tmp" \
      && mv "$sec/handoff/CONTEXT.md.tmp" "$sec/handoff/CONTEXT.md"
    printf '\n- token: <TOKEN>\n' >> "$sec/handoff/CONTEXT.md"
    ( cd "$sec" && git add handoff/CONTEXT.md && git commit -qm placeholder ) >/dev/null 2>&1
    sleep 1
    touch "$sec/handoff/PROMPT.md"
    if ( cd "$sec" && sh scripts/handoff.sh --push --dryrun >/dev/null 2>&1 ); then
      ok "密钥门禁: 占位符不误报"
    else
      bad "密钥门禁: 占位符被误报"
    fi
    sec_reg_fail() {
      printf '%s\n' "$2" > "$sec/handoff/zz-sec-$1.md"
      if ( cd "$sec" && sh scripts/handoff.sh --push --dryrun >/dev/null 2>&1 ); then
        bad "密钥模式: $1 未阻断"
      else
        ok "密钥模式: $1 阻断"
      fi
      rm -f "$sec/handoff/zz-sec-$1.md"
    }
    sec_reg_pass() {
      printf '%s\n' "$2" > "$sec/handoff/zz-sec-$1.md"
      if ( cd "$sec" && sh scripts/handoff.sh --push --dryrun >/dev/null 2>&1 ); then
        ok "密钥抑制: $1 放行"
      else
        bad "密钥抑制: $1 误报"
      fi
      rm -f "$sec/handoff/zz-sec-$1.md"
    }
    sec_reg_fail ghp 'token: ghp_abcdefghijklmnopqrstuvwxyz0123456789'
    sec_reg_fail akia 'aws = AKIAIOSFODNN7EXAMPLE'
    sec_reg_fail privkey '-----BEGIN RSA PRIVATE KEY-----'
    sec_reg_fail access 'access_key = "abcdefgh12345678"'
    sec_reg_pass templ 'token: ${TOKEN}'
    sec_reg_pass redacted 'token: REDACTED_VALUE'
    sec_reg_pass commitref 'token: commit:abc123def456'
  else
    bad "密钥门禁: 临时仓初始化失败"
  fi
else
  sk "密钥门禁: 无 git/tar，跳过"
fi

# 12. 交接状态门禁（安装副本无 .git，push_dir=临时项目）
installed_handoff=$tmp/skills/multi-agent-task-handoff/scripts/handoff.sh
if [ -f "$installed_handoff" ] && command -v git >/dev/null 2>&1; then
  hcfg=$tmp/hscfg
  mkdir -p "$hcfg"
  hs_setup() {
    hp=$tmp/hs-$1
    rm -rf "$hp"
    mkdir -p "$hp/handoff"
    ( cd "$hp" && git init -q -b main && git config user.email test@example.com && git config user.name test ) >/dev/null 2>&1
    printf '# card\n\n## 现在在哪\n- ok\n' > "$hp/handoff/CONTEXT.md"
    printf '# prompt\n' > "$hp/handoff/PROMPT.md"
    ( cd "$hp" && git add -A && git commit -qm init ) >/dev/null 2>&1
  }
  hs_run() { ( cd "$hp" && AGENT_CONFIG="$hcfg" sh "$installed_handoff" "$@" 2>&1 ); }

  hs_setup fresh
  out=$(hs_run --push --dryrun); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'result: OK'; then ok "handoff: 干净卡片 OK"; else bad "handoff: 干净卡片 rc=$rc $out"; fi

  hs_setup nohand
  ( cd "$hp" && rm -rf handoff && git add -A && git commit -qm nohand ) >/dev/null 2>&1
  out=$(hs_run --push --dryrun); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'result: OK' && ! printf '%s' "$out" | grep -q 'FAIL'; then ok "handoff: 无卡片不误报"; else bad "handoff: 无卡片误报 rc=$rc $out"; fi

  hs_setup stale
  sleep 1
  printf '\n- new\n' >> "$hp/handoff/CONTEXT.md"
  out=$(hs_run --push --dryrun); rc=$?
  if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'prompt-stale'; then ok "handoff: PROMPT 旧阻断"; else bad "handoff: PROMPT 旧未阻断 rc=$rc $out"; fi

  hs_setup dirty
  printf '\n- new\n' >> "$hp/handoff/CONTEXT.md"
  sleep 1
  touch "$hp/handoff/PROMPT.md"
  out=$(hs_run --push --dryrun); rc=$?
  if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'context-dirty'; then ok "handoff: CONTEXT 未提交阻断"; else bad "handoff: CONTEXT 未提交未阻断 rc=$rc $out"; fi

  hs_setup limit
  { printf '# card\n\n## 坑与约束\n'; i=1; while [ "$i" -le 11 ]; do printf '%s\n' "- pit $i"; i=$((i+1)); done; i=1; while [ "$i" -le 87 ]; do printf 'line %s\n' "$i"; i=$((i+1)); done; } > "$hp/handoff/CONTEXT.md"
  ( cd "$hp" && git add -A && git commit -qm limit ) >/dev/null 2>&1
  touch "$hp/handoff/PROMPT.md"
  out=$(hs_run --push --dryrun); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'context-lines' && printf '%s' "$out" | grep -q 'context-pits'; then ok "handoff: 限额 WARN"; else bad "handoff: 限额未报 rc=$rc $out"; fi

  hs_setup behind
  if touch -d '2026-01-01 00:00:00' "$hp/handoff/CONTEXT.md" 2>/dev/null \
    && touch -d '2026-01-01 00:01:00' "$hp/handoff/PROMPT.md" 2>/dev/null \
    && ( cd "$hp" && GIT_AUTHOR_DATE='2026-01-01T00:00:00' GIT_COMMITTER_DATE='2026-01-01T00:00:00' git commit -q --amend --no-edit ) >/dev/null 2>&1 \
    && mkdir -p "$hp/docs" && printf 'd\n' > "$hp/docs/d.md" \
    && ( cd "$hp" && git add docs/d.md && GIT_AUTHOR_DATE='2026-01-02T00:00:00' GIT_COMMITTER_DATE='2026-01-02T00:00:00' git commit -qm docs ) >/dev/null 2>&1; then
    out=$(hs_run --push --dryrun); rc=$?
    if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'card-behind-repo'; then ok "handoff: 仓库领先卡片 WARN"; else bad "handoff: 仓库领先未报 rc=$rc $out"; fi
  else
    sk "handoff: behind 需要 touch -d，跳过"
  fi

  hs_setup ignored
  printf 'handoff/\n' > "$hp/.gitignore"
  ( cd "$hp" && git rm -rq --cached handoff && git add .gitignore && git commit -qm ignore ) >/dev/null 2>&1
  printf '\n- new\n' >> "$hp/handoff/CONTEXT.md"
  sleep 1
  touch "$hp/handoff/PROMPT.md"
  out=$(hs_run --push --dryrun); rc=$?
  if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -q 'context-dirty'; then ok "handoff: ignore 跳过 dirty"; else bad "handoff: ignore 误报 rc=$rc $out"; fi

  nongit=$tmp/hs-nongit
  rm -rf "$nongit"
  mkdir -p "$nongit/handoff"
  printf '# card\n' > "$nongit/handoff/CONTEXT.md"
  printf '# prompt\n' > "$nongit/handoff/PROMPT.md"
  out=$( cd "$nongit" && AGENT_CONFIG="$hcfg" sh "$installed_handoff" --push --dryrun 2>&1 ); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '非 git'; then ok "handoff: 非 git dryrun"; else bad "handoff: 非 git dryrun rc=$rc $out"; fi

  hs_setup pushnoh
  ( cd "$hp" && rm -rf handoff && git add -A && git commit -qm nohand ) >/dev/null 2>&1
  git init -q --bare "$tmp/hs-remote-noh.git"
  ( cd "$hp" && git remote add origin "$tmp/hs-remote-noh.git" && git push -qu origin main ) >/dev/null 2>&1
  out=$(hs_run --push); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '已推送'; then ok "handoff: 无卡片 push 不误伤"; else bad "handoff: 无卡片 push rc=$rc $out"; fi

  hs_setup pushstale
  git init -q --bare "$tmp/hs-remote-stale.git"
  ( cd "$hp" && git remote add origin "$tmp/hs-remote-stale.git" && git push -qu origin main ) >/dev/null 2>&1
  before=$(git -C "$tmp/hs-remote-stale.git" rev-list --count HEAD 2>/dev/null || echo 0)
  sleep 1
  printf '\n- new\n' >> "$hp/handoff/CONTEXT.md"
  out=$(hs_run --push); rc=$?
  after=$(git -C "$tmp/hs-remote-stale.git" rev-list --count HEAD 2>/dev/null || echo 0)
  if [ "$rc" -eq 1 ] && [ "$before" = "$after" ]; then ok "handoff: 旧卡 push 阻断"; else bad "handoff: 旧卡 push rc=$rc before=$before after=$after"; fi

  hs_setup pushok
  git init -q --bare "$tmp/hs-remote-ok.git"
  ( cd "$hp" && git remote add origin "$tmp/hs-remote-ok.git" && git push -qu origin main ) >/dev/null 2>&1
  out=$(hs_run --push); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '已推送'; then ok "handoff: 干净卡片 push"; else bad "handoff: 干净卡片 push rc=$rc $out"; fi
else
  sk "handoff 门禁: 无安装副本或 git，跳过"
fi

# 13. 交接状态门禁的边界与回归（仅补测试，不改门禁逻辑）
hskill=$tmp/skills/multi-agent-task-handoff/scripts/handoff.sh
if [ -f "$hskill" ] && command -v git >/dev/null 2>&1; then
  hxcfg=$tmp/hxcfg
  mkdir -p "$hxcfg"
  hx_setup() {
    hx=$tmp/hx-$1
    rm -rf "$hx"
    mkdir -p "$hx/handoff"
    ( cd "$hx" && git init -q -b main && git config user.email test@example.com && git config user.name test ) >/dev/null 2>&1
    printf '# card\n\n## 现在在哪\n- ok\n' > "$hx/handoff/CONTEXT.md"
    printf '# prompt\n' > "$hx/handoff/PROMPT.md"
    printf 'r\n' > "$hx/README.md"
  }
  hx_run() { ( cd "$hx" && AGENT_CONFIG="$hxcfg" sh "$hskill" "$@" 2>&1 ); }

  hx_setup rec11
  { printf '# card\n\n## 交接记录\n'; i=1; while [ "$i" -le 11 ]; do printf '%s\n' "- 2026-01-01 r$i"; i=$((i+1)); done; } > "$hx/handoff/CONTEXT.md"
  sleep 1
  touch "$hx/handoff/PROMPT.md"
  ( cd "$hx" && git add -A && git commit -qm rec11 ) >/dev/null 2>&1
  out=$(hx_run --push --dryrun); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'context-records'; then ok "边界: 11 条记录 WARN"; else bad "边界: 11 条记录 rc=$rc $out"; fi

  hx_nop=$tmp/hx-nop
  rm -rf "$hx_nop"
  mkdir -p "$hx_nop/handoff"
  ( cd "$hx_nop" && git init -q -b main && git config user.email test@example.com && git config user.name test ) >/dev/null 2>&1
  printf '# card\n' > "$hx_nop/handoff/CONTEXT.md"
  printf 'r\n' > "$hx_nop/README.md"
  ( cd "$hx_nop" && git add -A && git commit -qm init ) >/dev/null 2>&1
  git init -q --bare "$tmp/hx-nop-remote.git"
  ( cd "$hx_nop" && git remote add origin "$tmp/hx-nop-remote.git" && git push -qu origin main ) >/dev/null 2>&1
  printf 'more\n' >> "$hx_nop/README.md"
  ( cd "$hx_nop" && git add README.md && git commit -qm more ) >/dev/null 2>&1
  hx=$hx_nop
  out=$(hx_run --push); rc=$?
  nop_after=$(git -C "$tmp/hx-nop-remote.git" rev-list --count refs/heads/main 2>/dev/null || echo 0)
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'prompt-missing' && [ "$nop_after" -eq 2 ]; then
    ok "边界: PROMPT 缺失只 WARN 且 push 成功"
  else
    bad "边界: PROMPT 缺失 rc=$rc remote=$nop_after $out"
  fi

  if command -v tar >/dev/null 2>&1; then
    hx_save=$tmp/hx-save
    rm -rf "$hx_save"
    mkdir -p "$hx_save"
    if (cd "$repo" && tar -cf - --exclude=.git --exclude=.skill-version --exclude=.skill-sync-paths .) | (cd "$hx_save" && tar -xf -) 2>/dev/null \
      && ( cd "$hx_save" && git init -q -b main && git config user.email test@example.com && git config user.name test && git add -A && git commit -qm init ) >/dev/null 2>&1; then
      printf '\n- new\n' >> "$hx_save/handoff/CONTEXT.md"
      before=$(git -C "$hx_save" rev-list --count HEAD 2>/dev/null || echo 0)
      save_out=$( cd "$hx_save" && sh scripts/handoff.sh --save 2>&1 ); save_rc=$?
      after=$(git -C "$hx_save" rev-list --count HEAD 2>/dev/null || echo 0)
      if [ "$save_rc" -eq 1 ] \
        && printf '%s' "$save_out" | grep -q 'prompt-stale' \
        && printf '%s' "$save_out" | grep -q '交接状态未就绪，未暂存、未提交' \
        && [ "$before" = "$after" ]; then
        ok "边界: --save precommit 旧 PROMPT 阻断且未提交"
      else
        bad "边界: --save precommit rc=$save_rc before=$before after=$after $save_out"
      fi
    else
      bad "边界: --save precommit 临时仓初始化失败"
    fi
  else
    sk "边界: --save precommit 无 tar，跳过"
  fi

  hx_setup same
  ( cd "$hx" && git add -A && git commit -qm all ) >/dev/null 2>&1
  out=$(hx_run --push --dryrun); rc=$?
  if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -q 'card-behind-repo'; then
    ok "边界: 同提交代码+CONTEXT 不报 behind"
  else
    bad "边界: 同提交误报 behind rc=$rc $out"
  fi

  hx_setup tol
  if ( cd "$hx" && GIT_AUTHOR_DATE='2026-01-01T00:00:00' GIT_COMMITTER_DATE='2026-01-01T00:00:00' git add -A && GIT_AUTHOR_DATE='2026-01-01T00:00:00' GIT_COMMITTER_DATE='2026-01-01T00:00:00' git commit -qm init ) >/dev/null 2>&1 \
    && touch -d '2026-01-01 00:00:00' "$hx/handoff/CONTEXT.md" 2>/dev/null \
    && touch -d '2026-01-01 00:00:01' "$hx/handoff/PROMPT.md" 2>/dev/null; then
    mkdir -p "$hx/docs"
    printf 'a\n' > "$hx/docs/a.md"
    ( cd "$hx" && git add docs/a.md && GIT_AUTHOR_DATE='2026-01-01T00:00:30' GIT_COMMITTER_DATE='2026-01-01T00:00:30' git commit -qm a ) >/dev/null 2>&1
    out=$(hx_run --push --dryrun); rc=$?
    if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -q 'card-behind-repo'; then
      ok "边界: 60s 容差内不报 behind"
    else
      bad "边界: 60s 容差内误报 rc=$rc $out"
    fi
    printf 'b\n' > "$hx/docs/b.md"
    ( cd "$hx" && git add docs/b.md && GIT_AUTHOR_DATE='2026-01-01T00:02:00' GIT_COMMITTER_DATE='2026-01-01T00:02:00' git commit -qm b ) >/dev/null 2>&1
    out=$(hx_run --push --dryrun); rc=$?
    if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'card-behind-repo'; then
      ok "边界: 超过 60s 报 behind"
    else
      bad "边界: 超过 60s 未报 rc=$rc $out"
    fi
  else
    sk "边界: 60s 容差需要 touch -d / 固定提交时间，跳过"
  fi

  hx_setup b100
  { printf '# card\n\n## 交接记录\n'; i=1; while [ "$i" -le 10 ]; do printf '%s\n' "- 2026-01-01 r$i"; i=$((i+1)); done; printf '\n## 坑与约束\n'; i=1; while [ "$i" -le 10 ]; do printf '%s\n' "- p$i"; i=$((i+1)); done; i=1; while [ "$i" -le 75 ]; do printf 'line %s\n' "$i"; i=$((i+1)); done; } > "$hx/handoff/CONTEXT.md"
  sleep 1
  touch "$hx/handoff/PROMPT.md"
  ( cd "$hx" && git add -A && git commit -qm b100 ) >/dev/null 2>&1
  out=$(hx_run --push --dryrun); rc=$?
  if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -qE 'context-lines|context-records|context-pits'; then
    ok "边界: 100 行/10 记录/10 坑不报限额"
  else
    bad "边界: 100/10/10 误报 rc=$rc $out"
  fi
else
  sk "边界: 无安装副本或 git，跳过"
fi

# 汇总
if [ "$fail" -eq 0 ]; then
  printf 'result: PASS（PASS=%s FAIL=0 SKIP=%s）\n' "$pass" "$skip"
  exit 0
fi
printf 'result: FAIL（PASS=%s FAIL=%s SKIP=%s）\n' "$pass" "$fail" "$skip"
exit 1
