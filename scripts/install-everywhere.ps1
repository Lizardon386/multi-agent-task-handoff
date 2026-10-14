# install-everywhere.ps1 — 把「任务三档规范」一键装到本机所有 agent 与工作区（幂等）
# 用法: powershell -File install-everywhere.ps1 [-Source <skill目录>] [-WorkspaceRoots <根1,根2...>]
# 铁律「更新即铺满」：skill 无论本地改过还是 git pull 到更新，都必须立刻运行本脚本。
#         -Source 缺省 = 脚本自身所在的 skill 目录——永远从"最新那份"里运行它。
# 做什么: ① 把 skill 同步进每个 agent 的技能目录  ② 给有全局指令文件的 agent 写规则块（缺才写）
#         ③ 给每个工作区铺 tools/ + AGENTS.md 规则块（与 bootstrap.sh 同一去重标记，兼容旧标题）
param(
  [string]$Source = (Split-Path $PSScriptRoot -Parent),
  [string[]]$AgentHomes = @("~\.codex", "~/.qoder-cn", "~\.claude"),
  [string[]]$WorkspaceRoots = @("D:\agent_workspace")
)
$ErrorActionPreference = "Stop"
# 去重标记用正则，同时接受旧标题「任务双档规范」：2026-10-14 规范从两档扩成三档后标题改成
# 「任务三档规范」，而本脚本对规则块是"缺才写、有就不动"——只认新名会给留着旧标题的工作区
# 追加出第二份规则块（-match 本来就是正则，这里不用额外改判定逻辑）。
$marker = "任务[双三]档规范"
if (-not (Test-Path $Source)) { throw "skill 源目录不存在: $Source" }
$report = @()

# ① 同步 skill 到各 agent 技能目录（只补缺/更新，不删除）
foreach ($agentHome in $AgentHomes) {
  if (-not (Test-Path $agentHome)) { $report += "跳过（agent 不存在）: $agentHome"; continue }
  $dest = Join-Path $agentHome "skills\multi-agent-task-handoff"
  if ((Resolve-Path $Source).Path -eq $dest) { $report += "跳过（自身即真源）: $dest"; continue }
  $updated = 0
  Get-ChildItem $Source -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' } | ForEach-Object {
    $rel = $_.FullName.Substring($Source.Length + 1)
    $tgt = Join-Path $dest $rel
    if (-not (Test-Path $tgt) -or (Get-FileHash $_.FullName -Algorithm MD5).Hash -ne (Get-FileHash $tgt -Algorithm MD5).Hash) {
      New-Item -ItemType Directory -Path (Split-Path $tgt) -Force | Out-Null
      Copy-Item $_.FullName $tgt -Force; $updated++
    }
  }
  $report += "skill 同步: $dest （更新 $updated 个文件）"
}

# ② 全局指令文件写规则块（仅对有全局文件约定的 agent；缺才追加）
$globalBlock = @"

## 任务三档规范（强制，来自 skill multi-agent-task-handoff）

以下条款对每一次会话、任意工作目录生效——禁止以"当前目录不在 agent workspace"为由跳过：

1. 会话开始即按 skill ``multi-agent-task-handoff`` 的规范工作。
2. 链接强制（无条件）：聊天回复中的任何文件产物路径一律写成可点击 Markdown 链接（不确定的宿主用 ``file:///`` 绝对路径，行号写进链接文字）；禁止裸文件名、反引号路径。
3. 在任何工作区新建任务/项目目录时，立即铺 ``README.md``（使用者说明）+ ``DESIGN.md``（方案设计）+ ``CONTEXT.md``（agent 交接）三档骨架；收工前更新 CONTEXT.md 的「当前状态」「变更记录」，三档「最近更新」同日且一致。git 仓库源码跟随仓库自身规范。
4. 工作区存在 ``tools/check-docs.sh`` 时，收工前必跑、退出码 0 才算完成；跑闸门不加管道。
5. 细节以 skill 的 ``references/agents-rule.md`` 为唯一权威。
"@
$globalFiles = @{ "~\.codex" = "AGENTS.md"; "~\.claude" = "CLAUDE.md" }
foreach ($agentHome in $globalFiles.Keys) {
  if (-not (Test-Path $agentHome)) { continue }
  $gf = Join-Path $agentHome $globalFiles[$agentHome]
  if ((Test-Path $gf) -and ([System.IO.File]::ReadAllText($gf) -match $marker)) { $report += "全局规则已存在，跳过: $gf"; continue }
  [System.IO.File]::AppendAllText($gf, $globalBlock, (New-Object System.Text.UTF8Encoding($false)))
  $report += "全局规则已写入: $gf"
}

# ③ 工作区铺 tools/ + AGENTS.md 规则块（与 bootstrap.sh 等价、同标记）
foreach ($root in $WorkspaceRoots) {
  if (-not (Test-Path $root)) { $report += "跳过（工作区不存在）: $root"; continue }
  $tools = Join-Path $root "tools"
  New-Item -ItemType Directory -Path (Join-Path $tools "templates") -Force | Out-Null
  foreach ($s in @("init-task.sh", "check-docs.sh", "bootstrap.sh", "install-everywhere.ps1")) {
    $src = Join-Path $Source "scripts\$s"; $dst = Join-Path $tools $s
    if ((Test-Path $dst) -and (Get-FileHash $src -Algorithm MD5).Hash -eq (Get-FileHash $dst -Algorithm MD5).Hash) { continue }
    Copy-Item $src $dst -Force
  }
  foreach ($t in Get-ChildItem (Join-Path $Source "assets") -File) {
    $dst = Join-Path $tools "templates\$($t.Name)"
    if ((Test-Path $dst) -and (Get-FileHash $t.FullName -Algorithm MD5).Hash -eq (Get-FileHash $dst -Algorithm MD5).Hash) { continue }
    Copy-Item $t.FullName $dst -Force
  }
  $wf = Join-Path $root "AGENTS.md"
  if ((Test-Path $wf) -and ([System.IO.File]::ReadAllText($wf) -match $marker)) { $report += "工作区规则已存在，跳过: $wf（tools/ 已同步）"; continue }
  [System.IO.File]::AppendAllText($wf, ("`n" + [System.IO.File]::ReadAllText((Join-Path $Source "references\agents-rule.md"))), (New-Object System.Text.UTF8Encoding($false)))
  $report += "工作区规则已写入: $wf（tools/ 已同步）"
}

$report | ForEach-Object { Write-Host $_ }
Write-Host "install-everywhere 完成（幂等，可重复运行）"
