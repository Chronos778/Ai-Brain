#Requires -Version 5.1
<#
.SYNOPSIS
    brain-sync — scan projects, update memory, sync VS Code, push to GitHub.
.USAGE
    brain-sync              # Full sync + push
    brain-sync -NoPush      # Sync without pushing
#>

param(
    [switch]$NoPush,
    [int]$ActiveDays = 14
)

$ErrorActionPreference = "Stop"

# ─── Config ───────────────────────────────────────────────────────────
$BrainRoot    = "C:\Users\Maithil\AI-Brain"
$ProjectsRoot = "C:\Users\Maithil\Projects"
$MemoryDir    = Join-Path $BrainRoot "memory"
$SkillsDir    = Join-Path $BrainRoot "skills"
$LogDir       = Join-Path $BrainRoot "logs"
$Now          = Get-Date
$LogFile      = Join-Path $LogDir "sync-$($Now.ToString('yyyy-MM-dd')).log"
$ActiveCutoff = $Now.AddDays(-$ActiveDays)

# ─── Helpers ──────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message)
    $line = "[$((Get-Date).ToString('HH:mm:ss'))] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

function Detect-TechStack {
    param([string]$RepoPath)
    $stack = @()

    # File-based markers
    $markers = @{
        "requirements.txt" = "Python"; "Pipfile" = "Python"; "pyproject.toml" = "Python"
        "Cargo.toml" = "Rust"; "go.mod" = "Go"; "composer.json" = "PHP"
        "Gemfile" = "Ruby"; "pubspec.yaml" = "Dart/Flutter"
        "Dockerfile" = "Docker"; "docker-compose.yml" = "Docker"
        "bun.lockb" = "Bun"; "deno.json" = "Deno"
    }
    foreach ($file in $markers.Keys) {
        if (Test-Path (Join-Path $RepoPath $file)) {
            $tech = $markers[$file]
            if ($tech -notin $stack) { $stack += $tech }
        }
    }

    # Glob markers
    @("*.csproj", "*.tf") | ForEach-Object {
        $found = Get-ChildItem -Path $RepoPath -Filter $_ -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $tech = if ($_ -eq "*.csproj") { ".NET/C#" } else { "Terraform" }
            if ($tech -notin $stack) { $stack += $tech }
        }
    }

    # Deep inspect package.json
    $pkgJson = Join-Path $RepoPath "package.json"
    if (Test-Path $pkgJson) {
        $stack += "Node.js"
        try {
            $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
            $allDeps = @()
            if ($pkg.dependencies) { $allDeps += ($pkg.dependencies | Get-Member -MemberType NoteProperty).Name }
            if ($pkg.devDependencies) { $allDeps += ($pkg.devDependencies | Get-Member -MemberType NoteProperty).Name }

            $jsMap = @{
                "react" = "React"; "next" = "Next.js"; "vue" = "Vue"; "svelte" = "Svelte"
                "@angular/core" = "Angular"; "express" = "Express"; "fastify" = "Fastify"
                "hono" = "Hono"; "tailwindcss" = "Tailwind CSS"; "typescript" = "TypeScript"
                "prisma" = "Prisma"; "drizzle-orm" = "Drizzle"; "@trpc/server" = "tRPC"
                "vite" = "Vite"; "three" = "Three.js"; "astro" = "Astro"
            }
            foreach ($dep in $jsMap.Keys) {
                if ($dep -in $allDeps -and $jsMap[$dep] -notin $stack) { $stack += $jsMap[$dep] }
            }
        } catch {}
    }

    if ((Test-Path (Join-Path $RepoPath "tsconfig.json")) -and "TypeScript" -notin $stack) {
        $stack += "TypeScript"
    }

    return $stack | Select-Object -Unique
}

# ─── Main ─────────────────────────────────────────────────────────────

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

Write-Log "=== Brain Sync ==="
Write-Log "Scanning $ProjectsRoot ($ActiveDays day window)"

if (-not (Test-Path $ProjectsRoot)) {
    Write-Log "ERROR: Projects folder not found at $ProjectsRoot"
    exit 1
}

