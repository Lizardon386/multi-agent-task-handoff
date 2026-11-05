#!/bin/sh
# 运行时操作：路径诊断与安装副本同步。安装见 install.sh。

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || { echo "错误: 找不到脚本所在目录" >&2; exit 1; }
repo=$script_dir
[ -f "$repo/SKILL.md" ] || { echo "错误: 脚本必须放在仓库根目录（找不到 SKILL.md）" >&2; exit 1; }
[ -f "$repo/lib.sh" ] || { echo "错误: 缺少 lib.sh" >&2; exit 1; }
. "$repo/lib.sh"

mode=
dry=0
host_arg=
target_arg=

usage() {
  cat <<'EOF'
用法: bash handoff.sh [选项]

  --printpath [--host NAME | --target DIR]
                   路径诊断：配置 / 工作区 / 能力表 / 源仓库 / 宿主 / 副本清单 / 钩子
  --syncall [--dry-run]
                   按 $AGENT_CONFIG/sync-paths 逐份对齐到当前 HEAD，只补落后的
                   （必须从源仓库运行；--dry-run 只打印）
  -h, --help       显示本表

安装用 install.sh；本脚本一次只做一件事。
EOF
}

die() { printf '%s\n' "错误: $*" >&2; exit 1; }
usage_die() { printf '%s\n' "错误: $*" >&2; usage >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --printpath) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=printpath ;;
    --syncall) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=syncall ;;
    --dry-run) dry=1 ;;
    --host) [ $# -ge 2 ] || usage_die "--host 需要一个值"; host_arg=$2; shift ;;
    --host=*) host_arg=${1#*=} ;;
    --target) [ $# -ge 2 ] || usage_die "--target 需要一个值"; target_arg=$2; shift ;;
    --target=*) target_arg=${1#*=} ;;
    -h|--help) usage; exit 0 ;;
    *) usage_die "未知参数 $1" ;;
  esac
  shift
done

[ -n "$mode" ] || usage_die "需要 --printpath 或 --syncall"
if [ -n "$target_arg" ] && [ -n "$host_arg" ]; then
  usage_die "--host 与 --target 只能用一个"
fi
if [ "$mode" = syncall ] && { [ -n "$target_arg" ] || [ -n "$host_arg" ]; }; then
  usage_die "--syncall 不能与 --host / --target 一起用"
fi
if [ "$mode" = printpath ] && [ "$dry" = 1 ]; then
  usage_die "--dry-run 只能跟 --syncall"
fi
if [ -n "$host_arg" ]; then
  case "$host_arg" in
    qoder|claude|codex|opencode|zcode|workbuddy) ;;
    *) usage_die "--host 只支持 qoder/claude/codex/opencode/zcode/workbuddy" ;;
  esac
fi

resolve_paths_file

