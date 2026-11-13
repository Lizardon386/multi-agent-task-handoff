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
if grep -q 'C01.*C14' SKILL.md && grep -q 'C14' assets/CHECK.md; then
  ok "引用: C01–C14 在 CHECK"
else
  bad "引用: SKILL 的 C14 与 CHECK 不一致"
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

# 9. 安装副本（从工作树拷贝，避免 install.sh 只装 HEAD）
if command -v tar >/dev/null 2>&1; then
  mkdir -p "$tmp/src"
  if (cd "$repo" && tar -cf - --exclude=.git --exclude=.skill-version --exclude=.skill-sync-paths .) | (cd "$tmp/src" && tar -xf -) 2>/dev/null; then
    if AGENT_CONFIG="$tmp/icfg" sh "$tmp/src/install.sh" --target "$tmp/skills/multi-agent-task-handoff" --noregister >/dev/null 2>&1; then
      dst=$tmp/skills/multi-agent-task-handoff
      if [ -f "$dst/scripts/selftest.sh" ] && grep -q 'C14' "$dst/assets/CHECK.md" && grep -q 'L110' "$dst/assets/PROBE.md"; then
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

# 汇总
if [ "$fail" -eq 0 ]; then
  printf 'result: PASS（PASS=%s FAIL=0 SKIP=%s）\n' "$pass" "$skip"
  exit 0
fi
printf 'result: FAIL（PASS=%s FAIL=%s SKIP=%s）\n' "$pass" "$fail" "$skip"
exit 1