# Find all git repos
$gitDirs = Get-ChildItem -Path $ProjectsRoot -Recurse -Directory -Filter ".git" -Force -ErrorAction SilentlyContinue
$repos = $gitDirs | ForEach-Object {
    [PSCustomObject]@{
        FullName     = $_.Parent.FullName
        RelativeName = $_.Parent.FullName.Replace("$ProjectsRoot\", "").Replace("\", "/")
    }
} | Sort-Object RelativeName

# Detect folders with no git
$topLevelFolders = Get-ChildItem -Path $ProjectsRoot -Directory -ErrorAction SilentlyContinue
$repoTopFolders = $repos | ForEach-Object { ($_.RelativeName -split "/")[0] } | Select-Object -Unique
$noGitFolders = $topLevelFolders | Where-Object { $_.Name -notin $repoTopFolders }
foreach ($folder in $noGitFolders) { Write-Log "  NO GIT: $($folder.Name)" }

Write-Log "Found $($repos.Count) repos"

$projects = @()
$allDetectedTech = @()
$changes = @()  # Track what changed since last sync

# Load previous state for diff
$prevProjectsPath = Join-Path $MemoryDir "active-projects.json"
$prevProjects = @{}
if (Test-Path $prevProjectsPath) {
    try {
        $prevData = Get-Content $prevProjectsPath -Raw | ConvertFrom-Json
        foreach ($p in $prevData.projects) { $prevProjects[$p.name] = $p }
    } catch {}
}

foreach ($repo in $repos) {
    $repoPath = $repo.FullName
    $repoName = $repo.RelativeName

    try {
        $lastCommitDate = git -C $repoPath log -1 --format="%aI" 2>$null
        $lastCommitMsg  = git -C $repoPath log -1 --format="%s" 2>$null
        $currentBranch  = git -C $repoPath branch --show-current 2>$null
    } catch { continue }

    if (-not $lastCommitDate) { continue }

    $lastCommitDateTime = [DateTime]::Parse($lastCommitDate)
    $isActive = $lastCommitDateTime -gt $ActiveCutoff
    $daysSince = [math]::Round(($Now - $lastCommitDateTime).TotalDays, 1)

    $techStack = @(Detect-TechStack -RepoPath $repoPath)
    $allDetectedTech += $techStack

    # Get meaningful recent commits (skip "." and merge commits)
    $recentCommits = @()
    try {
        $since = (Get-Date).AddDays(-$ActiveDays).ToString("yyyy-MM-dd")
        $raw = git -C $repoPath log --oneline --since=$since --no-merges 2>$null
        if ($raw) {
            $recentCommits = @($raw | Where-Object { $_ -notmatch '^\w+ \.$' } | Select-Object -First 5)
        }
    } catch {}

    $project = @{
        name = $repoName; path = $repoPath; branch = if ($currentBranch) { $currentBranch } else { "unknown" }
        lastCommit = @{ date = $lastCommitDate; message = if ($lastCommitMsg) { $lastCommitMsg } else { "" } }
        daysSinceCommit = $daysSince; isActive = $isActive
        techStack = $techStack; recentCommits = $recentCommits
    }
    $projects += $project

    # Detect meaningful changes since last sync
    if ($prevProjects.ContainsKey($repoName)) {
        $prev = $prevProjects[$repoName]
        $prevDays = if ($prev.daysSinceCommit) { $prev.daysSinceCommit } else { 999 }
        if ($daysSince -lt $prevDays -and $isActive) {
            $changes += "$repoName — new work ($($techStack -join ', '))"
        }
    } else {
        $changes += "$repoName — new repo detected ($($techStack -join ', '))"
    }

    $status = if ($isActive) { "ACTIVE" } else { "inactive" }
    Write-Log "  [$status] $repoName — $($techStack -join ', ') — ${daysSince}d ago"
}

$projects = $projects | Sort-Object { $_.daysSinceCommit }

# ─── Write active-projects.json ──────────────────────────────────────

$jsonOutput = @{
    lastSynced = $Now.ToString("yyyy-MM-ddTHH:mm:ssZ")
    totalRepos = $repos.Count
    activeRepos = ($projects | Where-Object { $_.isActive }).Count
    projects = $projects
} | ConvertTo-Json -Depth 5

Set-Content -Path $prevProjectsPath -Value $jsonOutput -Encoding UTF8

# ─── Generate active-context.md ──────────────────────────────────────

$activeProjects = $projects | Where-Object { $_.isActive }
$inactiveProjects = $projects | Where-Object { -not $_.isActive }

$ctx = @()
$ctx += "# Active Context"
$ctx += ""
$ctx += "> Auto-generated by brain-sync. Last synced: $($Now.ToString('yyyy-MM-dd HH:mm'))"
$ctx += ""

# What changed since last sync
if ($changes.Count -gt 0) {
    $ctx += "## What Changed"
    $ctx += ""
    foreach ($c in $changes) { $ctx += "- $c" }
    $ctx += ""
}

if ($activeProjects.Count -gt 0) {
    $ctx += "## Active Projects"
    $ctx += ""
    foreach ($p in $activeProjects) {
        $stack = if ($p.techStack.Count -gt 0) { $p.techStack -join ", " } else { "unknown" }
        $msg = if ($p.lastCommit.message -and $p.lastCommit.message -ne ".") { $p.lastCommit.message } else { "" }
        $daysAgo = if ($p.daysSinceCommit -lt 1) { "today" } elseif ($p.daysSinceCommit -lt 2) { "yesterday" } else { "$([math]::Floor($p.daysSinceCommit))d ago" }

        $ctx += "### $($p.name)"
        $ctx += "- **Stack**: $stack"
        $ctx += "- **Branch**: $($p.branch) — last commit $daysAgo"
        if ($msg) { $ctx += "- **Working on**: $msg" }
        if ($p.recentCommits.Count -gt 0) {
            $ctx += "- **Recent**:"
            foreach ($c in $p.recentCommits) { $ctx += "  - $c" }
        }
        $ctx += ""
    }
}

if ($inactiveProjects.Count -gt 0) {
    $ctx += "## Paused Projects"
    $ctx += ""
    foreach ($p in $inactiveProjects) {
        $stack = if ($p.techStack.Count -gt 0) { $p.techStack -join ", " } else { "unknown" }
        $ctx += "- **$($p.name)** ($stack) — $([math]::Floor($p.daysSinceCommit))d ago"
    }
    $ctx += ""
}

# Pull recent decisions
$decMd = Join-Path $MemoryDir "decisions.md"
if (Test-Path $decMd) {
    $decContent = Get-Content $decMd -Raw
    $decEntries = [regex]::Matches($decContent, '### \d{4}-\d{2}-\d{2} \|[^\n]+')
    if ($decEntries.Count -gt 0) {
        $ctx += "## Recent Decisions"
        $ctx += ""
        $decEntries | Select-Object -Last 5 | ForEach-Object { $ctx += "- $($_.Value.Trim())" }
        $ctx += ""
    }
}

# Pull recent learnings
$learnMd = Join-Path $MemoryDir "learnings.md"
if (Test-Path $learnMd) {
    $learnContent = Get-Content $learnMd -Raw
    $learnEntries = [regex]::Matches($learnContent, '### \d{4}-\d{2}-\d{2} \|[^\n]+')
    if ($learnEntries.Count -gt 0) {
        $ctx += "## Recent Learnings"
        $ctx += ""
        $learnEntries | Select-Object -Last 5 | ForEach-Object { $ctx += "- $($_.Value.Trim())" }
        $ctx += ""
    }
}

# Tech summary
$uniqueTech = $allDetectedTech | Select-Object -Unique | Sort-Object
if ($uniqueTech.Count -gt 0) {
    $ctx += "## Full Tech Stack"
    $ctx += $uniqueTech -join ", "
    $ctx += ""
}

Set-Content -Path (Join-Path $MemoryDir "active-context.md") -Value ($ctx -join "`n") -Encoding UTF8
Write-Log "Updated active-context.md"

# ─── Auto-create skill stubs for new tech ─────────────────────────────

$existingSkills = Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "_index.md" } | ForEach-Object { $_.BaseName.ToLower() }

