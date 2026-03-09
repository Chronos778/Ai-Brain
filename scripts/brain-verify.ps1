#Requires -Version 5.1
<#!
.SYNOPSIS
    brain-verify - verify AI-Brain instruction wiring for VS Code and Antigravity.
.USAGE
    brain-verify
#>

$ErrorActionPreference = "Stop"

$BrainRoot = "C:\Users\Maithil\AI-Brain"

$settingsTargets = @(
    [PSCustomObject]@{ Name = "VS Code"; Path = (Join-Path $env:APPDATA "Code\User\settings.json") },
    [PSCustomObject]@{ Name = "Antigravity"; Path = (Join-Path $env:APPDATA "Antigravity\User\settings.json") }
)

$keys = @(
    "github.copilot.chat.instructions",
    "github.copilot.chat.codeGeneration.instructions",
    "github.copilot.chat.testGeneration.instructions",
    "github.copilot.chat.reviewSelection.instructions"
)

$expectedCore = @(
    (Join-Path $BrainRoot "identity\core-rules.md"),
    (Join-Path $BrainRoot "identity\preferences.md"),
    (Join-Path $BrainRoot "identity\profile.md"),
    (Join-Path $BrainRoot "identity\style.md"),
    (Join-Path $BrainRoot "memory\active-context.md"),
    (Join-Path $BrainRoot "memory\decisions.md"),
    (Join-Path $BrainRoot "memory\learnings.md"),
    (Join-Path $BrainRoot "skills\_index.md")
)

function Normalize-Path {
    param([string]$PathText)
    if (-not $PathText) { return "" }
    return ($PathText -replace '/', '\\').ToLower()
}

$anyFailure = $false

foreach ($target in $settingsTargets) {
    Write-Host "" 
    Write-Host "=== $($target.Name) ===" -ForegroundColor Cyan

    if (-not (Test-Path $target.Path)) {
        Write-Host "FAIL: settings.json not found: $($target.Path)" -ForegroundColor Red
        $anyFailure = $true
        continue
    }

    $raw = Get-Content -Path $target.Path -Raw -Encoding UTF8
    try {
        $cfg = ConvertFrom-Json -InputObject $raw
    } catch {
        Write-Host "FAIL: invalid JSON in $($target.Path)" -ForegroundColor Red
        $anyFailure = $true
        continue
    }

    foreach ($k in $keys) {
        $entries = @($cfg.$k)
        if ($entries.Count -eq 0) {
            Write-Host "FAIL: $k -> 0 entries" -ForegroundColor Red
            $anyFailure = $true
            continue
        }

        $missing = @()
        foreach ($e in $entries) {
            $fp = if ($e -and $e.file) { [string]$e.file } else { "" }
            if (-not $fp) {
                $missing += "(entry without file)"
                continue
            }
            $expanded = [Environment]::ExpandEnvironmentVariables($fp)
            if (-not (Test-Path $expanded)) { $missing += $fp }
        }

        if ($missing.Count -gt 0) {
            Write-Host "WARN: $k -> $($entries.Count) entries, $($missing.Count) missing files" -ForegroundColor Yellow
            $missing | Select-Object -First 3 | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }
        } else {
            Write-Host "PASS: $k -> $($entries.Count) entries" -ForegroundColor Green
        }
    }

    $chatSet = @($cfg."github.copilot.chat.instructions")
    $chatFilesNorm = @($chatSet | ForEach-Object { if ($_.file) { Normalize-Path -PathText $_.file } })
    $missingCore = @()
    foreach ($core in $expectedCore) {
        $coreNorm = Normalize-Path -PathText $core
        if ($coreNorm -notin $chatFilesNorm) { $missingCore += $core }
    }

    if ($missingCore.Count -gt 0) {
        Write-Host "WARN: chat core set missing $($missingCore.Count) expected AI-Brain files" -ForegroundColor Yellow
        $missingCore | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }
    } else {
        Write-Host "PASS: chat core set includes all expected AI-Brain files" -ForegroundColor Green
    }
}

Write-Host ""
if ($anyFailure) {
    Write-Host "RESULT: FAIL (fix settings issues and run brain-sync)" -ForegroundColor Red
    exit 1
}

Write-Host "RESULT: PASS (instruction mapping looks healthy)" -ForegroundColor Green
exit 0
