#Requires -Version 5.1
<#!
.SYNOPSIS
    brain-adapt - audit markdown for tool-specific terms and optionally apply safe removals.
.USAGE
    brain-adapt
    brain-adapt -Apply
#>

param(
    [switch]$Apply,
    [string]$BrainRoot = "C:\Users\Maithil\AI-Brain",
    [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BrainRoot)) {
    throw "Brain root not found: $BrainRoot"
}

if (-not $ReportPath) {
    $ReportPath = Join-Path $BrainRoot "memory\migration-audit.md"
}

$knownClaudeSpecificPaths = @(
    "skills\configure-ecc",
    "skills\security-scan",
    "skills\autonomous-loops",
    "skills\nanoclaw-repl",
    "skills\skill-stocktake"
)

# Keep marker list concise and high-signal.
$markerPatterns = @(
    "\.claude",
    "CLAUDE\.md",
    "(^|\\s)/plugin(\\s|$|:)",
    "everything-claude-code",
    "ANTHROPIC_API_KEY",
    "from anthropic import",
    "claude-sonnet",
    "claude-opus"
)

if ($Apply) {
    foreach ($relativePath in $knownClaudeSpecificPaths) {
        $fullPath = Join-Path $BrainRoot $relativePath
        if (Test-Path $fullPath) {
            Remove-Item -Path $fullPath -Force -Recurse
        }
    }
}

$mdFiles = Get-ChildItem -Path $BrainRoot -Recurse -File -Filter "*.md" |
    Where-Object {
        $_.FullName -notmatch "\\.git\\" -and
        $_.FullName -notmatch "\\logs\\" -and
        $_.FullName -ne $ReportPath
    } |
    Sort-Object FullName

$findings = @()

foreach ($file in $mdFiles) {
    $relativePath = $file.FullName.Substring($BrainRoot.Length).TrimStart('\\')
    $lines = Get-Content -Path $file.FullName -Encoding UTF8

    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($pattern in $markerPatterns) {
            if ($lines[$i] -match $pattern) {
                $findings += [PSCustomObject]@{
                    File = $relativePath
                    Line = ($i + 1)
                    Pattern = $pattern
                    Snippet = $lines[$i].Trim()
                }
            }
        }
    }
}

$report = @()
$report += "# Migration Audit"
$report += ""
$report += "> Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
$report += "> Brain root: $BrainRoot"
$report += "> Apply mode: $Apply"
$report += ""
$report += "## High-Confidence Deletes"
$report += ""
foreach ($relativePath in $knownClaudeSpecificPaths) {
    $existsNow = Test-Path (Join-Path $BrainRoot $relativePath)
    $state = if ($existsNow) { "present" } else { "removed-or-missing" }
    $report += "- $relativePath - $state"
}
$report += ""
$report += "## Marker Findings"
$report += ""
$report += "- Total matches: $($findings.Count)"
$report += ""

if ($findings.Count -gt 0) {
    $byFile = $findings | Group-Object File | Sort-Object Name
    foreach ($group in $byFile) {
        $report += "### $($group.Name)"
        foreach ($item in ($group.Group | Sort-Object Line)) {
            $report += "- L$($item.Line) [$($item.Pattern)]: $($item.Snippet)"
        }
        $report += ""
    }
}

Set-Content -Path $ReportPath -Value ($report -join "`n") -Encoding UTF8

Write-Host "Audit written: $ReportPath"
Write-Host "Findings: $($findings.Count)"
if ($Apply) {
    Write-Host "Applied known deletions: $($knownClaudeSpecificPaths.Count)"
}