$newSkills = @()
foreach ($tech in $uniqueTech) {
    $slug = $tech.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
    if ($slug -notin $existingSkills) {
        $newSkills += $tech
        $usingProjects = ($projects | Where-Object { $tech -in $_.techStack } | ForEach-Object { $_.name }) -join ", "
        $stub = @"
# $tech

> Detected in: $usingProjects
> Auto-created by brain-sync on $($Now.ToString('yyyy-MM-dd'))

## How I Use It
- *(add your patterns here)*

## Expert Decisions
- *(add the non-obvious choices that save time)*

## Mistakes That Cost Hours
- *(add real anti-patterns from experience)*
"@
        Set-Content -Path (Join-Path $SkillsDir "$slug.md") -Value $stub -Encoding UTF8
        Write-Log "  NEW SKILL: $slug.md (stub created — customize it)"
    }
}

# ─── Sync VS Code Settings ───────────────────────────────────────────

$settingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
if (Test-Path $settingsPath) {
    $brainFiles = @()

    # Identity
    $identityDir = Join-Path $BrainRoot "identity"
    if (Test-Path $identityDir) {
        Get-ChildItem $identityDir -Filter "*.md" | Sort-Object Name | ForEach-Object { $brainFiles += $_.FullName }
    }

    # Memory (.md only)
    if (Test-Path $MemoryDir) {
        Get-ChildItem $MemoryDir -Filter "*.md" | Sort-Object Name | ForEach-Object { $brainFiles += $_.FullName }
    }

    # Skills
    if (Test-Path $SkillsDir) {
        $idx = Join-Path $SkillsDir "_index.md"
        if (Test-Path $idx) { $brainFiles += $idx }
        Get-ChildItem $SkillsDir -Filter "*.md" | Where-Object { $_.Name -ne "_index.md" } | Sort-Object Name | ForEach-Object { $brainFiles += $_.FullName }
    }

    $instructions = $brainFiles | ForEach-Object {
        "        { `"file`": `"$($_.Replace('\', '/'))`" }"
    }
    $block = $instructions -join ",`n"
    $newBlock = "    `"github.copilot.chat.codeGeneration.instructions`": [`n$block`n    ]"

    $raw = Get-Content $settingsPath -Raw -Encoding UTF8
    if ($raw -match 'github\.copilot\.chat\.codeGeneration\.instructions') {
        $raw = $raw -replace '(?s)    "github\.copilot\.chat\.codeGeneration\.instructions"\s*:\s*\[.*?\]', $newBlock
    } else {
        $raw = $raw -replace '\}(\s*)$', ",`n$newBlock`n}`$1"
    }
    Set-Content -Path $settingsPath -Value $raw -Encoding UTF8 -NoNewline
    Write-Log "VS Code settings synced ($($brainFiles.Count) files)"
}

