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
doc_arg=
observe_level=
observe_event=

usage() {
  cat <<'EOF'
用法: bash handoff.sh [选项]

  --printpath [--host NAME | --target DIR]
                   路径诊断：配置 / 工作区 / 能力表 / 源仓库 / 宿主 / 副本清单
  --syncall [--dryrun]
                   按 $AGENT_CONFIG/sync-paths 逐份对齐到当前 HEAD，只补落后的
                   （必须从源仓库运行；--dryrun 只打印；注册表缺失时提示先跑 install.sh）
  --push [--retries N] [--delay S]
                   显式推送当前分支；源仓库推源仓库，安装副本环境推当前项目；
                   网络错误重试 3 次 / 3 秒；Windows 再加 HTTP/1.1 + OpenSSL 回退 3 次
  --save [--all] [-m MSG] [--retries N] [--delay S]
                   提交已跟踪修改（--all 含新文件），同步副本，再推送（重试）
  --gear <key>[=<值>] | --gear list
                   读/写 config.toml 的 [defaults] 挡位；省略值只读取
                   读取/写入需要 config.toml；list 只列静态映射，不需要配置
                   键与允许值由脚本映射决定；值不在白名单时不修改文件
  --doc [--guard | --init] [--target DIR]
                   默认挡位读 config.toml 的 [defaults].doc（guard）
                   --guard 维护已有文档：只删 ## 文档 表中的失效协议行，其余只报告
                   --init 由 agent 显式创建，脚本不写内容
  --observe <L2|L3> <事件>
                   记录一条使用观察；[defaults].observe=off 时跳过
                   写入 $AGENT_CONFIG/OBSERVATIONS.md（不存在则建表头）
  -h, --help       显示本表

脚本层命令：--printpath / --doc / --syncall / --push / --save / --gear / --observe
--resume / --suspend / --post / --check / --fix / --probe / --workspace
由 agent 按 SKILL 执行，不是脚本参数。
完整协议帮助见 assets/HELP.txt。

安装用 install.sh；本脚本一次只做一件事。
EOF
}

die() { printf '%s\n' "错误: $*" >&2; exit 1; }
usage_die() { printf '%s\n' "错误: $*" >&2; usage >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --printpath) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=printpath ;;
    --doc) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=doc ;;
    --guard) [ -z "$doc_arg" ] || usage_die "--guard / --init 只能用一个"; doc_arg=guard ;;
    --init) [ -z "$doc_arg" ] || usage_die "--guard / --init 只能用一个"; doc_arg=init ;;
    --syncall) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=syncall ;;
    --push) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=push ;;
    --save) [ -z "$mode" ] || usage_die "一次只用一个命令"; mode=save ;;
    --gear) [ -z "$mode" ] || usage_die "一次只用一个命令"; [ $# -ge 2 ] || usage_die "--gear 需要一个值"; gear_arg=$2; mode=gear; shift ;;
    --gear=*) [ -z "$mode" ] || usage_die "一次只用一个命令"; gear_arg=${1#*=}; mode=gear ;;
    --observe) [ -z "$mode" ] || usage_die "一次只用一个命令"; [ $# -ge 3 ] || usage_die "--observe 需要 <L2|L3> 和 <事件>"; observe_level=$2; observe_event=$3; mode=observe; shift 2 ;;
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
    --resume|--suspend|--post|--check|--fix|--probe|--workspace)
      usage_die "$1 由 agent 按 SKILL 执行，不是脚本参数（脚本支持 --printpath / --doc / --syncall / --push / --save / --gear / --observe）" ;;
    *) usage_die "未知参数 $1" ;;
  esac
  shift
done

if [ -n "$doc_arg" ] && [ "$mode" != doc ]; then
  usage_die "--guard / --init 只能跟 --doc"
fi
[ -n "$mode" ] || usage_die "需要 --printpath / --doc / --syncall / --push / --save / --gear / --observe"
if [ -n "$target_arg" ] && [ -n "$host_arg" ]; then
  usage_die "--host 与 --target 只能用一个"
fi
if [ "$mode" != printpath ] && [ "$mode" != doc ] && { [ -n "$target_arg" ] || [ -n "$host_arg" ]; }; then
  usage_die "--host / --target 只能跟 --printpath / --doc"
fi
if [ "$mode" = doc ] && [ -n "$host_arg" ]; then
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

