#Requires -Version 5.1
<#
.SYNOPSIS
    brain-learn — add insights to your brain, connected to skills.
.DESCRIPTION
    Adds a learning to memory/learnings.md and optionally to the related skill file.
    Categorizes and connects new knowledge to existing skills.
.USAGE
    brain-learn react "Zustand selectors prevent unnecessary re-renders"
    brain-learn general "Always seed random in ML pipelines for reproducibility"
    brain-learn --list                # Show all learnings
    brain-learn --recent              # Show last 10 learnings
    brain-learn --decide <project> <decision>  # Add a decision instead
#>

param(
    [Parameter(Position = 0)]
    [string]$SkillOrFlag,
    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Content,
    [switch]$List,
    [switch]$Recent,
    [switch]$Decide
)

$ErrorActionPreference = "Stop"

$BrainRoot   = "C:\Users\Maithil\AI-Brain"
$SkillsDir   = Join-Path $BrainRoot "skills"
$MemoryDir   = Join-Path $BrainRoot "memory"
$LearnFile   = Join-Path $MemoryDir "learnings.md"
$DecideFile  = Join-Path $MemoryDir "decisions.md"
$Today       = (Get-Date).ToString("yyyy-MM-dd")

# ─── Skill mapping ───────────────────────────────────────────────────
# Maps keywords to skill file slugs for auto-categorization

$SkillKeywords = @{
    "react"       = @("react", "component", "hook", "useState", "useEffect", "jsx", "tsx", "zustand", "tanstack", "radix", "framer-motion")
    "typescript"  = @("typescript", "ts", "type", "interface", "zod", "discriminated", "branded", "satisfies", "generic")
    "next-js"     = @("next", "nextjs", "app-router", "server-component", "server-action", "rsc", "ssr", "isr", "vercel")
    "tailwind-css" = @("tailwind", "css", "cva", "cn()", "dark-mode", "responsive", "utility")
    "three-js"    = @("three", "r3f", "3d", "webgl", "drei", "canvas", "mesh", "gsap", "camera")
    "node-js"     = @("node", "npm", "event-loop", "stream", "worker", "fs", "path")
    "express"     = @("express", "middleware", "route", "controller", "api", "endpoint", "cors", "helmet")
    "firebase"    = @("firebase", "firestore", "cloud-function", "auth", "storage", "security-rule")
    "python"      = @("python", "flask", "fastapi", "pandas", "numpy", "pydantic", "pytest", "ml")
    "vite"        = @("vite", "rollup", "hmr", "import.meta")
    "bun"         = @("bun", "bunx", "bun.lockb")
    "frontend-design" = @("design", "accessibility", "a11y", "animation", "typography", "color", "layout", "ux", "ui")
}

function Find-RelatedSkills {
    param([string]$Text)
    $textLower = $Text.ToLower()
    $matches = @()
    foreach ($skill in $SkillKeywords.Keys) {
        foreach ($keyword in $SkillKeywords[$skill]) {
            if ($textLower -match [regex]::Escape($keyword)) {
                if ($skill -notin $matches) { $matches += $skill }
                break
            }
        }
    }
    return $matches
}

function Show-Learnings {
    param([int]$Count = 0)
    if (-not (Test-Path $LearnFile)) {
        Write-Host "No learnings yet." -ForegroundColor DarkGray
        return
    }
    $content = Get-Content $LearnFile -Raw
    $entries = [regex]::Matches($content, '### \d{4}-\d{2}-\d{2} \|[^\n]+\n([\s\S]*?)(?=\n### |\z)')
    if ($entries.Count -eq 0) {
        Write-Host "No learnings recorded yet." -ForegroundColor DarkGray
        return
    }
    $toShow = if ($Count -gt 0) { $entries | Select-Object -Last $Count } else { $entries }
    foreach ($e in $toShow) {
        $header = ($e.Value -split "`n")[0].Trim()
        $body = ($e.Value -split "`n" | Select-Object -Skip 1) -join "`n"
        Write-Host $header -ForegroundColor Cyan
        if ($body.Trim()) { Write-Host $body.Trim() -ForegroundColor White }
        Write-Host ""
    }
    Write-Host "$($entries.Count) total learnings" -ForegroundColor DarkGray
}

