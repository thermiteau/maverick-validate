<#
.SYNOPSIS
  check-suite.ps1 - verify the audit-prompt suite's own invariants.
  Windows port of check-suite.sh. Runs on Windows PowerShell 5.1 and PowerShell 7+.

.DESCRIPTION
  Guards the mechanical rules that otherwise rely on reviewer discipline (see
  CLAUDE.md). Run it after adding, removing, renumbering, or editing a prompt. It
  exits non-zero and lists every violation; zero means the suite is consistent.

  Checks:
    A. Numbering is contiguous 01..N with no gaps or duplicates.
    B. Every prompt file is linked from README.md.
    C. Every topic prompt appears in an orchestrator theme group.
    D. Every ./... link in README.md resolves on disk.
    E. The orchestrator range line's high number equals the highest topic.
    F. Each topic prompt has the invariant sections, in order.
    G. Each topic's declared audit/<slug>.md output equals its filename slug.

.EXAMPLE
  .\check-suite.ps1
  powershell -ExecutionPolicy Bypass -File .\check-suite.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir  = $PSScriptRoot
$PromptsDir = Join-Path $ScriptDir 'prompts'
$Readme     = Join-Path $ScriptDir 'README.md'
$Orch       = Join-Path $PromptsDir '00-orchestrator.md'

if (-not (Test-Path -LiteralPath $PromptsDir)) { Write-Host "ERROR: prompts\ not found ($PromptsDir)"; exit 2 }
if (-not (Test-Path -LiteralPath $Readme))     { Write-Host "ERROR: README.md not found ($Readme)"; exit 2 }
if (-not (Test-Path -LiteralPath $Orch))       { Write-Host "ERROR: 00-orchestrator.md not found ($Orch)"; exit 2 }

$script:Fails = 0
function Add-Fail([string]$Message) { $script:Fails++; Write-Host "  FAIL  $Message" }
function Pass([string]$Message)     { Write-Host "  ok    $Message" }

# The invariant section sequence every topic prompt must contain, in order.
$RequiredSections = @(
    '## Role'
    '## Objective'
    '## Investigate'
    '## Amateur / AI-built red flags'
    '## Scoring anchors'
)

# Collect topic prompts (NN-*.md, excluding the orchestrator). @() => reliable .Count.
$Topics = @(
    Get-ChildItem -LiteralPath $PromptsDir -Filter '*.md' |
        Where-Object { $_.Name -match '^\d\d-' -and $_.Name -ne '00-orchestrator.md' } |
        Sort-Object Name |
        ForEach-Object {
            [pscustomobject]@{
                Num  = $_.Name.Substring(0, 2)
                Slug = ($_.BaseName -replace '^\d\d-', '')
                File = $_.FullName
                Name = $_.Name
            }
        }
)

$Count = $Topics.Count
if ($Count -eq 0) { Write-Host "ERROR: no topic prompts found."; exit 2 }

$ReadmeText = Get-Content -LiteralPath $Readme -Raw
$OrchText   = Get-Content -LiteralPath $Orch -Raw

Write-Host "Checking $Count topic prompts in $PromptsDir"
Write-Host ""

# ---- A. contiguous numbering -------------------------------------------------
Write-Host ("A. Numbering contiguous 01..{0:D2}" -f $Count)
$expected = 1
foreach ($t in $Topics) {
    $want = '{0:D2}' -f $expected
    if ($t.Num -ne $want) { Add-Fail "numbering gap/dup near $($t.Num) (expected $want)" }
    $expected++
}
if ($script:Fails -eq 0) { Pass ("01..{0:D2} present, no gaps" -f $Count) }

# ---- B/C/F/G. per-topic checks ----------------------------------------------
Write-Host "B/C/F/G. Per-topic (README link, orchestrator group, sections, slug map)"
foreach ($t in $Topics) {
    # B: linked from README
    if (-not $ReadmeText.Contains("](./prompts/$($t.Name))")) {
        Add-Fail "$($t.Name) — not linked from README table"
    }

    # C: appears in an orchestrator theme group as "NN slug"
    if (-not $OrchText.Contains("$($t.Num) $($t.Slug)")) {
        Add-Fail "$($t.Name) — not in any orchestrator theme group ('$($t.Num) $($t.Slug)')"
    }

    $lines    = Get-Content -LiteralPath $t.File
    $fileText = Get-Content -LiteralPath $t.File -Raw

    # F: title + header reference + sections present and in order
    if ($lines[0] -notmatch "^# Audit 0*$([int]$t.Num):") {
        Add-Fail "$($t.Name) — title is not '# Audit $($t.Num): …'"
    }
    $head = ($lines | Select-Object -First 8) -join "`n"
    if ($head -notmatch '_conventions\.md') {
        Add-Fail "$($t.Name) — header block does not reference _conventions.md"
    }
    $prev = -1
    foreach ($sec in $RequiredSections) {
        $idx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].TrimEnd() -eq $sec) { $idx = $i; break }
        }
        if ($idx -lt 0) {
            Add-Fail "$($t.Name) — missing section '$sec'"
        } elseif ($idx -le $prev) {
            Add-Fail "$($t.Name) — section '$sec' is out of order"
        } else {
            $prev = $idx
        }
    }

    # G: declared output slug == filename slug
    $m = [regex]::Match($fileText, 'audit/[a-z0-9-]+\.md')
    $declared = if ($m.Success) { $m.Value } else { '' }
    if ($declared -ne "audit/$($t.Slug).md") {
        Add-Fail "$($t.Name) — declares '$declared' but filename slug is '$($t.Slug)' (driver mapping breaks)"
    }
}

# ---- B (reverse). 00 + _conventions are linked too --------------------------
foreach ($special in @('00-orchestrator.md', '_conventions.md')) {
    if (-not $ReadmeText.Contains("](./prompts/$special)")) {
        Add-Fail "$special — not linked from README"
    }
}

# ---- D. every README relative link resolves ---------------------------------
Write-Host "D. README relative links resolve"
$dBefore = $script:Fails
foreach ($lm in [regex]::Matches($ReadmeText, '\]\(\./([^)]+)\)')) {
    $rel = $lm.Groups[1].Value
    $target = ($rel -split '#')[0]
    if (-not (Test-Path -LiteralPath (Join-Path $ScriptDir $target))) {
        Add-Fail "README link does not resolve: ./$rel"
    }
}
if ($script:Fails -eq $dBefore) { Pass "all ./ links resolve" }

# ---- E. orchestrator range high number == max topic -------------------------
Write-Host "E. Orchestrator range line"
$rm = [regex]::Matches($OrchText, 'prompts/(\d\d)-\*\.md')
$rangeHi = if ($rm.Count -gt 0) { $rm[$rm.Count - 1].Groups[1].Value } else { '' }
$maxNum = $Topics[$Count - 1].Num
if ($rangeHi -eq $maxNum) {
    Pass "range ends at $rangeHi (matches highest topic)"
} else {
    $shown = if ($rangeHi) { $rangeHi } else { '?' }
    Add-Fail "range line ends at '$shown' but highest topic is '$maxNum'"
}

# ---- summary ----------------------------------------------------------------
Write-Host ""
if ($script:Fails -eq 0) {
    Write-Host "SUITE OK - all invariants hold ($Count topics)."
    exit 0
} else {
    Write-Host "SUITE INCONSISTENT - $($script:Fails) violation(s) above."
    exit 1
}
