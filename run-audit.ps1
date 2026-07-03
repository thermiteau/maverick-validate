<#
.SYNOPSIS
  run-audit.ps1 - drive the full AI Code Sanity Check suite over a target repo.
  Windows port of run-audit.sh. Runs on Windows PowerShell 5.1 and PowerShell 7+.

.DESCRIPTION
  WHY THIS EXISTS
    The audit is 27 heavy topic prompts. If one agent tries to run them all in a
    single session it will exhaust its context window and silently skip, truncate,
    or shallow-do topics. This driver removes that failure mode structurally:

      1. ISOLATION  - each topic prompt runs in its OWN fresh agent process, so
                      context spent on topic N can never starve topic N+1.
      2. PROOF      - a topic counts as done only when its audit/<slug>.md report
                      actually exists and looks valid. The filesystem is the
                      ledger, not the model's memory.
      3. LOUD FAIL  - if any expected report is missing at the end, the script
                      exits non-zero and names the gaps. "Complete" is verified,
                      never assumed.
      4. RESUMABLE  - re-running skips topics already produced, so a crash or a
                      rate-limit halfway through never forces a full redo.

.PARAMETER Target
  Repo to audit (required). Reports land in <Target>\audit\.

.PARAMETER Agent
  claude | codex | custom   (default: claude)

.PARAMETER Only
  Space-separated topic numbers to run, e.g. "14 23"   (default: all)

.PARAMETER Retries
  Attempts per topic before giving up   (default: 2)

.PARAMETER Force
  Re-run topics even if a report already exists.

.PARAMETER NoScorecard
  Skip the final aggregated SCORECARD.md step.

.PARAMETER DryRun
  Print the plan and exit without invoking any agent.

.EXAMPLE
  .\run-audit.ps1 -Target C:\code\my-app
  .\run-audit.ps1 -Target ..\my-app -Agent codex -Only "14 23 24"
  .\run-audit.ps1 -Target ..\my-app -DryRun

.NOTES
  If PowerShell blocks the script ("running scripts is disabled"), launch it with:
      powershell -ExecutionPolicy Bypass -File .\run-audit.ps1 -Target ...
  or (PowerShell 7):
      pwsh -File .\run-audit.ps1 -Target ...

  The agent command is defined in Invoke-Agent below - the ONE place to edit if
  your CLI/version needs different flags. -Agent custom with $env:AUDIT_CMD lets
  you plug in any tool that reads the prompt on stdin.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Target,
    [string] $Agent = 'claude',
    [string] $Only = '',
    [int]    $Retries = 2,
    [switch] $Force,
    [switch] $NoScorecard,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# Non-ASCII in the prompts (em-dashes, arrows, curly quotes) must survive the
# pipe into the CLI's stdin. Windows PowerShell 5.1 defaults $OutputEncoding to
# ASCII, which would replace those characters with '?'. Force UTF-8 (no BOM).
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch { }

function Fail([string]$Message) {
    [Console]::Error.WriteLine("ERROR: $Message")
    exit 1
}

# --------------------------------------------------------------------------- #
# Resolve where the suite lives (this script's own directory), independent of cwd
# --------------------------------------------------------------------------- #
$ScriptDir   = $PSScriptRoot
$PromptsDir  = Join-Path $ScriptDir 'prompts'
$Conventions = Join-Path $PromptsDir '_conventions.md'

if (-not (Test-Path -LiteralPath $Target))      { Fail "-Target '$Target' does not exist." }
if (-not (Test-Path -LiteralPath $Target -PathType Container)) { Fail "-Target '$Target' is not a directory." }
if (-not (Test-Path -LiteralPath $PromptsDir))  { Fail "prompts\ not found next to this script ($PromptsDir)." }
if (-not (Test-Path -LiteralPath $Conventions)) { Fail "prompts\_conventions.md not found." }
if ($Retries -lt 1) { Fail "-Retries must be >= 1." }

# Absolutise the target and derive output locations
$Target   = (Resolve-Path -LiteralPath $Target).Path
$AuditDir = Join-Path $Target 'audit'
$Ledger   = Join-Path $AuditDir '.run-audit.log'
$IsWin    = ($env:OS -eq 'Windows_NT')

