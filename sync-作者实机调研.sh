#!/bin/sh
# 把工作区根的三份文档同步到本仓库的 作者实机调研/ 快照。
# 只在本机手动运行；不自动提交。

set -u

usage() {
  cat <<'EOF'
用法: bash sync-作者实机调研.sh [选项]

从工作区根（$AGENT_WORKSPACE，未设置时用仓库父目录）复制：
  AGENTS.md、PROJECT_RULES.md、AGENT_CAPABILITIES.md
到本仓库的 作者实机调研/，并注入免责标注和源文件更新日期。

选项:
  --dry-run   只显示哪些文件会变，不写文件
  --check     只比对；有差异时退出码 1
  -h, --help  显示本表

退出码: 0 最新 / 1 快照过期 / 2 源文件缺失或含敏感内容

安全：源文件含 token / 私钥 / 真实会话 ID / C:\Users 路径时拒绝同步。
EOF
}

mode=sync
case "${1:-}" in
  --dry-run) mode=dry ;;
  --check) mode=check ;;
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) echo "未知参数: $1" >&2; usage >&2; exit 1 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
repo=$script_dir
snap_dir=$repo/作者实机调研
workspace=${AGENT_WORKSPACE:-$(dirname "$repo")}

[ -d "$workspace" ] || { echo "工作区根不存在: $workspace" >&2; exit 2; }
[ -d "$snap_dir" ] || mkdir -p "$snap_dir" || exit 2

files='AGENTS.md PROJECT_RULES.md AGENT_CAPABILITIES.md'
status=0
changed=0
tmpdir=$(mktemp -d) || exit 2
trap 'rm -rf "$tmpdir"' EXIT

scan_text() {
  pat=$1
  msg=$2
  file=$3
  grep -Eq "$pat" "$file"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "拒绝同步：$msg" >&2
    return 1
  fi
  if [ "$rc" -eq 2 ]; then
    echo "读取失败：$file" >&2
    return 1
  fi
  return 0
}

for f in $files; do
  src=$workspace/$f
  dst=$snap_dir/$f
  if [ ! -f "$src" ]; then
    echo "缺少源文件: $src" >&2
    status=2
    continue
  fi
  if ! scan_text 'gho_|ghp_|github_pat_|BEGIN (RSA|OPENSSH) PRIVATE' "$f 含疑似凭据" "$src"; then
    status=2
    continue
  fi
  if ! scan_text 'ses_[A-Za-z0-9]{10,}' "$f 含真实会话 ID" "$src"; then
    status=2
    continue
  fi
  if ! scan_text 'C:\\Users|C:/Users' "$f 含 C:\\Users 本机路径，先改成 ~" "$src"; then
    status=2
    continue
  fi

  src_date=$(date -r "$src" +%F 2>/dev/null || date +%F)
  note="> **作者实机调研快照，仅供参考。** 路径、账号、宿主版本均为作者本机环境，不代表通用约定；源文件在工作区根，更新以源文件为准（源文件更新 $src_date）。"
  tmp=$tmpdir/$f
  awk -v note="$note" '
    BEGIN { inserted=0 }
    { print }
    !inserted && /^# / { print ""; print note; inserted=1 }
  ' "$src" > "$tmp"

  if [ -f "$dst" ] && cmp -s "$tmp" "$dst"; then
    echo "无变化: $f"
    continue
  fi

  changed=$((changed + 1))
  case "$mode" in
    check)
      echo "快照过期: $f"
      status=1
      ;;
    dry)
      echo "会更新: $f"
      ;;
    sync)
      cp "$tmp" "$dst" || { echo "写入失败: $dst" >&2; status=2; continue; }
      echo "已更新: $f"
      ;;
  esac
done

case "$mode" in
  check)
    [ "$status" -eq 0 ] && echo "快照已是最新"
    exit "$status"
    ;;
  dry)
    echo "（dry-run，未写文件）"
    ;;
  sync)
    if [ "$changed" -gt 0 ]; then
      echo "---"
      echo "已更新 $changed 个文件；下一步："
      echo "  git add 作者实机调研 && git commit && git push"
      git -C "$repo" status --short -- "作者实机调研" 2>/dev/null || true
    fi
    ;;
esac
exit "$status"