# --doc --guard 的有限修复：只删 ## 文档 表中指向缺失协议角色的整行。
repair_doc_tables() {
  for pair in "$project/handoff/CONTEXT.md|$project/handoff" "$project/handoff/PROMPT.md|$project"; do
    file=${pair%%|*}
    base=${pair#*|}
    [ -f "$file" ] || continue
    tmp=$file.tmp.$$
    removed=0
    in_doc=0
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        '## 文档'*) in_doc=1; printf '%s\n' "$line"; continue ;;
        '## '*) in_doc=0; printf '%s\n' "$line"; continue ;;
      esac
      if [ "$in_doc" = 1 ]; then
        case "$line" in
          '|'*)
            link=$(printf '%s' "$line" | grep -oE '\]\([^)]*\)' | head -1 | sed 's/^](//; s/)$//')
            target=${link%%#*}
            if [ -z "$target" ]; then
              target=$(printf '%s' "$line" | awk -F'|' '{print $3}' | sed 's/^[[:space:]`]*//; s/[[:space:]`]*$//')
              case "$target" in *' '*) target= ;; esac
            fi
            if [ -n "$target" ] && [ ! -e "$base/$target" ]; then
              case "${target##*/}" in
                README.md|DESIGN.md|CONTEXT.md|COMPACT_BACKUP.md|COMMANDS.md|PROMPT.md)
                  removed=$((removed + 1)); continue ;;
              esac
            fi
            ;;
        esac
      fi
      printf '%s\n' "$line"
    done < "$file" > "$tmp"
    if [ "$removed" -gt 0 ]; then
      before=$(wc -l < "$file")
      if mv "$tmp" "$file"; then
        after=$(wc -l < "$file")
        printf 'FIXED    stale-role-ref  %s（删除 %s 行；before=%s after=%s）\n' "$file" "$removed" "$before" "$after"
      else
        rm -f "$tmp"
        printf 'WARN     stale-role-ref  %s（删除失败，保留原文件）\n' "$file"
        warn=1
      fi
    else
      rm -f "$tmp"
    fi
  done
}

