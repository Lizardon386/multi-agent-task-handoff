# sync-global-rules.ps1 — 把各 agent 的**全局规则文件**重写为源头当前的内容（带出处戳）。
# 用法:
#   powershell -NoProfile -ExecutionPolicy Bypass -File sync-global-rules.ps1                 # 只看报告，不动文件（默认 DryRun）
#   powershell -NoProfile -ExecutionPolicy Bypass -File sync-global-rules.ps1 -Apply          # 真写：先备份，再替换
#   powershell -NoProfile -ExecutionPolicy Bypass -File sync-global-rules.ps1 -Apply -AgentHomes C:\Users\x\.codex
# 为什么要有它: 2026-10-15 之前全局块是本脚本兄弟 install-everywhere.ps1 里写死的第二份文本，
#   源头改了它不动。现在 install-everywhere 已从 references/agents-rule.md 的
#   <!-- global-block:start/end --> 段截取，但**已存在的全局文件不会被自动更新**（安装器只补不覆盖，
#   免得冲掉手写内容），所以旧的那几份要人工迁一次——就是这件事。
# 安全边界:
#   ① 默认 DryRun，什么都不写；② -Apply 前给每个文件留 .bak-<时间戳>；
#   ③ 只替换"第一个命中判重锚的标题行 → 文件末尾"这一段，锚点之后若还有别的 `# ` 一级标题就**中止**，不猜；
#   ④ 保留原文件有无 BOM、以及原本的换行风格；⑤ 已经带戳且 sha == 源头 → 报"已同步"，不动。
# 它**不进工作区扁平副本清单**（bootstrap.sh / install-everywhere.ps1 那两处 6 个脚本的名单）：
#   脚本要读 references/agents-rule.md 并用 git 取 sha，而扁平副本目录里没有 `references/` 也没有
#   `.git`，铺过去只会长出一个一跑就报错的文件。它随仓库走，进的是各 agent 的技能目录（布局完整）。
# 含中文，**必须保持 UTF-8 带 BOM**——PowerShell 5.1 会把无 BOM 的中文按 GBK 误读（同 install-everywhere.ps1）。
param(
  [string]$Source = (Split-Path $PSScriptRoot -Parent),
  [string[]]$AgentHomes = @("~\.codex", "~/.qoder-cn", "~\.claude"),
  [switch]$Apply,
  [switch]$DryRun
)
$ErrorActionPreference = "Stop"
if ($DryRun) { $Apply = $false }

