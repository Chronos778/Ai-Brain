#Requires -Version 5.1

$HooksDir = Join-Path $env:USERPROFILE ".git-hooks"
$HookFile = Join-Path $HooksDir "post-commit"
$BrainSyncScript = "C:\Users\Maithil\AI-Brain\scripts\brain-sync.ps1"

Write-Host "Setting up global zero-touch Git hooks for AI-Brain..." -ForegroundColor Cyan

if (-not (Test-Path $HooksDir)) {
    New-Item -ItemType Directory -Path $HooksDir | Out-Null
    Write-Host "Created global hooks directory at $HooksDir"
}

# The bash script that Git will execute
$HookContent = @"
#!/bin/bash
# Global post-commit hook to trigger AI-Brain sync in the background
# This ensures that your context is always fresh.

# We run PowerShell detached and hidden so it doesn't interrupt your workflow
powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File $BrainSyncScript -NoPush'" &
"@

Set-Content -Path $HookFile -Value $HookContent -Encoding UTF8
Write-Host "Created post-commit hook at $HookFile"

# Make it executable (Git Bash)
try {
    # Using bash to chmod if possible
    bash -c "chmod +x `"$($HookFile -replace '\\','/')`"" 2>$null
} catch {}

# Configure git to use this directory globally
git config --global core.hooksPath $HooksDir
Write-Host "Configured Git globally to use core.hooksPath=$HooksDir" -ForegroundColor Green

Write-Host "`nSetup complete! Every time you commit in any project, AI-Brain will silently sync in the background." -ForegroundColor White
