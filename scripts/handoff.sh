#!/bin/sh
# 运行时操作：路径诊断与安装副本同步。安装见 install.sh。

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || { echo "错误: 找不到脚本所在目录" >&2; exit 1; }
repo=$(CDPATH= cd -- "$script_dir/.." && pwd -P) || { echo "错误: 找不到仓库根目录" >&2; exit 1; }
[ -f "$repo/SKILL.md" ] || { echo "错误: 脚本必须放在仓库的 scripts/ 目录（找不到上层 SKILL.md）" >&2; exit 1; }
[ -f "$script_dir/lib.sh" ] || { echo "错误: 缺少 scripts/lib.sh" >&2; exit 1; }
. "$script_dir/lib.sh"

mode=
dry=0
host_arg=
target_arg=
retries=3
delay=3
retries_set=0
delay_set=0
all=0
message=
gear_arg=

usage() {
  cat <<'EOF'
用法: bash handoff.sh [选项]

  --printpath [--host NAME | --target DIR]
                   路径诊断：配置 / 工作区 / 能力表 / 源仓库 / 宿主 / 副本清单
  --syncall [--dryrun]
                   按 $AGENT_CONFIG/sync-paths 逐份对齐到当前 HEAD，只补落后的
                   （必须从源仓库运行；--dryrun 只打印）
  --push [--retries N] [--delay S]
                   显式推送当前分支；网络错误重试 3 次 / 3 秒；
                   Windows 再加 HTTP/1.1 + OpenSSL 回退 3 次
  --save [--all] [-m MSG] [--retries N] [--delay S]
                   提交已跟踪修改（--all 含新文件），同步副本，再推送（重试）
  --gear <key>[=<值>] | --gear list
                   读/写 config.toml 的 [defaults] 挡位；省略值只读取
                   键与允许值由脚本映射决定；list 列出当前键、默认值与允许值
                   值不在白名单时不修改文件
  --doc-guard [--target DIR]
                   只读检查缺失角色/被引用文档；BLOCKED 退出 1，零写入
  -h, --help       显示本表

安装用 install.sh；本脚本一次只做一件事。
EOF
}

die() { printf '%s\n' "错误: $*" >&2; exit 1; }
usage_die() { printf '%s\n' "错误: $*" >&2; usage >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --printpath) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=printpath ;;
    --doc-guard) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=docguard ;;
    --syncall) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=syncall ;;
    --push) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=push ;;
    --save) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=save ;;
    --gear) [ -z "$mode" ] || usage_die "一次只用一个命令"; [ $# -ge 2 ] || usage_die "--gear 需要一个值"; gear_arg=$2; mode=gear; shift ;;
    --gear=*) [ -z "$mode" ] || usage_die "一次只用一个命令"; gear_arg=${1#*=}; mode=gear ;;
    --all) all=1 ;;
    -m|--message) [ $# -ge 2 ] || usage_die "-m/--message 需要一个值"; message=$2; shift ;;
    --message=*) message=${1#*=} ;;
    --dryrun) dry=1 ;;
    --retries) [ $# -ge 2 ] || usage_die "--retries 需要一个值"; retries=$2; retries_set=1; shift ;;
    --retries=*) retries=${1#*=}; retries_set=1 ;;
    --delay) [ $# -ge 2 ] || usage_die "--delay 需要一个值"; delay=$2; delay_set=1; shift ;;
    --delay=*) delay=${1#*=}; delay_set=1 ;;
    --host) [ $# -ge 2 ] || usage_die "--host 需要一个值"; host_arg=$2; shift ;;
    --host=*) host_arg=${1#*=} ;;
    --target) [ $# -ge 2 ] || usage_die "--target 需要一个值"; target_arg=$2; shift ;;
    --target=*) target_arg=${1#*=} ;;
    -h|--help) usage; exit 0 ;;
    *) usage_die "未知参数 $1" ;;
  esac
  shift
done

[ -n "$mode" ] || usage_die "需要 --printpath / --doc-guard / --syncall / --push / --save / --gear"
if [ -n "$target_arg" ] && [ -n "$host_arg" ]; then
  usage_die "--host 与 --target 只能用一个"
fi
if [ "$mode" != printpath ] && [ "$mode" != docguard ] && { [ -n "$target_arg" ] || [ -n "$host_arg" ]; }; then
  usage_die "--host / --target 只能跟 --printpath / --doc-guard"
fi
if [ "$mode" = docguard ] && [ -n "$host_arg" ]; then
  usage_die "--host 只能跟 --printpath"
fi
if [ "$mode" != syncall ] && [ "$dry" = 1 ]; then
  usage_die "--dryrun 只能跟 --syncall"
fi
if [ "$mode" != push ] && [ "$mode" != save ] && { [ "$retries_set" = 1 ] || [ "$delay_set" = 1 ]; }; then
  usage_die "--retries / --delay 只能跟 --push / --save"
