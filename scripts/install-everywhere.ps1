# install-everywhere.ps1 — 把「任务三档规范」一键装到本机所有 agent 与工作区（幂等）
# 用法: powershell -File install-everywhere.ps1 [-Source <skill目录>] [-WorkspaceRoots <根1,根2...>]
#                                       [-Prune] [-DryRun]
# 铁律「更新即铺满」：skill 无论本地改过还是 git pull 到更新，都必须立刻运行本脚本。
#         -Source 缺省 = 脚本所在的 scripts\ 目录的上一级 = skill 根目录，所以从真源工作树
#         （D:\agent_workspace\multi-agent-task-handoff\scripts\）里跑它就是对的。
#         2026-10-14 前真源住在 agent 的 skills 目录里；现在那里只是下游副本，别再从那儿改。
# 做什么: ① 把 skill 同步进每个 agent 的技能目录  ② 给有全局指令文件的 agent 写规则块（缺才写）
#         ③ 给每个工作区铺脚本副本目录 + AGENTS.md 规则块（与 bootstrap.sh 同一把**双锚**去重锁：
#            老锚「任务三档规范」或新锚 `agents-entry`，命中任一就不动；两者都没有的已存在文件
#            只警告不灌规则，防止覆盖别人写的东西）
#         全局规则块与出处戳都从 references\agents-rule.md 取——本脚本里**不再写死第二份文本**。
#         装了 skill 的工作区可用 `bootstrap.sh --root <根> --entry` 走"入口模式"：AGENTS.md 只剩
#         本机政策 + 指针，细则只在真源里，从此没有同步义务。
#         副本目录 2026-10-14 起叫 multi-agent-task-handoff；工作区里已有旧名 tools/ 时沿用旧名。
# 默认只补不删：仓库里删掉一个文件（如 2026-10-14 合并掉的 .github/README.md），各副本里那份
#         会留着继续误导 agent，而"副本 == 真源"正是整套铺满的前提。加 -Prune 才会清理，
#         且先列清单再删（-Prune -DryRun = 只列不删）。删除范围严格限定在本脚本自己铺过的
#         两个子树内（技能目录下的 skill 子树、工作区脚本副本目录），不碰任务目录、不碰 AGENTS.md。
param(
  [string]$Source = (Split-Path $PSScriptRoot -Parent),
  [string[]]$AgentHomes = @("~\.codex", "~/.qoder-cn", "~\.claude"),
  [string[]]$WorkspaceRoots = @("D:\agent_workspace"),
  [switch]$Prune,
  [switch]$DryRun
)
$ErrorActionPreference = "Stop"
# 去重锚有两个，命中任一即视为"这里已经装过规则块"、不再追加：
#   老锚——标题里含「任务三档规范」（同时接受拆分前的旧标题「任务双档规范」，只认新名会给
#         留着旧标题的工作区追加出第二份规则块）；
#   新锚——**整行**的 <!-- agents-entry -->：入口模式的工作区根里没有任何条款文字，靠它判重。
# 新锚必须整行匹配——本文件与 agents-rule.md 正文都会提到 agents-entry 这串字，裸子串匹配会把
# "提到过锚"当成"装了锚"，该追加的就不追加了（假绿灯）。
# 与 bootstrap.sh 的 RULE_MARK_RE / ENTRY_MARK_RE 是同一把锁的两套实现，**必须一起改**。
$marker = "任务[双三]档规范"
$entryMarker = '(?m)^\s*<!--\s*agents-entry\s*-->\s*$'