if [ "$mode" = doc ]; then
  config_dir=$(agent_config_dir)
  cfg_file=$config_dir/config.toml
  selected=${doc_arg:-$(config_get doc "$cfg_file" 2>/dev/null || true)}
  case "$selected" in guard|init) ;; *) selected=guard ;; esac
  if [ "$selected" = init ]; then
    printf 'doc: init 由 agent 按 SKILL 的 --doc --init 执行（显式确认，脚本不写内容）\n'
    exit 0
  fi
  project=$(to_unix "${target_arg:-$PWD}")
  project=$(CDPATH= cd -- "$project" 2>/dev/null && pwd -P) || die "项目目录不存在: ${target_arg:-$PWD}"
  warn=0
  printf 'doc(guard): %s\n' "$project"
  repair_doc_tables

  if [ -f "$project/handoff/CONTEXT.md" ]; then
    printf 'OK       handoff/CONTEXT.md\n'
    case "$(tail -n 1 "$project/handoff/CONTEXT.md")" in
      *'scope=handoff'*) ;;
      *) printf 'WARN     handoff/CONTEXT.md 末行缺少 scope=handoff\n'; warn=1 ;;
    esac
  else
    printf 'WARN     handoff/CONTEXT.md 缺失（唯一必需角色；--doc 不创建）\n'
    warn=1
  fi

  readme_refs=$(grep -nE '\]\([^)]*README\.md[^)]*\)' \
    "$project/handoff/CONTEXT.md" "$project/handoff/PROMPT.md" "$project"/docs/*.md 2>/dev/null || true)
  if [ -f "$project/README.md" ]; then
    printf 'OK       README.md\n'
    case "$(tail -n 1 "$project/README.md")" in
      *'scope=root'*) ;;
      *) printf 'WARN     README.md 末行缺少 scope=root\n'; warn=1 ;;
    esac
  else
    if [ -n "$readme_refs" ]; then
      printf 'WARN     dead-link  README.md 缺失（正文/历史引用；只报告）：\n'
      printf '%s\n' "$readme_refs" | sed 's/^/         /'
      warn=1
    elif git -C "$project" remote -v 2>/dev/null | grep -qi github; then
      printf 'WARN     README.md 缺失（GitHub 项目；可显式 --doc --init）\n'
      warn=1
    else
      printf 'OK       README.md 缺失（非 GitHub 项目，按需；不创建）\n'
    fi
  fi

  link_warnings=$(
    for f in "$project/handoff/CONTEXT.md" "$project/handoff/PROMPT.md" "$project/README.md" "$project"/docs/*.md; do
      [ -f "$f" ] || continue
      dir=$(dirname "$f")
      grep -oE '\]\([^)]*\.md[^)]*\)' "$f" 2>/dev/null | sed 's/^](//; s/)$//' | while IFS= read -r link; do
        case "$link" in http*|mailto:*|\#*) continue;; esac
        target=${link%%#*}; [ -n "$target" ] || continue
        case "${target##*/}" in README.md) continue;; esac
        [ -e "$dir/$target" ] || [ -e "$project/$target" ] || printf 'WARN     dead-link  %s -> %s（只报告）\n' "$f" "$target"
      done
    done
  )
  if [ -n "$link_warnings" ]; then
    printf '%s\n' "$link_warnings"
    warn=1
  fi

  for f in "$project"/*.md; do
    [ -f "$f" ] || continue
    base=${f##*/}
    case "$base" in README.md|SKILL.md) ;; *) printf 'WARN     根目录项目文档: %s（--doc 可迁移）\n' "$base"; warn=1 ;; esac
  done

  # 可选角色建议：只报告，不创建；用户确认后才走 --doc --init。
  design_exists=0
  commands_exists=0
  [ -f "$project/docs/DESIGN.md" ] && design_exists=1
  [ -f "$project/docs/COMMANDS.md" ] && commands_exists=1
  suggest_design=
  if [ "$design_exists" = 0 ]; then
    for f in "$project"/docs/*.md "$project"/*.md; do
      [ -f "$f" ] || continue
      base=${f##*/}
      case "$base" in
        *架构*.md|*设计*.md|*方案*.md|*DESIGN*.md|*ARCH*.md|*architecture*.md|*design*.md|*proposal*.md|ADR*.md|*RFC*.md)
          suggest_design="发现 $f（设计/方案类文档）；若有架构取舍，可考虑 docs/DESIGN.md"
          break ;;
      esac
    done
    if [ -z "$suggest_design" ] && [ -f "$project/README.md" ]; then
      if grep -qiE '架构|设计|方案|architecture|design|proposal|trade-?off' "$project/README.md"; then
        suggest_design="README 提到架构/设计/方案；若有设计取舍，可考虑 docs/DESIGN.md"
      fi
    fi
  fi
  suggest_commands=
  if [ "$commands_exists" = 0 ]; then
    for d in cmd bin cli scripts; do
      if [ -d "$project/$d" ]; then
        suggest_commands="发现 $d/ 目录；若项目有多个命令/CLI，可考虑 docs/COMMANDS.md"
        break
      fi
    done
    if [ -z "$suggest_commands" ] && [ -f "$project/package.json" ] && grep -q '"bin"' "$project/package.json"; then
      suggest_commands="package.json 含 bin；若项目有 CLI，可考虑 docs/COMMANDS.md"
    fi
    if [ -z "$suggest_commands" ] && [ -f "$project/pyproject.toml" ] && grep -qE '^\[project\.scripts\]|^\[tool\.poetry\.scripts\]' "$project/pyproject.toml"; then
      suggest_commands="pyproject.toml 含 scripts；若项目有 CLI，可考虑 docs/COMMANDS.md"
    fi
    if [ -z "$suggest_commands" ] && [ -f "$project/Cargo.toml" ] && grep -q '^\[\[bin\]\]' "$project/Cargo.toml"; then
      suggest_commands="Cargo.toml 含 [[bin]]；若项目有 CLI，可考虑 docs/COMMANDS.md"
    fi
    if [ -z "$suggest_commands" ] && [ -f "$project/README.md" ]; then
      if grep -qiE '\-\-help|命令参考|command reference|usage:' "$project/README.md"; then
        suggest_commands="README 提到 --help/命令参考；若项目有 CLI，可考虑 docs/COMMANDS.md"
      fi
    fi
  fi
  [ -n "$suggest_design" ] && printf 'SUGGEST  DESIGN：%s（仅建议，不自动创建）\n' "$suggest_design"
  [ -n "$suggest_commands" ] && printf 'SUGGEST  COMMANDS：%s（仅建议，不自动创建）\n' "$suggest_commands"

  if [ "$warn" = 1 ]; then
    printf 'result: WARN（协议表已检查；其余只报告）\n'
  else
    printf 'result: OK（协议表已检查）\n'
  fi
  exit 0