# ─── Git commit + push ────────────────────────────────────────────────

Set-Location $BrainRoot

if (Test-Path (Join-Path $BrainRoot ".git")) {
    git add -A 2>$null
    $status = git status --porcelain 2>$null
    if ($status) {
        # Build meaningful commit message
        $parts = @()
        if ($changes.Count -gt 0) { $parts += "$($changes.Count) project updates" }
        if ($newSkills.Count -gt 0) { $parts += "new skills: $($newSkills -join ', ')" }
        $summary = if ($parts.Count -gt 0) { $parts -join ", " } else { "routine sync" }
        $commitMsg = "sync: $summary — $($Now.ToString('yyyy-MM-dd HH:mm'))"

        git commit -m $commitMsg 2>$null
        Write-Log "Committed: $commitMsg"

        if (-not $NoPush) {
            $remotes = git remote 2>$null
            if ($remotes) {
                try {
                    git push origin main 2>$null
                    if ($LASTEXITCODE -ne 0) { git push origin master 2>$null }
                    Write-Log "Pushed to GitHub"
                } catch {
                    Write-Log "WARNING: Push failed — $($_.Exception.Message)"
                }
            }
        }
    } else {
        Write-Log "No changes to commit"
    }
}

# ─── Summary ──────────────────────────────────────────────────────────

$activeCount = ($projects | Where-Object { $_.isActive }).Count
Write-Log "=== Done === Active: $activeCount | Paused: $($projects.Count - $activeCount) | Total: $($projects.Count)"

if ($changes.Count -gt 0) {
    Write-Host ""
    Write-Host "Changes detected:" -ForegroundColor Cyan
    foreach ($c in $changes) { Write-Host "  $c" -ForegroundColor White }
}
if ($newSkills.Count -gt 0) {
    Write-Host ""
    Write-Host "New skill stubs created (customize them):" -ForegroundColor Yellow
    foreach ($s in $newSkills) { Write-Host "  skills/$($s.ToLower() -replace '[^a-z0-9]','-').md" -ForegroundColor White }
}
