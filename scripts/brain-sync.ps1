#Requires -Version 5.1
<#
.SYNOPSIS
    brain-sync - scan projects, update memory, sync VS Code, push to GitHub.
.USAGE
    brain-sync              # Full sync + push
    brain-sync -NoPush      # Sync without pushing
#>

param(
    [switch]$NoPush,
    [int]$ActiveDays = 14,
    [int]$ContextDays = 30,
    [int]$SkillStaleDays = 45
)

$ErrorActionPreference = "Stop"

# ─── Config ───────────────────────────────────────────────────────────
$BrainRoot    = "C:\Users\Maithil\AI-Brain"
$ProjectsRoot = "C:\Users\Maithil\Projects"
$MemoryDir    = Join-Path $BrainRoot "memory"
$SkillsDir    = Join-Path $BrainRoot "skills"
$ReviewDir    = Join-Path $SkillsDir "review"
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

function Get-MarkdownDatedEntries {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }

    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    $pattern = '(?ms)^###\s+(?<date>\d{4}-\d{2}-\d{2})\s+\|\s*(?<title>[^\r\n]+)\r?\n(?<body>.*?)(?=^###\s+\d{4}-\d{2}-\d{2}\s+\||\z)'
    $matches = [regex]::Matches($raw, $pattern)

    $entries = @()
    foreach ($m in $matches) {
        try {
            $entryDate = [DateTime]::ParseExact($m.Groups['date'].Value, 'yyyy-MM-dd', $null)
        } catch {
            continue
        }
        $entries += [PSCustomObject]@{
            Date = $entryDate
            DateText = $m.Groups['date'].Value
            Title = $m.Groups['title'].Value.Trim()
            Body = $m.Groups['body'].Value.Trim()
        }
    }
    return $entries
}

function Compress-MemoryFile {
    param(
        [string]$Path,
        [DateTime]$Cutoff,
        [int]$MaxEntries = 80
    )

    $entries = @(Get-MarkdownDatedEntries -Path $Path)
    if ($entries.Count -eq 0) {
        return [PSCustomObject]@{ Removed = 0; Duplicates = 0; Total = 0 }
    }

    $kept = @()
    $seen = @{}
    $duplicates = 0
    foreach ($e in ($entries | Sort-Object Date)) {
        if ($e.Date -lt $Cutoff) { continue }
        $fingerprint = (($e.Title + '|' + $e.Body) -replace '\s+', ' ').ToLower().Trim()
        if ($seen.ContainsKey($fingerprint)) {
            $duplicates++
            continue
        }
        $seen[$fingerprint] = $true
        $kept += $e
    }

    if ($kept.Count -gt $MaxEntries) {
        $kept = $kept | Sort-Object Date | Select-Object -Last $MaxEntries
    }

    $header = if ($Path.ToLower().EndsWith('decisions.md')) {
@"
# Decisions

Architecture choices, technology picks, and the reasoning behind them.
When future-you or an AI wonders "why was it done this way?" - the answer is here.

---
"@
    } else {
@"
# Learnings

Things I've figured out that are worth remembering. Not documentation - insights.
Each entry should save future-me at least 30 minutes.

---
"@
    }

    $lines = @($header)
    foreach ($e in ($kept | Sort-Object Date)) {
        $lines += ""
        $lines += "### $($e.DateText) | $($e.Title)"
        if ($e.Body) { $lines += $e.Body }
    }

    Set-Content -Path $Path -Value ($lines -join "`n") -Encoding UTF8

    return [PSCustomObject]@{
        Removed = [Math]::Max(0, $entries.Count - $kept.Count)
        Duplicates = $duplicates
        Total = $kept.Count
    }
}

function Get-Score {
    param([double]$Value)
    if ($Value -lt 0) { return 0 }
    if ($Value -gt 100) { return 100 }
    return [Math]::Round($Value, 0)
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

$contextCutoff = $Now.AddDays(-$ContextDays)
$decisionsPath = Join-Path $MemoryDir "decisions.md"
$learningsPath = Join-Path $MemoryDir "learnings.md"
$decisionStats = Compress-MemoryFile -Path $decisionsPath -Cutoff $contextCutoff
$learningStats = Compress-MemoryFile -Path $learningsPath -Cutoff $contextCutoff
if ($decisionStats.Removed -gt 0 -or $learningStats.Removed -gt 0) {
    Write-Log "Compressed memory: decisions -$($decisionStats.Removed), learnings -$($learningStats.Removed)"
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
            $changes += "$repoName - new work ($($techStack -join ', '))"
        }
    } else {
        $changes += "$repoName - new repo detected ($($techStack -join ', '))"
    }

    $status = if ($isActive) { "ACTIVE" } else { "inactive" }
    Write-Log "  [$status] $repoName - $($techStack -join ', ') - ${daysSince}d ago"
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

