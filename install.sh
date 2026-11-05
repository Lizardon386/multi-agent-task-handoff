#!/bin/sh
# 只负责安装：把当前 HEAD 装到“当前宿主”的 skill 目录。
# 运行时诊断/同步见 handoff.sh。宿主靠环境变量识别，识别不出就退出，不猜目录。

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || { echo "错误: 找不到脚本所在目录" >&2; exit 1; }
repo=$script_dir
[ -f "$repo/SKILL.md" ] || { echo "错误: 脚本必须放在仓库根目录（找不到 SKILL.md）" >&2; exit 1; }
[ -f "$repo/scripts/lib.sh" ] || { echo "错误: 缺少 scripts/lib.sh" >&2; exit 1; }
. "$repo/scripts/lib.sh"

dry=0
force=0
hook=1
register=1
host_arg=
target_arg=

usage() {
  cat <<'EOF'
用法: bash install.sh [选项]

只安装，不做诊断或副本同步；诊断/同步用 handoff.sh。

按环境变量识别当前宿主，只给它安装：
  Qoder        QODER_CONFIG_DIR / QODERCN_CONFIG_DIR
  Claude Code  CLAUDECODE / CLAUDE_CONFIG_DIR
  Codex        CODEX_HOME
  OpenCode     OPENCODE / OPENCODE_CONFIG_DIR
  ZCode        ZCODE_CONFIG_DIR / ZCODE_APP_VERSION
  WorkBuddy    CODEBUDDY_HOST=workbuddy* / WORKBUDDY_CONFIG_DIR / CODEBUDDY_CONFIG_DIR

安装目录 = <宿主配置目录>/skills/multi-agent-task-handoff
源可以是 git 克隆，也可以是解压后的非 git 副本（后者装工作树）。

选项:
  --dryrun        只打印将要做什么，不写文件
  --host NAME      qoder | claude | codex | opencode | zcode | workbuddy（识别不出时显式指定）
  --target DIR     直接指定安装目录（与 --host 二选一）
  --force          覆盖没有 .skill-version 的非空目录
  --nohook        不改仓库本地 core.hooksPath
  --noregister    不把目标写进 $AGENT_CONFIG/sync-paths
  -h, --help       显示本表

退出码: 0 成功 / 1 用法或环境错误 / 2 识别不出宿主
EOF
}

die() { printf '%s\n' "错误: $*" >&2; exit 1; }
usage_die() { printf '%s\n' "错误: $*" >&2; usage >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dryrun) dry=1 ;;
    --force) force=1 ;;
    --nohook) hook=0 ;;
    --noregister) register=0 ;;
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

repo_real=$(CDPATH= cd -- "$repo" && pwd -P)

name=$(sed -n 's/^name:[[:space:]]*//p' "$repo/SKILL.md" | head -1 | tr -d '\r')
[ "$name" = "$skill_id" ] || die "SKILL.md 的 name 应为 $skill_id（实际: ${name:-空}）"

resolve_paths_file

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
  target_in=$(to_unix "$target_arg")
elif [ -n "$host_arg" ]; then
  case "$host_arg" in
    qoder|claude|codex|opencode|zcode|workbuddy) ;;
    *) usage_die "--host 只支持 qoder/claude/codex/opencode/zcode/workbuddy" ;;
  esac
  host=$host_arg
  cfg=$(default_cfg "$host") || die "无法确定 $host 的配置目录"
  cfg_src=--host
  target_in=$cfg/skills/$skill_id
elif detect_host; then
  target_in=$cfg/skills/$skill_id
else
  cat >&2 <<'EOF'
识别不出当前宿主。已检查: CODEBUDDY_HOST, WORKBUDDY_CONFIG_DIR, CODEBUDDY_CONFIG_DIR, QODER_CONFIG_DIR, QODERCN_CONFIG_DIR, CLAUDE_CONFIG_DIR, CLAUDECODE, CODEX_HOME, OPENCODE, OPENCODE_CONFIG_DIR, ZCODE_CONFIG_DIR, ZCODE_APP_VERSION。
请用 --host qoder|claude|codex|opencode|zcode|workbuddy 或 --target DIR 指定。
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

is_git=1
if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
  is_git=0
fi
if [ "$is_git" = 1 ]; then
  full_commit=$(git -C "$repo" rev-parse HEAD) || die "读不到 HEAD"
  commit=$(printf '%s' "$full_commit" | cut -c1-7)
  commit_date=$(git -C "$repo" log -1 --format=%cI)
  dirty=$(git -C "$repo" status --porcelain)
else
  full_commit=unknown
  commit=unknown
  commit_date=$(date -Iseconds 2>/dev/null || date)
  dirty=
fi

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
if [ "$is_git" = 1 ]; then
  printf '源:   %s%s\n' "$commit" "${dirty:+（工作树有未提交改动，只装 HEAD）}"
else
  printf '源:   unknown（非 git 副本，装工作树）\n'
fi
printf '动作: %s\n' "$state"

reg=$(to_reg "$target")
if [ "$register" = 1 ]; then
  if [ "$is_git" = 0 ]; then
    echo "登记: 跳过（非 git 源）"
  elif [ -f "$paths_file" ] && grep -Fqx "$reg" "$paths_file"; then
    echo "登记: 已在 sync-paths"
  else
    echo "登记: 会追加到 sync-paths -> $reg"
  fi