fi

if [ "$mode" = observe ]; then
  case "$observe_level" in
    L2|L3) ;;
    *) usage_die "--observe 等级只支持 L2 / L3" ;;
  esac
  [ -n "$observe_event" ] || usage_die "--observe 事件不能为空"
  config_dir=$(agent_config_dir)
  cfg_file=$config_dir/config.toml
  observe_on=$(config_get observe "$cfg_file" 2>/dev/null || true)
  [ -n "$observe_on" ] || observe_on=on
  if [ "$observe_on" = off ]; then
    printf '观察记录已关闭（[defaults].observe = off）\n'
    exit 0
  fi
  project=$(basename "$(pwd -P)" 2>/dev/null || true)
  [ -n "$project" ] || project=unknown
  host_label=unknown
  if detect_host; then host_label=$host; fi
  observe_event=$(printf '%s' "$observe_event" | tr '\n' ' ' | tr '|' '/')
  observe_event=$(printf '%.200s' "$observe_event")
  obs_file=$config_dir/OBSERVATIONS.md
  if [ ! -s "$obs_file" ]; then
    mkdir -p "$config_dir" || die "无法创建配置目录: $config_dir"
    cat > "$obs_file" <<'EOF'
# multi-agent-task-handoff · 使用观察记录

> 用途：记录本机各项目使用该 skill 时的真实异常，供维护会话评估优化计划。
> 写入：协议命令出现 L2/L3 异常且 `[defaults].observe` 未关闭时由 agent 调用 `--observe` 追加。
> 读取：维护会话（skill 源仓库）在评估计划时读取；本文件不随项目仓库、不随换机迁移。
> 隐私：只记项目目录名 / 宿主 / 事件，不记完整路径、会话 ID、凭据。

## 等级

- **L2**：实际使用事件（交接 / 检查中出现异常，未造成返工）；同类累计 2 次触发计划评估。
- **L3**：造成返工或损失；直接触发计划评估。
- L1（静态代码 / 文档演进）不记入本文件，留在项目 memory。

## 记录

| 日期 | 项目 | 宿主 | 等级 | 事件 | 证据 / 后续 |
|---|---|---|---|---|---|
EOF
  fi
  if [ -s "$obs_file" ]; then
    last=$(tail -c 1 "$obs_file" 2>/dev/null || true)
    [ -n "$last" ] && printf '\n' >> "$obs_file"
  fi
  printf '| %s | %s | %s | %s | %s | — |\n' \
    "$(date '+%Y-%m-%d')" "$project" "$host_label" "$observe_level" "$observe_event" >> "$obs_file" \
    || die "写入失败: $obs_file"
  printf '已记录: %s %s %s\n' "$observe_level" "$project" "$observe_event"
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
      [ -f "$cfg_file" ] || die "配置文件不存在: $cfg_file；先运行 install.sh"
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
  git -C "$repo" commit -m "$msg" >/dev/null || die "提交失败"
  commit=$(git -C "$repo" rev-parse --short HEAD)
  sync_rc=0
  push_rc=0
  sync_out=$(sh "$script_dir/handoff.sh" --syncall 2>&1) || sync_rc=$?
  push_out=$(sh "$script_dir/handoff.sh" --push --retries "$retries" --delay "$delay" 2>&1) || push_rc=$?
  if [ "$sync_rc" -eq 0 ] && [ "$push_rc" -eq 0 ]; then
    printf '已保存: %s；同步: OK；推送: OK\n' "$commit"
    exit 0
  fi
  [ "$sync_rc" -eq 0 ] || printf '%s\n' "$sync_out" >&2
  [ "$push_rc" -eq 0 ] || printf '%s\n' "$push_out" >&2
  die "保存完成，但同步或推送失败；提交留在本地"
fi