$priorityItems = @()
foreach ($p in ($activeProjects | Sort-Object daysSinceCommit)) {
    if ($p.lastCommit.message -and $p.lastCommit.message -ne ".") {
        $priorityItems += "**$($p.name)** - $($p.lastCommit.message)"
    } else {
        $priorityItems += "**$($p.name)** - keep momentum on current branch ($($p.branch))"
    }
}
$priorityItems = $priorityItems | Select-Object -First 5
if ($priorityItems.Count -gt 0) {
    $ctx += "## Top Current Priorities"
    $ctx += ""
    foreach ($item in $priorityItems) { $ctx += "- $item" }
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
        $ctx += "- **Branch**: $($p.branch) - last commit $daysAgo"
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
        $ctx += "- **$($p.name)** ($stack) - $([math]::Floor($p.daysSinceCommit))d ago"
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

# Check for skills pending review
$pendingReviews = @()
if (Test-Path $ReviewDir) {
    $pendingReviews = @(Get-ChildItem -Path $ReviewDir -Filter "*.md" -ErrorAction SilentlyContinue)
}
if ($pendingReviews.Count -gt 0) {
    $ctx += "## Skills Pending Review"
    $ctx += ""
    $ctx += "These skills were auto-detected but need real content. Ask the AI agent to fill them in."
    $ctx += ""
    foreach ($pf in $pendingReviews) {
        $content = Get-Content $pf.FullName -Raw -ErrorAction SilentlyContinue
        $detectedIn = ""
        if ($content -match 'Detected in: (.+)') { $detectedIn = " - used in $($Matches[1])" }
        $ctx += "- **$($pf.BaseName)**$detectedIn → ``skills/review/$($pf.Name)``"
    }
    $ctx += ""
}

# Quality metrics for maintaining a high-signal brain
$latestMemoryDate = $null
$decisionEntries = @(Get-MarkdownDatedEntries -Path $decisionsPath)
$learningEntries = @(Get-MarkdownDatedEntries -Path $learningsPath)
$allMemoryEntries = @($decisionEntries + $learningEntries)
if ($allMemoryEntries.Count -gt 0) {
    $latestMemoryDate = ($allMemoryEntries | Sort-Object Date -Descending | Select-Object -First 1).Date
}

$freshnessDays = if ($latestMemoryDate) { ($Now - $latestMemoryDate).TotalDays } else { 999 }
$activeRatio = if ($projects.Count -gt 0) { $activeProjects.Count / $projects.Count } else { 0 }
$contextFreshnessScore = Get-Score -Value (100 - ($freshnessDays * 2.2) + ($activeRatio * 20))

$decisionRaw = if (Test-Path $decisionsPath) { Get-Content $decisionsPath -Raw -Encoding UTF8 } else { "" }
$unresolvedDecisions = ([regex]::Matches($decisionRaw, '(?im)\b(todo|tbd|revisit)\b')).Count

$skillFiles = @(Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_index.md" -and $_.Name -ne "review-playbook.md" -and $_.Name -ne "testing-playbook.md" })
$staleCutoff = $Now.AddDays(-$SkillStaleDays)
$staleSkills = @($skillFiles | Where-Object { $_.LastWriteTime -lt $staleCutoff })

$knownStackRatio = if ($projects.Count -gt 0) { (@($projects | Where-Object { $_.techStack.Count -gt 0 }).Count) / $projects.Count } else { 0 }
$recentCommitRatio = if ($projects.Count -gt 0) { (@($projects | Where-Object { $_.daysSinceCommit -le $ActiveDays }).Count) / $projects.Count } else { 0 }
$activeProjectConfidence = Get-Score -Value ((($knownStackRatio * 0.6) + ($recentCommitRatio * 0.4)) * 100)

$duplicateInsights = $decisionStats.Duplicates + $learningStats.Duplicates

$ctx += "## Quality Metrics"
$ctx += ""
$ctx += "- **Context Freshness Score**: $contextFreshnessScore/100"
$ctx += "- **Duplicate Insight Count**: $duplicateInsights"
$ctx += "- **Unresolved Decision Markers**: $unresolvedDecisions"
$ctx += "- **Stale Skills**: $($staleSkills.Count) (older than $SkillStaleDays days)"
$ctx += "- **Active Project Confidence**: $activeProjectConfidence/100"
$ctx += ""

Set-Content -Path (Join-Path $MemoryDir "active-context.md") -Value ($ctx -join "`n") -Encoding UTF8
Write-Log "Updated active-context.md"

# ─── Auto-create skill stubs in review folder ─────────────────────────

if (-not (Test-Path $ReviewDir)) { New-Item -ItemType Directory -Path $ReviewDir -Force | Out-Null }

# Check both skills/ and skills/review/ so we don't recreate existing ones
$existingSkills = @()
$existingSkills += Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "_index.md" } | ForEach-Object { $_.BaseName.ToLower() }
$existingSkills += Get-ChildItem -Path $ReviewDir -Filter "*.md" -ErrorAction SilentlyContinue |
    ForEach-Object { $_.BaseName.ToLower() }

$newSkills = @()
foreach ($tech in $uniqueTech) {
    $slug = $tech.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
    if ($slug -notin $existingSkills) {
        $newSkills += $tech

        # Gather rich context for the AI to fill in later
        $usingProjects = ($projects | Where-Object { $tech -in $_.techStack } | ForEach-Object { $_.name }) -join ", "
        $detectedPackages = @()
        foreach ($p in ($projects | Where-Object { $tech -in $_.techStack })) {
            $pkgJson = Join-Path $p.path "package.json"
            if (Test-Path $pkgJson) {
                try {
                    $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
                    $allDeps = @()
                    if ($pkg.dependencies) { $allDeps += ($pkg.dependencies | Get-Member -MemberType NoteProperty).Name }
                    if ($pkg.devDependencies) { $allDeps += ($pkg.devDependencies | Get-Member -MemberType NoteProperty).Name }
                    $detectedPackages += $allDeps
                } catch {}
            }
            $reqTxt = Join-Path $p.path "requirements.txt"
            if (Test-Path $reqTxt) {
                try { $detectedPackages += (Get-Content $reqTxt | Where-Object { $_ -match '^[a-zA-Z]' } | ForEach-Object { ($_ -split '[=<>!]')[0].Trim() }) } catch {}
            }
        }
        $detectedPackages = $detectedPackages | Select-Object -Unique | Sort-Object
        $pkgLine = if ($detectedPackages.Count -gt 0) { "`n> Packages found: $($detectedPackages -join ', ')" } else { "" }

        $stub = @"
# $tech

> Detected in: $usingProjects
> Auto-created by brain-sync on $($Now.ToString('yyyy-MM-dd'))$pkgLine
>
> **STATUS: PENDING REVIEW** - Ask the AI agent to fill this with real patterns.
> Reference existing skills in skills/ for the expected format:
> How I Build → Expert Decisions → Mistakes That Cost Hours

## How I Build
- *(pending - AI will fill based on your projects and usage)*

## Expert Decisions
- *(pending - AI will research and add non-obvious choices)*

## Mistakes That Cost Hours
- *(pending - AI will add real anti-patterns)*
"@
        Set-Content -Path (Join-Path $ReviewDir "$slug.md") -Value $stub -Encoding UTF8
        Write-Log "  NEW SKILL: review/$slug.md (pending AI review)"
    }
}

# ─── Sync Editor Settings (VS Code + Antigravity) ───────────────────

$settingsTargets = @(
    [PSCustomObject]@{ Name = "VS Code"; Path = (Join-Path $env:APPDATA "Code\User\settings.json") },
    [PSCustomObject]@{ Name = "Antigravity"; Path = (Join-Path $env:APPDATA "Antigravity\User\settings.json") }
)

foreach ($settingsTarget in $settingsTargets) {
if (Test-Path $settingsTarget.Path) {
    function Build-InstructionBlock {
        param(
            [string]$SettingKey,
            [string[]]$Files
        )
        $unique = @($Files | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique)
        $rows = $unique | ForEach-Object { "        { `"file`": `"$($_.Replace('\', '/'))`" }" }
        $body = $rows -join ",`n"
        return "    `"$SettingKey`": [`n$body`n    ]"
    }

    $coreRules = Join-Path $BrainRoot "identity\core-rules.md"
    $preferences = Join-Path $BrainRoot "identity\preferences.md"
    $profile = Join-Path $BrainRoot "identity\profile.md"
    $style = Join-Path $BrainRoot "identity\style.md"
    $activeContext = Join-Path $MemoryDir "active-context.md"
    $decisions = Join-Path $MemoryDir "decisions.md"
    $learnings = Join-Path $MemoryDir "learnings.md"
    $skillIndex = Join-Path $SkillsDir "_index.md"
    $reviewPlaybook = Join-Path $SkillsDir "review-playbook.md"
    $testingPlaybook = Join-Path $SkillsDir "testing-playbook.md"

    $allSkillFiles = @()
    if (Test-Path $SkillsDir) {
        $allSkillFiles = @(Get-ChildItem $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.FullName })
    }

    $chatFiles = @($coreRules, $preferences, $profile, $style, $activeContext, $decisions, $learnings, $skillIndex)
    $codegenFiles = @($chatFiles + $allSkillFiles)
    $testFiles = @($coreRules, $preferences, $style, $skillIndex, $testingPlaybook)
    $reviewFiles = @($coreRules, $preferences, $style, $skillIndex, $reviewPlaybook)

    $blocks = @(
        (Build-InstructionBlock -SettingKey "github.copilot.chat.instructions" -Files $chatFiles),
        (Build-InstructionBlock -SettingKey "github.copilot.chat.codeGeneration.instructions" -Files $codegenFiles),
        (Build-InstructionBlock -SettingKey "github.copilot.chat.testGeneration.instructions" -Files $testFiles),
        (Build-InstructionBlock -SettingKey "github.copilot.chat.reviewSelection.instructions" -Files $reviewFiles)
    )

    $raw = Get-Content $settingsTarget.Path -Raw -Encoding UTF8
    foreach ($block in $blocks) {
        if ($block -match '"([^"]+)"') {
            $key = $Matches[1]
            $escapedKey = [regex]::Escape($key)
            if ($raw -match $escapedKey) {
                $raw = $raw -replace "(?s)    `"$escapedKey`"\s*:\s*\[.*?\]", $block
            } else {
                $raw = $raw -replace '\}(\s*)$', ",`n$block`n}`$1"
            }
        }
    }

    Set-Content -Path $settingsTarget.Path -Value $raw -Encoding UTF8 -NoNewline
    Write-Log "$($settingsTarget.Name) settings synced (chat/codegen/test/review instruction sets)"
}
}