if [ "$mode" = syncall ]; then
  [ -f "$paths_file" ] || die "找不到 $paths_file（先跑一次 install.sh 生成）"
  # 必须从源仓库跑：安装副本没有 HEAD，强行同步会把所有副本降级成 unknown。
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 \
    || die "--syncall 必须从源仓库运行（当前是安装副本，没有 HEAD）"
  # 一次 git 调用同时拿到 commit；失败才退回 unknown（少一次进程 ≈ 0.7 秒）
  head_commit=$(git -C "$repo" rev-parse HEAD 2>/dev/null) || head_commit=unknown
  printf '对齐目标: %s\n' "$head_commit"
  total=0
  bad=0
  while IFS= read -r line <&3; do
    case "$line" in ''|'#'*) continue ;; esac
    # 去尾部空白、取父目录、读 commit，全用 shell 内建：
    # Git Bash 在 Windows 上每启动一个 sed/dirname 约 0.9 秒，四份累积能把钩子拖到 8 秒以上。
    dest=$line
    while :; do case "$dest" in *' ') dest=${dest% } ;; *) break ;; esac; done
    parent=${dest%/*}
    [ -n "$parent" ] && [ -d "$parent" ] || { printf '跳过（父目录不存在）: %s\n' "$dest"; continue; }
    total=$((total + 1))
    cur=
    if [ -f "$dest/.skill-version" ]; then
      while IFS= read -r kv; do
        case "$kv" in commit=*) cur=${kv#commit=}; break ;; esac
      done < "$dest/.skill-version"
    fi
    if [ "$cur" = "$head_commit" ]; then
      printf '已最新: %s\n' "$dest"
      continue
    fi
    if [ "$dry" = 1 ]; then
      printf '需更新: %s（%s -> %s）\n' "$dest" "${cur:-未知}" "$head_commit"
      continue
    fi
    # 子进程单独跑，stdin 接 /dev/null：循环体读的是 fd 3，不会被吃掉
    if sh "$repo/install.sh" --target "$dest" --no-hook --no-register </dev/null >/dev/null 2>&1; then
      printf '已同步: %s\n' "$dest"
    else
      printf '同步失败: %s（手动: sh %s/install.sh --target "%s"）\n' "$dest" "$repo" "$dest" >&2
      bad=$((bad + 1))
    fi
  done 3< "$paths_file"
  [ "$total" -eq 0 ] && printf '清单里没有可处理的目录\n'
  [ "$bad" -gt 0 ] && die "$bad 份同步失败"
  exit 0
fi

# --printpath
resolve_workspace
caps=$config_dir/AGENT_CAPABILITIES.md
cfg_file=$config_dir/config.toml
registry_file=$paths_file
reg_count=0
[ -f "$registry_file" ] && reg_count=$(awk 'NF && $1 !~ /^#/ {n++} END{print n+0}' "$registry_file" 2>/dev/null)
caps_date=
[ -f "$caps" ] && caps_date=$(grep -o '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' "$caps" 2>/dev/null | head -1)
src_repo=
hook_repo=$repo
if ! git -C "$hook_repo" rev-parse --git-dir >/dev/null 2>&1; then
  src_repo=$(sed -n 's/^source=//p' "$repo/.skill-version" 2>/dev/null | head -1)
  if [ -n "$src_repo" ] && git -C "$src_repo" rev-parse --git-dir >/dev/null 2>&1; then
    hook_repo=$src_repo
  else
    src_repo=
  fi
fi
head_full=
if git -C "$hook_repo" rev-parse --git-dir >/dev/null 2>&1; then
  head_full=$(git -C "$hook_repo" rev-parse HEAD 2>/dev/null || true)
  hooks_path=$(git -C "$hook_repo" config --local --get core.hooksPath 2>/dev/null || true)
  case "$hooks_path" in
    .githooks) hooks_status='可选钩子已启用' ;;
    '') hooks_status='未设置（可选钩子不跑；同步由 --suspend 负责）' ;;
    *) hooks_status='未指向 .githooks（可选钩子不跑；同步由 --suspend 负责）' ;;
  esac
else
  hooks_path=未知
  hooks_status='非 git 副本，未找到源仓库'
fi
if [ -n "$target_arg" ]; then
  t=$(to_unix "$target_arg")
  host_label='manual (--target)'
elif [ -n "$host_arg" ]; then
  cfg=$(default_cfg "$host_arg" 2>/dev/null) || cfg=
  [ -n "$cfg" ] && t=$(to_unix "$cfg")/skills/$skill_id || t=未知宿主
  host_label="$host_arg (--host)"
elif detect_host; then
  t=$(to_unix "$cfg")/skills/$skill_id
  host_label="$host ($cfg_src)"
else
  t=未识别宿主
  host_label='未识别（检查宿主环境变量）'
fi
printf '路径诊断\n'
printf '────────────────────────────────────────\n'
printf '  配置目录        %s\n' "$config_dir"
if [ -f "$cfg_file" ]; then
  printf '  配置文件        %s  [已存在]\n' "$cfg_file"
else
  printf '  配置文件        %s  [不存在，安装时会创建]\n' "$cfg_file"
fi
printf '  工作区根        %s  [来源: %s]\n' "$workspace" "$workspace_src"
if [ -f "$caps" ]; then
  printf '  能力表          %s  [已存在%s]\n' "$caps" "${caps_date:+，更新 $caps_date}"
else
  printf '  能力表          %s  [缺失]\n' "$caps"
fi
if [ -f "$registry_file" ]; then
  printf '  安装注册表      %s  [%s 条]\n' "$registry_file" "$reg_count"
else
  printf '  安装注册表      %s  [缺失]\n' "$registry_file"
fi
printf '  源仓库          %s\n' "${src_repo:-$repo}"
printf '  Git 钩子        %s  [%s]\n' "${hooks_path:-未设置}" "$hooks_status"
printf '  宿主            %s\n' "$host_label"
printf '  安装副本        %s\n' "$t"
if [ -f "$registry_file" ]; then
  while IFS= read -r line <&3; do
    case "$line" in ''|'#'*) continue ;; esac
    dest=$line
    while :; do case "$dest" in *' '*) dest=${dest% } ;; *) break ;; esac; done
    [ -n "$dest" ] || continue
    cur=
    if [ -f "$dest/.skill-version" ]; then
      while IFS= read -r kv; do
        case "$kv" in commit=*) cur=${kv#commit=}; break ;; esac
      done < "$dest/.skill-version"
    fi
    if [ ! -d "$dest" ]; then st=缺失
    elif [ -z "$cur" ]; then st=无版本
    elif [ -z "$head_full" ]; then st=未知
    elif [ "$cur" = "$head_full" ]; then st=当前
    else st=落后
    fi
    cur7=$(printf '%.7s' "$cur")
    printf '  副本            %s  %s  [%s]\n' "$dest" "${cur7:--}" "$st"
  done 3< "$registry_file"
else
  printf '  副本            无注册表\n'
fi
printf '────────────────────────────────────────\n'
exit 0