if [ "$mode" = push ]; then
  # 源仓库（脚本所在仓库有 .git）推源仓库；安装副本环境推当前项目的 git 仓库
  if git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    push_dir=$repo
  else
    push_dir=$(pwd -P)
    git -C "$push_dir" rev-parse --git-dir >/dev/null 2>&1 \
      || die "--push 需要 git 仓库：源仓库或当前项目"
  fi
  git -C "$push_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 \
    || die "当前分支没有上游；先 git push -u origin <branch>"
  printf '推送目标: %s\n' "$push_dir"
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
        out=$(git -C "$push_dir" -c http.version=HTTP/1.1 -c http.sslBackend=openssl push 2>&1); rc=$?
      else
        out=$(git -C "$push_dir" push 2>&1); rc=$?
      fi
      if [ "$rc" -eq 0 ]; then
        printf '%s\n' "$out"
        printf '已推送: %s\n' "$(git -C "$push_dir" rev-parse --short HEAD)"
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

resolve_paths

if [ "$mode" = syncall ]; then
  if [ ! -f "$paths_file" ]; then
    if [ -f "$repo/.skill-sync-paths" ]; then
      die "找不到 $paths_file；检测到旧 $repo/.skill-sync-paths，请先运行 install.sh 迁移"
    fi
    die "找不到 $paths_file（先跑一次 install.sh 生成）"
  fi
  # 必须从源仓库跑：安装副本没有 HEAD，强行同步会把所有副本降级成 unknown。
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 \
    || die "--syncall 必须从源仓库运行（当前是安装副本，没有 HEAD）"
  # 一次 git 调用同时拿到 commit；失败才退回 unknown（少一次进程 ≈ 0.7 秒）
  head_commit=$(git -C "$repo" rev-parse HEAD 2>/dev/null) || head_commit=unknown
  printf '对齐目标: %s\n' "$head_commit"
  total=0
  latest=0
  synced=0
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
      latest=$((latest + 1))
      continue
    fi
    if [ "$dry" = 1 ]; then
      printf '需更新: %s（%s -> %s）\n' "$dest" "${cur:-未知}" "$head_commit"
      continue
    fi
    # 子进程单独跑，stdin 接 /dev/null：循环体读的是 fd 3，不会被吃掉
    if sh "$repo/install.sh" --target "$dest" --noregister </dev/null >/dev/null 2>&1; then
      synced=$((synced + 1))
    else
      printf '同步失败: %s（手动: sh %s/install.sh --target "%s"）\n' "$dest" "$repo" "$dest" >&2
      bad=$((bad + 1))
    fi
  done 3< "$paths_file"
  if [ "$total" -eq 0 ]; then
    printf '清单里没有可处理的目录\n'
  elif [ "$latest" -eq "$total" ]; then
    printf '已最新: %s 份\n' "$total"
  elif [ "$dry" = 0 ] && [ "$synced" -gt 0 ]; then
    printf '已同步: %s 份\n' "$synced"
  fi
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
elif [ -f "$repo/.skill-sync-paths" ]; then
  printf '  安装注册表      %s  [缺失；检测到旧 .skill-sync-paths，运行 install.sh 迁移]\n' "$registry_file"
else
  printf '  安装注册表      %s  [缺失]\n' "$registry_file"
fi
printf '  源仓库          %s\n' "${src_repo:-$repo}"
printf '  宿主            %s\n' "$host_label"
printf '  安装副本        %s\n' "$t"
if [ -f "$registry_file" ]; then
  total=0
  ok=0
  while IFS= read -r line <&3; do
    case "$line" in ''|'#'*) continue ;; esac
    dest=$line
    while :; do case "$dest" in *' '*) dest=${dest% } ;; *) break ;; esac; done
    [ -n "$dest" ] || continue
    total=$((total + 1))
    cur=
    if [ -f "$dest/.skill-version" ]; then
      while IFS= read -r kv; do
        case "$kv" in commit=*) cur=${kv#commit=}; break ;; esac
      done < "$dest/.skill-version"
    fi
    [ -n "$head_full" ] && [ "$cur" = "$head_full" ] && ok=$((ok + 1))
  done 3< "$registry_file"
  if [ "$total" -eq 0 ]; then
    printf '  副本            注册表为空\n'
  elif [ "$ok" -eq "$total" ]; then
    printf '  副本            %s 份全部当前\n' "$total"
  else
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
  fi
else
  printf '  副本            无注册表\n'
fi
printf '────────────────────────────────────────\n'
exit 0