fi
if [ "$mode" != save ] && { [ "$all" = 1 ] || [ -n "$message" ]; }; then
  usage_die "--all / -m 只能跟 --save"
fi
if [ "$mode" = gear ] && [ -z "$gear_arg" ]; then
  usage_die "--gear 需要 <key>、<key>=<value> 或 list"
fi
case "$retries" in ''|*[!0-9]*) usage_die "--retries 必须是正整数" ;; esac
[ "$retries" -ge 1 ] || usage_die "--retries 必须 ≥ 1"
case "$delay" in ''|*[!0-9]*) usage_die "--delay 必须是非负整数" ;; esac
if [ -n "$host_arg" ]; then
  case "$host_arg" in
    qoder|claude|codex|opencode|zcode|workbuddy) ;;
    *) usage_die "--host 只支持 qoder/claude/codex/opencode/zcode/workbuddy" ;;
  esac
fi

if [ "$mode" = docguard ]; then
  project=$(to_unix "${target_arg:-$PWD}")
  project=$(CDPATH= cd -- "$project" 2>/dev/null && pwd -P) || die "项目目录不存在: ${target_arg:-$PWD}"
  blocked=0
  printf 'doc-guard: %s\n' "$project"

  if [ -f "$project/handoff/CONTEXT.md" ]; then
    printf 'OK       handoff/CONTEXT.md\n'
    case "$(tail -n 1 "$project/handoff/CONTEXT.md")" in
      *'scope=handoff'*) ;;
      *) printf 'WARN     handoff/CONTEXT.md 末行缺少 scope=handoff\n' ;;
    esac
  else
    printf 'BLOCKED  handoff/CONTEXT.md 缺失（唯一必需角色）\n'
    blocked=1
  fi

  readme_refs=$(grep -nE '\]\([^)]*README\.md[^)]*\)' \
    "$project/handoff/CONTEXT.md" "$project/handoff/PROMPT.md" "$project"/docs/*.md 2>/dev/null || true)
  if [ -f "$project/README.md" ]; then
    printf 'OK       README.md\n'
    case "$(tail -n 1 "$project/README.md")" in
      *'scope=root'*) ;;
      *) printf 'WARN     README.md 末行缺少 scope=root\n' ;;
    esac
  else
    if [ -n "$readme_refs" ]; then
      printf 'BLOCKED  README.md 缺失，但被以下位置引用：\n'
      printf '%s\n' "$readme_refs" | sed 's/^/         /'
      printf '         不得生成/还原；需用户决定恢复或移除引用\n'
      blocked=1
    elif git -C "$project" remote -v 2>/dev/null | grep -qi github; then
      printf 'BLOCKED  README.md 缺失（GitHub 项目必需；先跑 --doc-init）\n'
      blocked=1
    else
      printf 'OK       README.md 缺失（非 GitHub 项目，按需；不创建）\n'
    fi
  fi

  for f in "$project/handoff/CONTEXT.md" "$project/handoff/PROMPT.md" "$project/README.md" "$project"/docs/*.md; do
    [ -f "$f" ] || continue
    dir=$(dirname "$f")
    grep -oE '\]\([^)]*\.md[^)]*\)' "$f" 2>/dev/null | sed 's/^](//; s/)$//' | while IFS= read -r link; do
      case "$link" in http*|mailto:*|\#*) continue;; esac
      target=${link%%#*}; [ -n "$target" ] || continue
      [ -e "$dir/$target" ] || printf 'WARN     %s -> %s（原有死链，只报告）\n' "$f" "$target"
    done
  done

  for f in "$project"/*.md; do
    [ -f "$f" ] || continue
    base=${f##*/}
    case "$base" in README.md|SKILL.md) ;; *) printf 'WARN     根目录项目文档: %s（--doc 可迁移）\n' "$base" ;; esac
  done

  if [ "$blocked" = 1 ]; then
    printf 'result: BLOCKED（--doc 必须停止，零写入）\n'
    exit 1
  fi
  printf 'result: OK\n'
  exit 0
fi