if (-not (Test-Path $Source)) { throw "skill 源目录不存在: $Source" }
$sourceRoot = (Resolve-Path $Source).Path.TrimEnd('\')
$rulePath = Join-Path $sourceRoot "references\agents-rule.md"
if (-not (Test-Path $rulePath)) { throw "找不到源头规则原文: $rulePath" }

# ── 新块 = 源头锚点段 + 出处戳（和 install-everywhere.ps1 同一把尺子，别另写一份文本）──
$txt = [System.IO.File]::ReadAllText($rulePath)
$aa = "<!-- global-block:start -->"; $ab = "<!-- global-block:end -->"
$s = $txt.IndexOf($aa); $e = $txt.IndexOf($ab)
if ($s -lt 0 -or $e -lt 0 -or $e -le $s) { throw "agents-rule.md 里找不到 global-block 锚点段——没有源头可取" }
$body = $txt.Substring($s + $aa.Length, $e - $s - $aa.Length).Trim()
if ($body -notmatch "任务[双三]档规范") { throw "global-block 段里没有「任务三档规范」字样，写出去会让下次铺满追加第二份" }
$sha = $null
try { $sha = (& git -C $sourceRoot log -1 --format=%h -- references/agents-rule.md 2>$null) } catch { }
if (-not $sha) { $sha = "unknown" }
$stamp = "<!-- generated-from: references/agents-rule.md @ $sha ($(Get-Date -Format 'yyyy-MM-dd')) -->"
$newBlock = "`r`n" + $body + "`r`n" + $stamp + "`r`n"

# ── 全局文件按 agent 家目录推导（与 install-everywhere.ps1 一致）──
$byName = @{ ".codex" = "AGENTS.md"; ".claude" = "CLAUDE.md" }
$targets = @()
foreach ($ah in $AgentHomes) {
  $base = (Split-Path $ah -Leaf)
  if ($byName.ContainsKey($base)) { $targets += (Join-Path $ah $byName[$base]) }
}
if ($targets.Count -eq 0) { Write-Host "没有可写的目标（-AgentHomes 里没有 .codex/.claude 这类目录名）"; exit 0 }

$mark = 0
foreach ($f in $targets) {
  Write-Host "───── $f"
  if (-not (Test-Path $f)) { Write-Host "  不存在——跳过（首次安装请跑 install-everywhere.ps1，它负责创建）"; continue }

  $raw = [System.IO.File]::ReadAllBytes($f)
  $hasBom = ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF)
  $content = [System.Text.Encoding]::UTF8.GetString($raw)
  if ($hasBom) { $content = $content.Substring(1) }
  $nl = if ($content -match "`r`n") { "`r`n" } else { "`n" }
  $content = $content -replace "`r`n", "`n"          # 内部统一成 LF，写回时再按原风格转

  if ($content -match "generated-from: references/agents-rule\.md @ ([0-9a-f]+)") {
    if ($Matches[1] -eq $sha) { Write-Host "  已同步（戳 @$sha），不动"; continue }
    Write-Host "  已有戳 @$($Matches[1])，源头现在是 @$sha → 要更新"
  }

  $lines = $content -split "`n"
  $start = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^#{1,4} .*任务[双三]档规范') { $start = $i; break }
  }
  if ($start -lt 0) {
    if ($content -match "任务[双三]档规范|agents-entry") {
      Write-Host "  [跳过] 文件里有锚点字样但**不在标题行**，我无法确定该替换哪一段——请人工处理，别让我猜"
    } else {
      Write-Host "  [追加] 没有规则块 → 在文件末尾追加新块（保留你已写的内容）"
    }
    $head = $content.TrimEnd("`n"); $newContent = $head + $newBlock
  } else {
    # 锚点之后还有一级标题 = 后面另有内容，替换会吞掉它 → 中止
    for ($j = $start + 1; $j -lt $lines.Count; $j++) {
      if ($lines[$j] -match '^# ') {
        Write-Host "  [中止] 第 $($j+1) 行还有另一个一级标题：`"$($lines[$j])`" ——我不敢把整段尾部换成新块，请手工搬"
        $mark = 1; $start = -2; break
      }
    }
    if ($start -eq -2) { continue }
    $kept = ($lines[0..($start - 1)] -join "`n")
    $removed = $lines[$start..($lines.Count - 1)]
    Write-Host "  将保留第 1-$start 行（共 $start 行本地内容），替换第 $($start + 1)-$($lines.Count) 行为新块"
    Write-Host "  将被移除的旧内容前 3 行："
    foreach ($rl in @($removed | Where-Object { $_.Trim() -ne "" } | Select-Object -First 3)) { Write-Host "    - $($rl.Substring(0, [Math]::Min(90, $rl.Length)))" }
    $newContent = $kept.TrimEnd("`n") + "`n" + $newBlock
  }

  if (-not $Apply) { Write-Host "  [DryRun] 未写入。确认无误后加 -Apply"; continue }
  $bak = "$f.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  Copy-Item -LiteralPath $f -Destination $bak -Force
  $out = $newContent
  if ($nl -eq "`r`n") { $out = $out -replace "`n", "`r`n" }
  $enc = New-Object System.Text.UTF8Encoding($hasBom)
  [System.IO.File]::WriteAllText($f, $out, $enc)
  Write-Host "  已写入（备份: $bak）"
}

if (-not $Apply) {
  Write-Host "`n这是 DryRun。要真写：再加 -Apply（会自动留 .bak-<时间戳>）"
  exit 0
}
Write-Host "`n完成。复验（Git Bash）：bash <工作树>/scripts/watchdog.sh —— 那两个文件的 [出处] 应变成「与原文同步（@ $sha）」"
if ($mark -ne 0) { exit 1 }