else
  echo "登记: 跳过（--noregister）"
fi

if [ "$hook" = 1 ]; then
  if [ "$is_git" = 0 ]; then
    echo "钩子: 跳过（非 git 源）"
  else
    cur=$(git -C "$repo" config --local --get core.hooksPath 2>/dev/null || true)
    if [ -z "$cur" ]; then
      echo "钩子: 会设 core.hooksPath=.githooks"
    elif [ "$cur" = ".githooks" ]; then
      echo "钩子: 已启用"
    else
      echo "钩子: 未覆盖（当前 core.hooksPath=$cur）"
    fi
  fi
else
  echo "钩子: 跳过（--nohook）"
fi

cfg_file=$config_dir/config.toml
if [ -f "$cfg_file" ]; then
  echo "配置: 已存在 $cfg_file（不覆盖）"
else
  echo "配置: 会创建 $cfg_file"
fi
caps_file=$config_dir/AGENT_CAPABILITIES.md
if [ -f "$caps_file" ]; then
  echo "能力表: 已存在 $caps_file（不覆盖）"
else
  echo "能力表: 会创建 $caps_file（模板，待 --probe 填充）"
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
if [ "$is_git" = 1 ]; then
  git -C "$repo" archive HEAD | tar -x -C "$target" || die "解包失败: $target"
else
  ( cd "$repo" && tar -cf - --exclude=.git --exclude=.skill-sync-paths --exclude=.skill-version . ) | tar -xf - -C "$target" || die "复制失败: $target"
fi
[ -f "$target/SKILL.md" ] || die "安装后缺少 SKILL.md: $target"

exp=$(mktemp) || die "mktemp 失败"
act=$(mktemp) || die "mktemp 失败"
trap 'rm -f "$exp" "$act"' EXIT
if [ "$is_git" = 1 ]; then
  git -C "$repo" -c core.quotePath=false ls-tree -r --name-only HEAD | sort > "$exp"
else
  ( cd "$repo" && find . -type f ! -path './.git/*' ! -name '.git' ! -name '.skill-sync-paths' ! -name '.skill-version' | sed 's|^\./||' | sort ) > "$exp"
fi
( cd "$target" && find . -type f ! -name .skill-version | sed 's|^\./||' | sort ) > "$act"
if ! diff -u "$exp" "$act" >/dev/null; then
  diff -u "$exp" "$act" | sed -n '1,20p' >&2
  die "安装校验失败：文件清单与 HEAD 不一致"
fi

printf 'commit=%s\ndate=%s\nsource=%s\n' "$full_commit" "$commit_date" "$repo_real" > "$target/.skill-version" || die "写 .skill-version 失败"

if [ ! -f "$cfg_file" ]; then
  if mkdir -p "$config_dir" 2>/dev/null; then
    if [ -f "$repo/assets/config.toml.tpl" ]; then
      cp "$repo/assets/config.toml.tpl" "$cfg_file" || echo "警告: 写配置失败 $cfg_file" >&2
      echo "配置: 已创建 $cfg_file"
    else
      echo "警告: 缺少 assets/config.toml.tpl" >&2
    fi
  else
    echo "警告: 无法创建配置目录 $config_dir" >&2
  fi
fi

if [ ! -f "$caps_file" ]; then
  if mkdir -p "$config_dir" 2>/dev/null; then
    if [ -f "$repo/assets/AGENT_CAPABILITIES.md.tpl" ]; then
      cp "$repo/assets/AGENT_CAPABILITIES.md.tpl" "$caps_file" || echo "警告: 写能力表失败 $caps_file" >&2
      echo "能力表: 已创建 $caps_file（模板，待 --probe 填充）"
    else
      echo "警告: 缺少 assets/AGENT_CAPABILITIES.md.tpl" >&2
    fi
  else
    echo "警告: 无法创建配置目录 $config_dir" >&2
  fi
fi

if [ "$register" = 1 ] && [ "$is_git" = 1 ]; then
  mkdir -p "$config_dir" 2>/dev/null || true
  [ -f "$paths_file" ] || : > "$paths_file"
  if grep -Fqx "$reg" "$paths_file"; then
    echo "已在 sync-paths: $reg"
  else
    if [ -s "$paths_file" ] && [ "$(tail -c1 "$paths_file" | wc -l)" -eq 0 ]; then
      printf '\n' >> "$paths_file"
    fi
    printf '%s\n' "$reg" >> "$paths_file" || die "写 sync-paths 失败"
    echo "已登记到 sync-paths: $reg"
  fi
fi

if [ "$hook" = 1 ] && [ "$is_git" = 1 ]; then
  cur=$(git -C "$repo" config --local --get core.hooksPath 2>/dev/null || true)
  if [ -z "$cur" ]; then
    git -C "$repo" config --local core.hooksPath .githooks || die "启用钩子失败"
    echo "已启用 core.hooksPath=.githooks"
  elif [ "$cur" = ".githooks" ]; then
    echo "钩子已启用（core.hooksPath=.githooks）"
  else
    echo "提示: core.hooksPath 已是 $cur，未覆盖；可选钩子不生效，--suspend 会显式同步" >&2
  fi
fi

echo "完成: $skill_id $commit -> $target"