if [ "$mode" = gear ]; then
  config_dir=$(agent_config_dir)
  cfg_file=$config_dir/config.toml
  if [ "$gear_arg" = list ]; then
    for key in $(gear_keys); do
      meta=$(gear_meta "$key") || continue
      default=$(printf '%s\n' "$meta" | sed -n '1p')
      allowed=$(printf '%s\n' "$meta" | sed -n '2p')
      printf '%-8s default=%-8s allowed=%s\n' "$key" "$default" "$allowed"
    done
    exit 0
  fi
  case "$gear_arg" in
    *=*)
      key=${gear_arg%%=*}
      value=${gear_arg#*=}
      meta=$(gear_meta "$key") || die "--gear 不支持键 $key；用 --gear list 查看；未修改"
      allowed=$(printf '%s\n' "$meta" | sed -n '2p')
      case " $allowed " in *" $value "*) ;; *) die "--gear $key 只支持 $allowed；未修改" ;; esac
      [ -f "$cfg_file" ] || die "配置文件不存在: $cfg_file；先运行 install.sh"
      config_set "$key" "$value" "$cfg_file" || die "写入失败: $cfg_file"
      printf '%s=%s\n' "$key" "$value"
      ;;
    *)
      meta=$(gear_meta "$gear_arg") || die "--gear 不支持键 $gear_arg；用 --gear list 查看"
      default=$(printf '%s\n' "$meta" | sed -n '1p')
      allowed=$(printf '%s\n' "$meta" | sed -n '2p')
      v=$(config_get "$gear_arg" "$cfg_file" 2>/dev/null || true)
      case " $allowed " in *" $v "*) ;; *) v=$default ;; esac
      printf '%s\n' "$v"
      ;;
  esac
  exit 0
fi

if [ "$mode" = save ]; then
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || die "--save 必须在源仓库运行"
  if [ "$all" = 1 ]; then
    git -C "$repo" add -A || die "git add -A 失败"
  else
    git -C "$repo" add -u || die "git add -u 失败"
  fi
  if git -C "$repo" diff --cached --quiet; then
    echo "无改动，跳过"
    exit 0
  fi
  msg=${message:-"chore: autosave $(date '+%Y-%m-%d %H:%M')"}
  git -C "$repo" commit -m "$msg" || die "提交失败"
  printf '已提交: %s\n' "$(git -C "$repo" rev-parse --short HEAD)"
  sync_rc=0
  push_rc=0
  sh "$script_dir/handoff.sh" --syncall || sync_rc=$?
  sh "$script_dir/handoff.sh" --push --retries "$retries" --delay "$delay" || push_rc=$?
  [ "$sync_rc" -eq 0 ] && [ "$push_rc" -eq 0 ] || die "保存完成，但同步或推送失败；提交留在本地"
  exit 0
fi

if [ "$mode" = push ]; then
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || die "--push 必须在源仓库运行"
  git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 \
    || die "当前分支没有上游；先 git push -u origin <branch>"
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) tls_fallback=1 ;;
    *) tls_fallback=0 ;;
  esac
  for phase in normal fallback; do
    if [ "$phase" = fallback ]; then
      [ "$tls_fallback" = 1 ] || continue
      printf '常规推送失败，改用 HTTP/1.1 + OpenSSL 重试（%s 次 / %s 秒）\n' "$retries" "$delay" >&2
    fi
    i=1
    while [ "$i" -le "$retries" ]; do
      if [ "$phase" = fallback ]; then
        out=$(git -C "$repo" -c http.version=HTTP/1.1 -c http.sslBackend=openssl push 2>&1); rc=$?
      else
        out=$(git -C "$repo" push 2>&1); rc=$?
      fi
      if [ "$rc" -eq 0 ]; then
        printf '%s\n' "$out"
        printf '已推送: %s\n' "$(git -C "$repo" rev-parse --short HEAD)"
        exit 0
      fi
      case "$out" in
        *"Authentication failed"*|*"Permission denied"*|*"non-fast-forward"*|*"rejected"*|*"protected branch"*|*"could not read Username"*|*"terminal prompts disabled"*)
          printf '%s\n' "$out" >&2
          die "推送失败（非网络错误，不重试）" ;;
      esac
      if [ "$phase" = fallback ]; then
        printf 'TLS 回退失败（第 %s/%s 次）：\n%s\n' "$i" "$retries" "$out" >&2
      else
        printf '推送失败（第 %s/%s 次）：\n%s\n' "$i" "$retries" "$out" >&2
      fi
      [ "$i" -lt "$retries" ] && sleep "$delay"
      i=$((i + 1))
    done
  done
  if [ "$tls_fallback" = 1 ]; then
    die "推送连续失败（常规 + TLS 回退各 $retries 次）；提交留在本地"
  fi
  die "推送连续失败 $retries 次；提交留在本地"
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
    # Git Bash 在 Windows 上每启动一个 sed/dirname 约 0.9 秒，四份累积能把同步拖到 8 秒以上。
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
    if sh "$repo/install.sh" --target "$dest" --noregister </dev/null >/dev/null 2>&1; then
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
head_repo=$repo
if ! git -C "$head_repo" rev-parse --git-dir >/dev/null 2>&1; then
  src_repo=$(sed -n 's/^source=//p' "$repo/.skill-version" 2>/dev/null | head -1)
  if [ -n "$src_repo" ] && git -C "$src_repo" rev-parse --git-dir >/dev/null 2>&1; then
    head_repo=$src_repo
  else
    src_repo=
  fi
fi
head_full=
if git -C "$head_repo" rev-parse --git-dir >/dev/null 2>&1; then
  head_full=$(git -C "$head_repo" rev-parse HEAD 2>/dev/null || true)
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
