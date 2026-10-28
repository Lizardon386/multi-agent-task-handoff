#!/bin/sh
# 把当前 HEAD 安装到“当前宿主”的 skill 目录；只装一个目标。
# 宿主靠环境变量识别：Qoder / Claude Code / Codex。识别不出就退出，不猜目录。

set -u

skill_id=multi-agent-task-handoff

dry=0
force=0
hook=1
register=1
host_arg=
target_arg=

usage() {
  cat <<'EOF'
用法: bash install.sh [选项]

按环境变量识别当前宿主，只给它安装：
  Qoder        QODER_CONFIG_DIR / QODERCN_CONFIG_DIR
  Claude Code  CLAUDECODE / CLAUDE_CONFIG_DIR
  Codex        CODEX_HOME

安装目录 = <宿主配置目录>/skills/multi-agent-task-handoff

选项:
  --dry-run        只打印将要做什么，不写文件
  --host NAME      qoder | claude | codex（识别不出时显式指定）
  --target DIR     直接指定安装目录（与 --host 二选一）
  --force          覆盖没有 .skill-version 的非空目录
  --no-hook        不改仓库本地 core.hooksPath
  --no-register    不把目标写进 .skill-sync-paths
  -h, --help       显示本表

退出码: 0 成功 / 1 用法或环境错误 / 2 识别不出宿主
EOF
}

die() { printf '%s\n' "错误: $*" >&2; exit 1; }
usage_die() { printf '%s\n' "错误: $*" >&2; usage >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry=1 ;;
    --force) force=1 ;;
    --no-hook) hook=0 ;;
    --no-register) register=0 ;;
    --host) [ $# -ge 2 ] || usage_die "--host 需要一个值"; host_arg=$2; shift ;;
    --host=*) host_arg=${1#*=} ;;
    --target) [ $# -ge 2 ] || usage_die "--target 需要一个值"; target_arg=$2; shift ;;
    --target=*) target_arg=${1#*=} ;;
    -h|--help) usage; exit 0 ;;
    *) usage_die "未知参数 $1" ;;
  esac
  shift
done

if [ -n "$target_arg" ] && [ -n "$host_arg" ]; then
  usage_die "--host 与 --target 只能用一个"
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || die "找不到脚本所在目录"
repo=$script_dir
[ -f "$repo/SKILL.md" ] || die "脚本必须放在仓库根目录（找不到 SKILL.md）"
repo_real=$(CDPATH= cd -- "$repo" && pwd -P)

name=$(sed -n 's/^name:[[:space:]]*//p' "$repo/SKILL.md" | head -1 | tr -d '\r')
[ "$name" = "$skill_id" ] || die "SKILL.md 的 name 应为 $skill_id（实际: ${name:-空}）"

to_unix() {
  case "$1" in
    [A-Za-z]:[\\/]*)
      if command -v cygpath >/dev/null 2>&1; then
        cygpath -u "$1"
      else
        d=$(printf '%s' "$1" | cut -c1 | tr 'A-Z' 'a-z')
        r=$(printf '%s' "$1" | cut -c3- | sed 's|\\|/|g')
        printf '/%s%s\n' "$d" "$r"
      fi ;;
    *) printf '%s\n' "$1" ;;
  esac
}

to_reg() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1" 2>/dev/null || printf '%s\n' "$1"
  else
    printf '%s\n' "$1"
  fi
}

default_cfg() {
  case "$1" in
    qoder)
      if [ -n "${QODER_CONFIG_DIR:-}" ]; then printf '%s\n' "$QODER_CONFIG_DIR"
      elif [ -n "${QODERCN_CONFIG_DIR:-}" ]; then printf '%s\n' "$QODERCN_CONFIG_DIR"
      elif [ -d "$HOME/.qoder-cn" ]; then printf '%s\n' "$HOME/.qoder-cn"
      elif [ -d "$HOME/.qoder" ]; then printf '%s\n' "$HOME/.qoder"
      else printf '%s\n' "$HOME/.qoder-cn"; fi ;;
    claude)
      if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then printf '%s\n' "$CLAUDE_CONFIG_DIR"; else printf '%s\n' "$HOME/.claude"; fi ;;
    codex)
      if [ -n "${CODEX_HOME:-}" ]; then printf '%s\n' "$CODEX_HOME"; else printf '%s\n' "$HOME/.codex"; fi ;;
    *) return 1 ;;
  esac
}