# --------------------------------------------------------------------------- #
# THE agent invocation. Edit here if your CLI needs different flags.
# Contract: pipe the full prompt to the tool on STDIN, run non-interactively with
# the working directory set to $Target, allow it to read the repo + write files
# under audit\, and return the tool's exit code (non-zero on hard failure).
# --------------------------------------------------------------------------- #
function Invoke-Agent {
    param([string] $Message, [string] $LogPath)

    Push-Location -LiteralPath $Target
    try {
        switch ($Agent) {
            'claude' {
                # Headless "print" mode. --permission-mode acceptEdits lets it
                # write the report; for fully unattended runs you may instead need
                # --dangerously-skip-permissions (audits run read-only shell like
                # git log / findstr / npm audit).
                $Message | & claude -p --permission-mode acceptEdits 2>&1 |
                    Out-File -FilePath $LogPath -Append -Encoding utf8
            }
            'codex' {
                $Message | & codex exec --full-auto - 2>&1 |
                    Out-File -FilePath $LogPath -Append -Encoding utf8
            }
            'custom' {
                if (-not $env:AUDIT_CMD) { throw "custom agent requires the AUDIT_CMD environment variable." }
                if ($IsWin) {
                    $Message | & $env:ComSpec '/c' $env:AUDIT_CMD 2>&1 |
                        Out-File -FilePath $LogPath -Append -Encoding utf8
                } else {
                    $Message | & '/bin/sh' '-c' $env:AUDIT_CMD 2>&1 |
                        Out-File -FilePath $LogPath -Append -Encoding utf8
                }
            }
            default { throw "unknown -Agent '$Agent' (claude | codex | custom)." }
        }
        $code = $LASTEXITCODE
        if ($null -eq $code) { $code = 0 }
        return $code
    }
    catch {
        ($_ | Out-String) | Out-File -FilePath $LogPath -Append -Encoding utf8
        return 1
    }
    finally {
        Pop-Location
    }
}

# --------------------------------------------------------------------------- #
# Build the topic list: every prompts\NN-*.md except the orchestrator.
# Mapping is deterministic: NN-<slug>.md  ->  audit\<slug>.md
# --------------------------------------------------------------------------- #
# @() forces an array so .Count is reliable even with a single match (PS 5.1).
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

if ($Topics.Count -eq 0) { Fail "no topic prompts found in $PromptsDir." }

# Optional subset filter -> set of ints (accepts "7" or "07")
$OnlySet = @()
if ($Only.Trim().Length -gt 0) {
    $OnlySet = @($Only -split '\s+' | Where-Object { $_ } | ForEach-Object { [int]$_ })
}
function Test-Selected([string]$Num) {
    if ($OnlySet.Count -eq 0) { return $true }
    return ($OnlySet -contains [int]$Num)
}

