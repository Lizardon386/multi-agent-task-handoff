#!/bin/sh
# 共享函数：配置目录、工作区根、宿主识别、路径转换。
# 由 install.sh / handoff.sh source；不单独执行。

skill_id=multi-agent-task-handoff

# 机器级配置目录：$AGENT_CONFIG > %APPDATA% > $XDG_CONFIG_HOME > ~/.config
agent_config_dir() {
  if [ -n "${AGENT_CONFIG:-}" ]; then printf '%s\n' "$AGENT_CONFIG"
  elif [ -n "${APPDATA:-}" ]; then printf '%s\n' "$APPDATA/multi-agent-task-handoff" | sed 's|\\|/|g'
  elif [ -n "${XDG_CONFIG_HOME:-}" ]; then printf '%s\n' "$XDG_CONFIG_HOME/multi-agent-task-handoff"
  else printf '%s\n' "$HOME/.config/multi-agent-task-handoff"
  fi
}

expand_path() {
  p=$1
  case "$p" in
    '~') p=$HOME ;;
    '~/'*) p=$HOME/${p#\~/} ;;
  esac
  case "$p" in
    *'%USERPROFILE%'*) p=$(printf '%s' "$p" | sed "s|%USERPROFILE%|$HOME|g") ;;
  esac
  printf '%s\n' "$p"
}

config_get() {
  key=$1
  file=$2
  [ -f "$file" ] || return 1
  sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*\"\\(.*\\)\"[[:space:]]*$/\1/p" "$file" | head -1
}

# 只改 [defaults] 下的 key；key 不存在时插在 [defaults] 后；失败不留下临时文件。
config_set() {
  key=$1
  value=$2
  file=$3
  [ -f "$file" ] || return 1
  has=$(awk -v key="$key" '
    /^[[:space:]]*\[defaults\][[:space:]]*$/ { in_defaults=1; next }
    /^[[:space:]]*\[/ { in_defaults=0 }
    in_defaults && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" { found=1; exit }
    END { print found+0 }
  ' "$file")
  tmp=$file.tmp.$$
  if [ "$has" = 1 ]; then
    awk -v key="$key" -v value="$value" '
      /^[[:space:]]*\[defaults\][[:space:]]*$/ { in_defaults=1; print; next }
      /^[[:space:]]*\[/ { in_defaults=0 }
      {
        if (in_defaults && $0 ~ "^[[:space:]]*" key "[[:space:]]*=") {
          print key " = \"" value "\""; next
        }
        print
      }
    ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
  else
    awk -v key="$key" -v value="$value" '
      { print }
      /^[[:space:]]*\[defaults\][[:space:]]*$/ && !done {
        print key " = \"" value "\""; done=1
      }
      END { exit done ? 0 : 3 }
    ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
  fi
  mv "$tmp" "$file" || { rm -f "$tmp"; return 1; }
}

# --gear 的唯一映射：键名与 config.toml 的 [defaults] 一致。
# 每项输出两行：默认值、允许值（空格分隔）；新增挡位只改这里。
gear_meta() {
  case "$1" in
    suspend) printf '%s\n' local "local commit push" ;;
    probe) printf '%s\n' static "static live" ;;
    post) printf '%s\n' new "new next" ;;
    *) return 1 ;;
  esac
}

gear_keys() {
  printf '%s\n' suspend probe post
}

resolve_workspace() {
  if [ -n "${AGENT_WORKSPACE:-}" ]; then
    workspace=$(expand_path "$AGENT_WORKSPACE"); workspace_src=AGENT_WORKSPACE; return
  fi
  cfg_file=$(agent_config_dir)/config.toml
  v=$(config_get workspace "$cfg_file" 2>/dev/null || true)
  if [ -n "$v" ]; then
    workspace=$(expand_path "$v"); workspace_src=config.toml; return
  fi
  workspace=$HOME/agent_workspace; workspace_src=default
}

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
    opencode)
      if [ -n "${OPENCODE_CONFIG_DIR:-}" ]; then printf '%s\n' "$OPENCODE_CONFIG_DIR"
      elif [ -n "${XDG_CONFIG_HOME:-}" ]; then printf '%s\n' "$XDG_CONFIG_HOME/opencode"
      else printf '%s\n' "$HOME/.config/opencode"; fi ;;
    zcode)
      if [ -n "${ZCODE_CONFIG_DIR:-}" ]; then printf '%s\n' "$ZCODE_CONFIG_DIR"; else printf '%s\n' "$HOME/.zcode"; fi ;;
    workbuddy)
      if [ -n "${WORKBUDDY_CONFIG_DIR:-}" ]; then printf '%s\n' "$WORKBUDDY_CONFIG_DIR"
      elif [ -n "${CODEBUDDY_CONFIG_DIR:-}" ]; then printf '%s\n' "$CODEBUDDY_CONFIG_DIR"
      elif [ -d "$HOME/.workbuddy" ]; then printf '%s\n' "$HOME/.workbuddy"
      else return 1; fi ;;
    *) return 1 ;;
  esac
}

detect_host() {
  # WorkBuddy 放在最前：它同时会带 CODEBUDDY_CONFIG_DIR / CLAUDE_* 等通用变量，
  # 靠 CODEBUDDY_HOST 前缀和 WORKBUDDY_* 先认，避免被后面的通用变量误判成别的宿主。
  if [ -n "${CODEBUDDY_HOST:-}" ]; then
    case "$CODEBUDDY_HOST" in
      workbuddy*) host=workbuddy; cfg=$(default_cfg workbuddy); cfg_src=CODEBUDDY_HOST; return 0 ;;
    esac
  fi
  if [ -n "${WORKBUDDY_CONFIG_DIR:-}" ]; then
    host=workbuddy; cfg=$WORKBUDDY_CONFIG_DIR; cfg_src=WORKBUDDY_CONFIG_DIR; return 0
  fi
  if [ -n "${CODEBUDDY_CONFIG_DIR:-}" ]; then
    host=workbuddy; cfg=$CODEBUDDY_CONFIG_DIR; cfg_src=CODEBUDDY_CONFIG_DIR; return 0
  fi
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
  if [ -n "${OPENCODE_CONFIG_DIR:-}" ]; then
    host=opencode; cfg=$OPENCODE_CONFIG_DIR; cfg_src=OPENCODE_CONFIG_DIR; return 0
  fi
  if [ -n "${OPENCODE:-}" ]; then
    host=opencode; cfg=$(default_cfg opencode); cfg_src=OPENCODE; return 0
  fi
  if [ -n "${ZCODE_CONFIG_DIR:-}" ]; then
    host=zcode; cfg=$ZCODE_CONFIG_DIR; cfg_src=ZCODE_CONFIG_DIR; return 0
  fi
  if [ -n "${ZCODE_APP_VERSION:-}" ]; then
    host=zcode; cfg=$(default_cfg zcode); cfg_src=ZCODE_APP_VERSION; return 0
  fi
  return 1
}

# 安装注册表统一放 $AGENT_CONFIG/sync-paths；旧位置 $repo/.skill-sync-paths 一次性迁移。
# 依赖调用方已设置 $repo；设置 config_dir、paths_file。
resolve_paths_file() {
  config_dir=$(agent_config_dir)
  paths_file=$config_dir/sync-paths
  if [ ! -f "$paths_file" ] && [ -f "$repo/.skill-sync-paths" ]; then
    mkdir -p "$config_dir" 2>/dev/null || true
    cp "$repo/.skill-sync-paths" "$paths_file" 2>/dev/null && rm -f "$repo/.skill-sync-paths" \
      && echo "迁移: .skill-sync-paths -> $paths_file"
  fi
}