if (-not (Test-Path $Source)) { throw "skill 源目录不存在: $Source" }
$report = @()
$sourceRoot = (Resolve-Path $Source).Path.TrimEnd('\')

# 「应有清单」= 源里所有文件的相对路径（小写、反斜杠统一），供技能目录镜像比对。
function Get-MirrorExpectedSet([string]$src) {
  $set = @{}
  Get-ChildItem $src -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' } | ForEach-Object {
    $set[$_.FullName.Substring($src.Length + 1).Replace('/', '\').ToLowerInvariant()] = $true
  }
  $set
}
# 工作区副本目录是**派生布局**（扁平脚本 + templates/ ← assets/），不能拿源相对路径直接比，
# 否则会把整份扁平副本当成"多余文件"删光。这里显式列出本脚本铺过什么。
function Get-CopyExpectedSet([string]$src) {
  $set = @{}
  foreach ($s in @("init-task.sh", "check-docs.sh", "bootstrap.sh", "install-everywhere.ps1", "selftest.sh", "muttest.sh")) { $set[$s] = $true }
  $assets = Join-Path $src "assets"
  if (Test-Path $assets) {
    Get-ChildItem $assets -File | ForEach-Object { $set["templates\$($_.Name)".ToLowerInvariant()] = $true }
  }
  $set
}
# 先列清单再删；-DryRun 只列。删完后自底向上收掉空目录（只在本子树内）。
function Remove-StaleFiles([string]$root, [hashtable]$expected, [string]$label) {
  if (-not (Test-Path $root)) { return }
  $resolved = (Resolve-Path $root).Path.TrimEnd('\')
  # 两道保险：不许拿真源自己开刀；路径短得不像个目录（盘根、`\Users` 之类）直接拒。
  if ($resolved -eq $sourceRoot) { $script:report += "$label 跳过 prune（它就是真源）"; return }
  if ($resolved.Length -lt 12) { throw "$label prune 拒绝执行：目标路径过短，不像受管子树 ($resolved)" }
  $stale = @(Get-ChildItem $resolved -Recurse -File | Where-Object {
      -not $expected.ContainsKey($_.FullName.Substring($resolved.Length + 1).Replace('/', '\').ToLowerInvariant())
    })
  if ($stale.Count -eq 0) { $script:report += "$label prune：无残留文件"; return }
  foreach ($f in $stale) { $script:report += "$label prune 待删: $($f.FullName)" }
  if ($DryRun) { $script:report += "$label prune：DryRun，未删除（$($stale.Count) 个）"; return }
  foreach ($f in $stale) { Remove-Item -LiteralPath $f.FullName -Force; $script:report += "$label prune 已删: $($f.FullName.Substring($resolved.Length + 1))" }
  Get-ChildItem $resolved -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
    if (-not (Get-ChildItem $_.FullName -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $_.FullName -Force }
  }
  $script:report += "$label prune：已删 $($stale.Count) 个残留文件"
}
$mirrorExpected = $null
if ($Prune) { $mirrorExpected = Get-MirrorExpectedSet $sourceRoot }

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
  if ($Prune) { Remove-StaleFiles $dest $mirrorExpected "技能副本 $dest" }
}

# ② 全局指令文件写规则块（仅对有全局文件约定的 agent；缺才追加）
# 全局块**不再在本脚本里写死**（2026-10-15 合并）：从 references/agents-rule.md 的
# <!-- global-block:start/end --> 之间截取。源头只有一个，不会再出现"原文更新了、
# 各 agent 的全局块还停在旧版"。截不到就报错退出——绝不用脆弱正则猜着拼。
$globalAnchorA = "<!-- global-block:start -->"
$globalAnchorB = "<!-- global-block:end -->"
function Get-GlobalBlock([string]$src) {
  $txt = [System.IO.File]::ReadAllText((Join-Path $src "references\agents-rule.md"))
  $s = $txt.IndexOf($globalAnchorA); $e = $txt.IndexOf($globalAnchorB)
  if ($s -lt 0 -or $e -lt 0 -or $e -le $s) { throw "agents-rule.md 里找不到 global-block 锚点段——全局规则块没有源头可取" }
  $block = $txt.Substring($s + $globalAnchorA.Length, $e - $s - $globalAnchorA.Length).Trim()
  # 截出来的段必须含老锚，否则写进全局文件后下次判重失配、会追加出第二份全局块
  if ($block -notmatch $script:marker) { throw "global-block 段里没有「$script:marker」字样，写出去会让下次铺满追加第二份全局块" }
  return "`n" + $block + "`n"
}
# 出处戳：派生物要能回答"我是从哪个版本的原文生成的"，watchdog 的 [出处] 探针靠它算落后多少。
function Get-SourceStamp([string]$src) {
  $sha = $null
  try { $sha = (& git -C $src log -1 --format=%h -- references/agents-rule.md 2>$null) } catch { }
  if (-not $sha) { $sha = "unknown" }
  return "<!-- generated-from: references/agents-rule.md @ $sha ($(Get-Date -Format 'yyyy-MM-dd')) -->`n"
}
$globalBlock = (Get-GlobalBlock $sourceRoot) + (Get-SourceStamp $sourceRoot)
# 全局文件按 agent 家目录**推导**，不再写死 `~\…`（2026-10-15 修）：
# 原先这里硬编码本机两个路径，发给别人的机器上第②步等于空转——别人的全局规则文件根本没被写。
# 约定：`.codex` → AGENTS.md（Codex CLI/桌面版每次会话必读），`.claude` → CLAUDE.md；其他家目录没有全局文件约定，跳过。
$globalByName = @{ ".codex" = "AGENTS.md"; ".claude" = "CLAUDE.md" }
$globalFiles = @{}
foreach ($ah in $AgentHomes) {
  $base = (Split-Path $ah -Leaf)
  if ($globalByName.ContainsKey($base)) { $globalFiles[$ah] = $globalByName[$base] }
}
foreach ($agentHome in $globalFiles.Keys) {
  if (-not (Test-Path $agentHome)) { continue }
  $gf = Join-Path $agentHome $globalFiles[$agentHome]
  $gt = ""
  if (Test-Path $gf) { $gt = [System.IO.File]::ReadAllText($gf) }
  if (($gt -match $marker) -or ($gt -match $entryMarker)) { $report += "全局规则已存在，跳过: $gf"; continue }
  [System.IO.File]::AppendAllText($gf, $globalBlock, (New-Object System.Text.UTF8Encoding($false)))
  $report += "全局规则已写入: $gf（出处戳见文件末行）"
}

# ③ 工作区铺脚本副本目录 + AGENTS.md 规则块（与 bootstrap.sh 等价、同标记）
foreach ($root in $WorkspaceRoots) {
  if (-not (Test-Path $root)) { $report += "跳过（工作区不存在）: $root"; continue }
  # 副本目录名解析与 bootstrap.sh 保持一致：已有旧名 tools/ 且还没有新名时沿用 tools/，
  # 否则一次铺满会铺出两份脚本、"哪份是真副本"没人认领（2026-10-14 本目录就是这么丢的）。
  $tools = Join-Path $root "multi-agent-task-handoff"
  $legacy = Join-Path $root "tools"
  if ((Test-Path $legacy) -and -not (Test-Path $tools)) { $tools = $legacy }
  # 真源自己就住在这个副本目录里时不铺自己：2026-10-14 起 D:\agent_workspace\multi-agent-task-handoff
  # 是 skill 仓库的 git 工作树（布局 scripts/ + assets/），往它根上铺扁平脚本会造出两份真源。
  if ((Test-Path $tools) -and ((Resolve-Path $tools).Path -eq (Resolve-Path $Source).Path)) {
    $report += "副本目录即真源，跳过脚本/模板同步: $tools"
  } else {
    New-Item -ItemType Directory -Path (Join-Path $tools "templates") -Force | Out-Null
    foreach ($s in @("init-task.sh", "check-docs.sh", "bootstrap.sh", "install-everywhere.ps1", "selftest.sh", "muttest.sh")) {
      $src = Join-Path $Source "scripts\$s"; $dst = Join-Path $tools $s
      if ((Test-Path $dst) -and (Get-FileHash $src -Algorithm MD5).Hash -eq (Get-FileHash $dst -Algorithm MD5).Hash) { continue }
      Copy-Item $src $dst -Force
    }
    foreach ($t in Get-ChildItem (Join-Path $Source "assets") -File) {
      $dst = Join-Path $tools "templates\$($t.Name)"
      if ((Test-Path $dst) -and (Get-FileHash $t.FullName -Algorithm MD5).Hash -eq (Get-FileHash $dst -Algorithm MD5).Hash) { continue }
      Copy-Item $t.FullName $dst -Force
    }
    if ($Prune) { Remove-StaleFiles $tools (Get-CopyExpectedSet $sourceRoot) "工作区副本 $tools" }
  }
  $wf = Join-Path $root "AGENTS.md"
  $wt = ""
  if (Test-Path $wf) { $wt = [System.IO.File]::ReadAllText($wf) }
  if (($wt -match $marker) -or ($wt -match $entryMarker)) {
    $which = if ($wt -match $entryMarker) { "新锚 agents-entry（入口模式）" } else { "老锚「任务三档规范」" }
    $report += "工作区规则已存在，跳过: $wf（$which；副本目录: $tools）"
    continue
  }
  if (Test-Path $wf) {
    # 既不认老锚也不认新锚的已存在文件：往里灌整段规则等于覆盖别人写的东西。铺满是无人的，
    # 所以这里只警告不动手（bootstrap.sh 交互式那条则直接报错要人选模式）。落后交给看门狗报。
    $report += "[警告] $wf 既无「任务三档规范」标题也无 <!-- agents-entry -->，不往里灌规则——请明确选一种模式：整份跑 bootstrap.sh --root $root，入口模式加 --entry（并在新文件里留住锚）"
    continue
  }
  $body = "`n" + [System.IO.File]::ReadAllText((Join-Path $Source "references\agents-rule.md")) + "`n" + (Get-SourceStamp $sourceRoot)
  [System.IO.File]::AppendAllText($wf, ("# 工作区约定（" + (Split-Path $root -Leaf) + "）`n" + $body), (New-Object System.Text.UTF8Encoding($false)))
  $report += "工作区规则已写入: $wf（副本目录: $tools）"
}

$report | ForEach-Object { Write-Host $_ }
Write-Host "install-everywhere 完成（幂等，可重复运行）"