# ─── Git commit + push ────────────────────────────────────────────────

Set-Location $BrainRoot

if (Test-Path (Join-Path $BrainRoot ".git")) {
    # Route through cmd so git stderr warnings are treated as plain output, not PowerShell errors.
    $gitAddOutput = @(cmd /d /c "git add -A 2>&1")
    $gitAddExit = $LASTEXITCODE

    if ($gitAddExit -ne 0) {
        $details = ($gitAddOutput -join [Environment]::NewLine).Trim()
        if (-not $details) { $details = "(no git output)" }
        throw "git add failed: $details"
    }
    $status = git status --porcelain 2>$null
    if ($status) {
        # Build meaningful commit message
        $parts = @()
        if ($changes.Count -gt 0) { $parts += "$($changes.Count) project updates" }
        if ($newSkills.Count -gt 0) { $parts += "new skills: $($newSkills -join ', ')" }
        $summary = if ($parts.Count -gt 0) { $parts -join ", " } else { "routine sync" }
        $commitMsg = "sync: $summary - $($Now.ToString('yyyy-MM-dd HH:mm'))"

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
                    Write-Log "WARNING: Push failed - $($_.Exception.Message)"
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
    Write-Host "New skills pending review:" -ForegroundColor Yellow
    foreach ($s in $newSkills) { Write-Host "  skills/review/$($s.ToLower() -replace '[^a-z0-9]','-').md" -ForegroundColor White }
}

# Show all pending reviews (including pre-existing ones)
$allPending = @()
if (Test-Path $ReviewDir) {
    $allPending = @(Get-ChildItem -Path $ReviewDir -Filter "*.md" -ErrorAction SilentlyContinue)
}
if ($allPending.Count -gt 0) {
    Write-Host ""
    Write-Host "Skills pending AI review ($($allPending.Count)):" -ForegroundColor Magenta
    foreach ($pf in $allPending) {
        Write-Host "  skills/review/$($pf.Name)" -ForegroundColor White
    }
    Write-Host "  → Ask Copilot: 'fill in the pending skill reviews'" -ForegroundColor DarkGray
}