detect_host() {
  if [ -n "${QODER_CONFIG_DIR:-}" ]; then
    host=qoder; cfg=$QODER_CONFIG_DIR; cfg_src=QODER_CONFIG_DIR; return 0
  fi
  if [ -n "${QODERCN_CONFIG_DIR:-}" ]; then
    host=qoder; cfg=$QODERCN_CONFIG_DIR; cfg_src=QODERCN_CONFIG_DIR; return 0
  fi
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    host=claude; cfg=$CLAUDE_CONFIG_DIR; cfg_src=CLAUDE_CONFIG_DIR; return 0
  fi
  if [ -n "${CLAUDECODE:-}" ]; then
    host=claude; cfg=$HOME/.claude; cfg_src=CLAUDECODE; return 0
  fi
  if [ -n "${CODEX_HOME:-}" ]; then
    host=codex; cfg=$CODEX_HOME; cfg_src=CODEX_HOME; return 0
  fi
  return 1
}

target_abs() {
  d=$(dirname -- "$1")
  b=$(basename -- "$1")
  case "$d" in
    /*) ;;
    *) d=$PWD/$d ;;
  esac
  if [ -d "$d" ]; then
    d=$(CDPATH= cd -- "$d" && pwd -P)
  fi
  printf '%s/%s\n' "${d%/}" "$b"
}

if [ -n "$target_arg" ]; then
  host=manual
  target_in=$target_arg
elif [ -n "$host_arg" ]; then
  case "$host_arg" in
    qoder|claude|codex) ;;
    *) usage_die "--host 只支持 qoder/claude/codex" ;;
  esac
  host=$host_arg
  cfg=$(default_cfg "$host") || die "无法确定 $host 的配置目录"
  cfg_src=--host
  target_in=$cfg/skills/$skill_id
elif detect_host; then
  target_in=$cfg/skills/$skill_id
else
  cat >&2 <<'EOF'
识别不出当前宿主。已检查: QODER_CONFIG_DIR, QODERCN_CONFIG_DIR, CLAUDE_CONFIG_DIR, CLAUDECODE, CODEX_HOME。
请用 --host qoder|claude|codex 或 --target DIR 指定。
EOF
  exit 2
fi

if [ "$host" != manual ]; then
  cfg=$(to_unix "$cfg")
  [ -d "$cfg" ] || die "宿主配置目录不存在: $cfg（可用 --target 指定）"
  target_in=$cfg/skills/$skill_id
fi

target=$(target_abs "$target_in")
base=$(basename -- "$target")
[ "$base" = "$skill_id" ] || die "目标目录名必须是 $skill_id: $target"
case "$target" in
  "$repo_real"|"$repo_real"/*) die "拒绝安装到源仓库内: $target" ;;
  /|"$HOME"|"$HOME"/) die "目标不安全: $target" ;;
esac

git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || die "不是 git 仓库: $repo"
full_commit=$(git -C "$repo" rev-parse HEAD) || die "读不到 HEAD"
commit=$(printf '%s' "$full_commit" | cut -c1-7)
commit_date=$(git -C "$repo" log -1 --format=%cI)
dirty=$(git -C "$repo" status --porcelain)

state=安装
if [ -e "$target" ] && [ ! -d "$target" ]; then
  die "目标已存在且不是目录: $target"
fi
if [ -d "$target" ]; then
  if [ -f "$target/.skill-version" ]; then
    state=更新
  elif [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
    state=安装
  else
    [ "$force" = 1 ] || die "非托管目录且非空: $target（确认后加 --force）"
    state=覆盖
  fi
fi

printf '宿主: %s%s\n' "$host" "${cfg_src:+ ($cfg_src)}"
printf '目标: %s\n' "$target"
printf '源:   %s%s\n' "$commit" "${dirty:+（工作树有未提交改动，只装 HEAD）}"
printf '动作: %s\n' "$state"

reg=$(to_reg "$target")
if [ "$register" = 1 ]; then
  if [ -f "$repo/.skill-sync-paths" ] && grep -Fqx "$reg" "$repo/.skill-sync-paths"; then
    echo "登记: 已在 .skill-sync-paths"
  else
    echo "登记: 会追加到 .skill-sync-paths -> $reg"
  fi
else
  echo "登记: 跳过（--no-register）"
fi

if [ "$hook" = 1 ]; then
  cur=$(git -C "$repo" config --local --get core.hooksPath 2>/dev/null || true)
  if [ -z "$cur" ]; then
    echo "钩子: 会设 core.hooksPath=.githooks"
  elif [ "$cur" = ".githooks" ]; then
    echo "钩子: 已启用"
  else
    echo "钩子: 未覆盖（当前 core.hooksPath=$cur）"
  fi
else
  echo "钩子: 跳过（--no-hook）"
fi

if [ "$dry" = 1 ]; then
  echo "（dry-run，未写文件）"
  exit 0
fi

if [ "$host" != manual ]; then
  mkdir -p "$cfg/skills" || die "无法创建 $cfg/skills"
fi

rm -rf "$target" || die "删除旧目录失败: $target"
mkdir -p "$target" || die "创建目录失败: $target"
git -C "$repo" archive HEAD | tar -x -C "$target" || die "解包失败: $target"
[ -f "$target/SKILL.md" ] || die "安装后缺少 SKILL.md: $target"

exp=$(mktemp) || die "mktemp 失败"
act=$(mktemp) || die "mktemp 失败"
trap 'rm -f "$exp" "$act"' EXIT
git -C "$repo" -c core.quotePath=false ls-tree -r --name-only HEAD | sort > "$exp"
( cd "$target" && find . -type f ! -name .skill-version | sed 's|^\./||' | sort ) > "$act"
if ! diff -u "$exp" "$act" >/dev/null; then
  diff -u "$exp" "$act" | sed -n '1,20p' >&2
  die "安装校验失败：文件清单与 HEAD 不一致"
fi

printf 'commit=%s\ndate=%s\n' "$full_commit" "$commit_date" > "$target/.skill-version" || die "写 .skill-version 失败"

if [ "$register" = 1 ]; then
  reg_file=$repo/.skill-sync-paths
  [ -f "$reg_file" ] || : > "$reg_file"
  if grep -Fqx "$reg" "$reg_file"; then
    echo "已在 .skill-sync-paths: $reg"
  else
    if [ -s "$reg_file" ] && [ "$(tail -c1 "$reg_file" | wc -l)" -eq 0 ]; then
      printf '\n' >> "$reg_file"
    fi
    printf '%s\n' "$reg" >> "$reg_file" || die "写 .skill-sync-paths 失败"
    echo "已登记到 .skill-sync-paths: $reg"
  fi
fi

if [ "$hook" = 1 ]; then
  cur=$(git -C "$repo" config --local --get core.hooksPath 2>/dev/null || true)
  if [ -z "$cur" ]; then
    git -C "$repo" config --local core.hooksPath .githooks || die "启用钩子失败"
    echo "已启用 core.hooksPath=.githooks"
  elif [ "$cur" = ".githooks" ]; then
    echo "钩子已启用（core.hooksPath=.githooks）"
  else
    echo "注意: core.hooksPath 已是 $cur，未覆盖；提交不会自动同步" >&2
  fi
fi

echo "完成: $skill_id $commit -> $target"