# A report is "valid" if it exists, is non-trivially sized, and carries the Score
# line from the report template (present even for N/A verdicts).
function Test-ReportValid([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    if ((Get-Item -LiteralPath $Path).Length -lt 200)       { return $false }
    $content = Get-Content -LiteralPath $Path -Raw
    if ($content -notmatch '\*\*Score:\*\*')                { return $false }
    return $true
}

# --------------------------------------------------------------------------- #
# Plan / dry-run
# --------------------------------------------------------------------------- #
Write-Host "AI Code Sanity Check - full-suite driver"
Write-Host "  suite     : $PromptsDir"
Write-Host "  target    : $Target"
Write-Host "  agent     : $Agent"
Write-Host "  reports   : $AuditDir\<topic>.md"
if ($OnlySet.Count -gt 0) { Write-Host "  subset    : $Only" }
Write-Host "  topics    : $($Topics.Count) available"
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN - planned actions:"
    foreach ($t in $Topics) {
        if (-not (Test-Selected $t.Num)) { continue }
        $out = Join-Path $AuditDir "$($t.Slug).md"
        if ((-not $Force) -and (Test-ReportValid $out)) {
            Write-Host ("  [skip ] {0} (report already valid)" -f $t.Slug)
        } else {
            Write-Host ("  [run  ] {0} -> audit\{0}.md" -f $t.Slug)
        }
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $AuditDir | Out-Null
Set-Content -LiteralPath $Ledger -Value '' -Encoding utf8
function Log([string]$Message) {
    Write-Host $Message
    Add-Content -LiteralPath $Ledger -Value $Message -Encoding utf8
}

# --------------------------------------------------------------------------- #
# Run each selected topic in its own fresh agent process
# --------------------------------------------------------------------------- #
$Done = New-Object System.Collections.Generic.List[string]
$Skipped = New-Object System.Collections.Generic.List[string]
$Failed = New-Object System.Collections.Generic.List[string]
$ConvText = Get-Content -LiteralPath $Conventions -Raw

foreach ($t in $Topics) {
    if (-not (Test-Selected $t.Num)) { continue }
    $out = Join-Path $AuditDir "$($t.Slug).md"

    if ((-not $Force) -and (Test-ReportValid $out)) {
        Log "[$($t.Num)] $($t.Slug) - SKIP (valid report exists; use -Force to redo)"
        $Skipped.Add($t.Slug); continue
    }

    $promptText = Get-Content -LiteralPath $t.File -Raw
    $slug = $t.Slug
    $promptName = $t.Name

    $attempt = 1; $ok = $false
    while ($attempt -le $Retries) {
        Log "[$($t.Num)] $slug - running (attempt $attempt/$Retries)..."

        # Compose a fully self-contained prompt: driver preamble + shared
        # conventions + the topic prompt. No inter-file reads required, so each
        # process is hermetic. File contents are inserted via variables, so any
        # backticks/$ inside them are treated literally.
        $msg = @"
You are running ONE topic of the AI Code Sanity Check audit against the
repository in your current working directory ($Target).

Rules for this run:
- This is a READ-ONLY audit of the code. The ONLY file you may create or modify
  is audit/$slug.md (create the audit/ directory if needed).
- Do NOT attempt any other audit topic. Do exactly this one and then stop.
- Follow the shared conventions and the topic prompt below. Even if the topic is
  Not Applicable to this repo, you must still WRITE audit/$slug.md stating N/A
  and why - an absent file is treated as a failed run.

===== SHARED CONVENTIONS (_conventions.md) =====
$ConvText

===== TOPIC PROMPT ($promptName) =====
$promptText
"@

        # Proof over exit code: the report file is the source of truth. Accept the
        # attempt if a valid report exists, whatever the CLI's exit status.
        $code = Invoke-Agent -Message $msg -LogPath $Ledger
        if (Test-ReportValid $out) { $ok = $true; break }
        Log "[$($t.Num)] $slug - attempt $attempt produced no valid report (agent exit $code)."
        $attempt++
    }

    if ($ok) {
        Log "[$($t.Num)] $slug - DONE (audit/$slug.md)"
        $Done.Add($slug)
    } else {
        Log "[$($t.Num)] $slug - FAILED after $Retries attempt(s)."
        $Failed.Add($slug)
    }
}

# --------------------------------------------------------------------------- #
# Completeness gate - the whole point of this script
# --------------------------------------------------------------------------- #
Write-Host ""
Write-Host "===================== RUN SUMMARY ====================="
Write-Host ("  done    : {0}" -f $Done.Count)
Write-Host ("  skipped : {0} (already valid)" -f $Skipped.Count)
Write-Host ("  failed  : {0}" -f $Failed.Count)

# Verify EVERY selected topic now has a valid report, however it got there.
$Missing = New-Object System.Collections.Generic.List[string]
foreach ($t in $Topics) {
    if (-not (Test-Selected $t.Num)) { continue }
    if (-not (Test-ReportValid (Join-Path $AuditDir "$($t.Slug).md"))) { $Missing.Add($t.Slug) }
}

if ($Missing.Count -gt 0) {
    Write-Host ""
    Write-Host "INCOMPLETE - no report produced for:"
    foreach ($m in $Missing) { Write-Host "  - $m" }
    Write-Host "Re-run to fill the gaps (existing reports are kept): .\run-audit.ps1 -Target `"$Target`""
    exit 1
}

Write-Host "  ALL SELECTED TOPICS HAVE A VALID REPORT [OK]"

# --------------------------------------------------------------------------- #
# Optional: aggregate into SCORECARD.md (safe - it only reads the short reports)
# --------------------------------------------------------------------------- #
if ((-not $NoScorecard) -and ($OnlySet.Count -eq 0)) {
    Write-Host ""
    Write-Host "Aggregating audit\SCORECARD.md ..."
    $orch = Get-Content -LiteralPath (Join-Path $PromptsDir '00-orchestrator.md') -Raw
    $agg = @"
Every per-topic report has been written under audit/ in your current working
directory. Read all of audit/*.md (they are short) and aggregate them into
audit/SCORECARD.md following the "Aggregate into audit/SCORECARD.md" section of
the orchestrator prompt below. Write ONLY audit/SCORECARD.md. Do not re-run any
topic audit.

===== ORCHESTRATOR (aggregation spec) =====
$orch
"@
    $code = Invoke-Agent -Message $agg -LogPath $Ledger
    if ($code -eq 0 -and (Test-Path -LiteralPath (Join-Path $AuditDir 'SCORECARD.md'))) {
        Write-Host "  SCORECARD.md written [OK]"
    } else {
        Write-Host "  SCORECARD.md step did not complete - topic reports are still valid."
        Write-Host "  You can retry aggregation, or build the scorecard by hand from audit\*.md."
        exit 1
    }
}

Write-Host ""
Write-Host "Done. Reports: $AuditDir\   (run log: $Ledger)"