# ─── Handle flags ─────────────────────────────────────────────────────

if ($List -or $SkillOrFlag -eq "--list") {
    Show-Learnings
    exit 0
}

if ($Recent -or $SkillOrFlag -eq "--recent") {
    Show-Learnings -Count 10
    exit 0
}

# ─── Add a Decision ──────────────────────────────────────────────────

if ($Decide -or $SkillOrFlag -eq "--decide") {
    if ($Decide) {
        $project = $SkillOrFlag
        $decisionText = $Content -join " "
    } else {
        # --decide was first arg, project is second
        $project = if ($Content.Count -gt 0) { $Content[0] } else { "general" }
        $decisionText = if ($Content.Count -gt 1) { ($Content | Select-Object -Skip 1) -join " " } else { "" }
    }

    if (-not $decisionText) {
        Write-Host "Usage: brain-learn --decide <project> <what you decided>" -ForegroundColor Yellow
        Write-Host "  Example: brain-learn --decide myportfolio 'Switched to GSAP for camera timelines because Framer Motion lacks ScrollTrigger'" -ForegroundColor DarkGray
        exit 0
    }

    $entry = @"

### $Today | $project | $decisionText
"@
    Add-Content -Path $DecideFile -Value $entry -Encoding UTF8
    Write-Host "Decision recorded: $project" -ForegroundColor Green
    Write-Host "  $decisionText" -ForegroundColor White

    # Find related skills
    $related = Find-RelatedSkills -Text "$project $decisionText"
    if ($related.Count -gt 0) {
        Write-Host "  Related skills: $($related -join ', ')" -ForegroundColor DarkGray
    }
    exit 0
}

# ─── Add a Learning ──────────────────────────────────────────────────

if (-not $SkillOrFlag) {
    Write-Host "brain-learn — add insights to your brain" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Add a learning:" -ForegroundColor White
    Write-Host '  brain-learn react "Zustand selectors prevent unnecessary re-renders"'
    Write-Host '  brain-learn general "Always validate env vars at startup with Zod"'
    Write-Host ""
    Write-Host "Add a decision:" -ForegroundColor White
    Write-Host '  brain-learn --decide myportfolio "Chose GSAP over Framer for camera"'
    Write-Host ""
    Write-Host "View learnings:" -ForegroundColor White
    Write-Host "  brain-learn --list         # All learnings"
    Write-Host "  brain-learn --recent       # Last 10"
    Write-Host ""
    Write-Host "Available skills:" -ForegroundColor White
    $SkillKeywords.Keys | Sort-Object | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    exit 0
}

$learningText = $Content -join " "
if (-not $learningText) {
    Write-Host 'Usage: brain-learn <skill> "what you learned"' -ForegroundColor Yellow
    Write-Host '  Example: brain-learn react "useTransition wraps non-urgent updates to keep UI responsive"' -ForegroundColor DarkGray
    exit 0
}

$topic = $SkillOrFlag

# Auto-detect related skills from the learning text
$specifiedSkill = $topic.ToLower() -replace '[^a-z0-9]', '-'
$relatedSkills = Find-RelatedSkills -Text "$topic $learningText"
if ($specifiedSkill -notin $relatedSkills -and (Test-Path (Join-Path $SkillsDir "$specifiedSkill.md"))) {
    $relatedSkills = @($specifiedSkill) + $relatedSkills
}

# Add to learnings.md
$skillTag = if ($relatedSkills.Count -gt 0) { " [$($relatedSkills -join ', ')]" } else { "" }
$entry = @"

### $Today | $topic$skillTag
$learningText
"@

Add-Content -Path $LearnFile -Value $entry -Encoding UTF8
Write-Host "Learning recorded: $topic" -ForegroundColor Green
Write-Host "  $learningText" -ForegroundColor White

if ($relatedSkills.Count -gt 0) {
    Write-Host "  Connected to: $($relatedSkills -join ', ')" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Run brain-sync to commit and push." -ForegroundColor DarkGray
