#Requires -Version 5.1
<#
.SYNOPSIS
    AI Brain Sync — scans your projects, updates memory, and pushes to GitHub.
.DESCRIPTION
    Scans C:\Users\Maithil\Projects for git repos with recent activity,
    detects tech stacks, updates active-projects.json and active-context.md,
    then commits and pushes the brain to GitHub.
.USAGE
    brain-sync                    # Full sync + git push
    brain-sync -NoPush            # Sync without pushing to GitHub
    brain-sync -Verbose           # Sync with detailed output
#>

param(
    [switch]$NoPush,
    [int]$ActiveDays = 14
)

$ErrorActionPreference = "Stop"

# ─── Configuration ────────────────────────────────────────────────────
$BrainRoot      = "C:\Users\Maithil\AI-Brain"
$ProjectsRoot   = "C:\Users\Maithil\Projects"
$MemoryDir      = Join-Path $BrainRoot "memory"
$SkillsDir      = Join-Path $BrainRoot "skills"
$LogDir         = Join-Path $BrainRoot "logs"
$ProjectsJson   = Join-Path $MemoryDir "active-projects.json"
$ContextMd      = Join-Path $MemoryDir "active-context.md"
$SkillsIndex    = Join-Path $SkillsDir "_index.md"
$DecisionsMd    = Join-Path $MemoryDir "decisions.md"
$LearningsMd    = Join-Path $MemoryDir "learnings.md"

$Now            = Get-Date
$LogFile        = Join-Path $LogDir "sync-$($Now.ToString('yyyy-MM-dd')).log"
$ActiveCutoff   = $Now.AddDays(-$ActiveDays)

# ─── Helpers ──────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

function Detect-TechStack {
    param([string]$RepoPath)
    $stack = @()

    $markers = @{
        "package.json"       = $null  # Will inspect contents
        "requirements.txt"   = "Python"
        "Pipfile"            = "Python"
        "pyproject.toml"     = "Python"
        "setup.py"           = "Python"
        "Cargo.toml"         = "Rust"
        "go.mod"             = "Go"
        "composer.json"      = "PHP"
        "Gemfile"            = "Ruby"
        "build.gradle"       = "Java"
        "pom.xml"            = "Java"
        "*.csproj"           = ".NET/C#"
        "*.fsproj"           = ".NET/F#"
        "Dockerfile"         = "Docker"
        "docker-compose.yml" = "Docker"
        "docker-compose.yaml"= "Docker"
        "terraform"          = "Terraform"
        "*.tf"               = "Terraform"
        "deno.json"          = "Deno"
        "bun.lockb"          = "Bun"
        "flutter"            = "Flutter"
        "pubspec.yaml"       = "Dart/Flutter"
    }

    foreach ($marker in $markers.Keys) {
        if ($marker -match '\*') {
            $found = Get-ChildItem -Path $RepoPath -Filter $marker -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        } else {
            $found = Test-Path (Join-Path $RepoPath $marker)
        }
        if ($found) {
            $tech = $markers[$marker]
            if ($tech -and $tech -notin $stack) {
                $stack += $tech
            }
        }
    }

    # Deep inspect package.json for JS/TS frameworks
    $pkgJson = Join-Path $RepoPath "package.json"
    if (Test-Path $pkgJson) {
        $stack += "Node.js"
        try {
            $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
            $allDeps = @()
            if ($pkg.dependencies) {
                $allDeps += ($pkg.dependencies | Get-Member -MemberType NoteProperty).Name
            }
            if ($pkg.devDependencies) {
                $allDeps += ($pkg.devDependencies | Get-Member -MemberType NoteProperty).Name
            }

            $jsFrameworks = @{
                "react"          = "React"
                "next"           = "Next.js"
                "vue"            = "Vue"
                "nuxt"           = "Nuxt"
                "svelte"         = "Svelte"
                "@angular/core"  = "Angular"
                "express"        = "Express"
                "fastify"        = "Fastify"
                "hono"           = "Hono"
                "tailwindcss"    = "Tailwind CSS"
                "typescript"     = "TypeScript"
                "prisma"         = "Prisma"
                "drizzle-orm"    = "Drizzle"
                "@trpc/server"   = "tRPC"
                "electron"       = "Electron"
                "vite"           = "Vite"
                "astro"          = "Astro"
                "solid-js"       = "SolidJS"
                "three"          = "Three.js"
            }

            foreach ($dep in $jsFrameworks.Keys) {
                if ($dep -in $allDeps -and $jsFrameworks[$dep] -notin $stack) {
                    $stack += $jsFrameworks[$dep]
                }
            }
        } catch {
            # Bad JSON, skip
        }
    }

    # Check for TypeScript config files
    if ((Test-Path (Join-Path $RepoPath "tsconfig.json")) -and "TypeScript" -notin $stack) {
        $stack += "TypeScript"
    }

    return $stack | Select-Object -Unique
}

function Get-RecentCommits {
    param([string]$RepoPath, [int]$Days = 7)
    try {
        $since = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd")
        $commits = git -C $RepoPath log --oneline --since=$since --no-merges 2>$null
        if ($commits) {
            return @($commits | Select-Object -First 10)
        }
    } catch {}
    return @()
}

# ─── Main ─────────────────────────────────────────────────────────────

# Ensure log directory exists
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

Write-Log "=== Brain Sync Started ==="
Write-Log "Scanning: $ProjectsRoot"
Write-Log "Active window: $ActiveDays days"

# Check if Projects folder exists
if (-not (Test-Path $ProjectsRoot)) {
    Write-Log "ERROR: Projects folder not found at $ProjectsRoot"
    Write-Log "Create the folder or update `$ProjectsRoot in this script."
    exit 1
}

# Find all git repos
$repos = Get-ChildItem -Path $ProjectsRoot -Directory -ErrorAction SilentlyContinue | Where-Object {
    Test-Path (Join-Path $_.FullName ".git")
}

Write-Log "Found $($repos.Count) git repositories"

$projects = @()
$allDetectedTech = @()

foreach ($repo in $repos) {
    $repoPath = $repo.FullName
    $repoName = $repo.Name

    Write-Log "Processing: $repoName"

    # Get last commit info
    try {
        $lastCommitDate = git -C $repoPath log -1 --format="%aI" 2>$null
        $lastCommitMsg  = git -C $repoPath log -1 --format="%s" 2>$null
        $currentBranch  = git -C $repoPath branch --show-current 2>$null
    } catch {
        Write-Log "  WARNING: Could not read git info for $repoName"
        continue
    }

    if (-not $lastCommitDate) {
        Write-Log "  Skipping $repoName — no commits"
        continue
    }

    $lastCommitDateTime = [DateTime]::Parse($lastCommitDate)
    $isActive = $lastCommitDateTime -gt $ActiveCutoff
    $daysSinceCommit = [math]::Round(($Now - $lastCommitDateTime).TotalDays, 1)

    # Detect tech stack
    $techStack = @(Detect-TechStack -RepoPath $repoPath)
    $allDetectedTech += $techStack

    # Get recent commits
    $recentCommits = @(Get-RecentCommits -RepoPath $repoPath)

    $project = @{
        name            = $repoName
        path            = $repoPath
        branch          = if ($currentBranch) { $currentBranch } else { "unknown" }
        lastCommit      = @{
            date    = $lastCommitDate
            message = if ($lastCommitMsg) { $lastCommitMsg } else { "" }
        }
        daysSinceCommit = $daysSinceCommit
        isActive        = $isActive
        techStack       = $techStack
        recentCommits   = $recentCommits
    }

    $projects += $project

    $statusLabel = if ($isActive) { "ACTIVE" } else { "inactive" }
    Write-Log "  [$statusLabel] branch=$($project.branch) stack=$($techStack -join ', ') lastCommit=${daysSinceCommit}d ago"
}

# Sort: active first, then by most recent commit
$projects = $projects | Sort-Object { $_.isActive } -Descending | Sort-Object { $_.daysSinceCommit }

# ─── Write active-projects.json ──────────────────────────────────────

$jsonOutput = @{
    lastSynced = $Now.ToString("yyyy-MM-ddTHH:mm:ssZ")
    totalRepos = $repos.Count
    activeRepos = ($projects | Where-Object { $_.isActive }).Count
    projects = $projects
} | ConvertTo-Json -Depth 5

Set-Content -Path $ProjectsJson -Value $jsonOutput -Encoding UTF8
Write-Log "Updated: active-projects.json ($($projects.Count) projects, $(($projects | Where-Object { $_.isActive }).Count) active)"

# ─── Generate active-context.md ──────────────────────────────────────

$activeProjects = $projects | Where-Object { $_.isActive }
$inactiveProjects = $projects | Where-Object { -not $_.isActive }

$contextLines = @()
$contextLines += "# Active Context"
$contextLines += ""
$contextLines += "> Auto-generated by brain-sync.ps1 — do not edit manually."
$contextLines += "> Last synced: $($Now.ToString('yyyy-MM-dd HH:mm'))"
$contextLines += ""

if ($activeProjects.Count -gt 0) {
    $contextLines += "## Currently Active Projects"
    $contextLines += ""
    foreach ($p in $activeProjects) {
        $stackStr = if ($p.techStack.Count -gt 0) { $p.techStack -join ", " } else { "unknown" }
        $commitMsg = if ($p.lastCommit.message) { $p.lastCommit.message } else { "no message" }
        $daysAgo = if ($p.daysSinceCommit -lt 1) { "today" } elseif ($p.daysSinceCommit -lt 2) { "yesterday" } else { "$([math]::Floor($p.daysSinceCommit))d ago" }
        $contextLines += "### $($p.name)"
        $contextLines += "- **Stack**: $stackStr"
        $contextLines += "- **Branch**: $($p.branch)"
        $contextLines += "- **Last commit**: `"$commitMsg`" ($daysAgo)"
        if ($p.recentCommits.Count -gt 0) {
            $contextLines += "- **Recent work**:"
            foreach ($c in $p.recentCommits | Select-Object -First 5) {
                $contextLines += "  - $c"
            }
        }
        $contextLines += ""
    }
} else {
    $contextLines += "## Currently Active Projects"
    $contextLines += "*(no active projects in the last $ActiveDays days)*"
    $contextLines += ""
}

if ($inactiveProjects.Count -gt 0) {
    $contextLines += "## Inactive Projects"
    $contextLines += ""
    foreach ($p in $inactiveProjects) {
        $stackStr = if ($p.techStack.Count -gt 0) { $p.techStack -join ", " } else { "unknown" }
        $contextLines += "- **$($p.name)** ($stackStr) — last touched $([math]::Floor($p.daysSinceCommit))d ago"
    }
    $contextLines += ""
}

# Pull in recent decisions
if (Test-Path $DecisionsMd) {
    $decContent = Get-Content $DecisionsMd -Raw
    $decEntries = [regex]::Matches($decContent, '### \d{4}-\d{2}-\d{2} \|[^\n]+\n[\s\S]*?(?=###|\z)')
    if ($decEntries.Count -gt 0) {
        $contextLines += "## Recent Decisions"
        $contextLines += ""
        $recentDecs = $decEntries | Select-Object -Last 5
        foreach ($dec in $recentDecs) {
            $firstLine = ($dec.Value -split "`n")[0].Trim()
            $contextLines += "- $firstLine"
        }
        $contextLines += ""
    }
}

# Pull in recent learnings
if (Test-Path $LearningsMd) {
    $learnContent = Get-Content $LearningsMd -Raw
    $learnEntries = [regex]::Matches($learnContent, '### \d{4}-\d{2}-\d{2} \|[^\n]+\n[\s\S]*?(?=###|\z)')
    if ($learnEntries.Count -gt 0) {
        $contextLines += "## Recent Learnings"
        $contextLines += ""
        $recentLearns = $learnEntries | Select-Object -Last 5
        foreach ($learn in $recentLearns) {
            $firstLine = ($learn.Value -split "`n")[0].Trim()
            $contextLines += "- $firstLine"
        }
        $contextLines += ""
    }
}

# All detected tech across projects
$uniqueTech = $allDetectedTech | Select-Object -Unique | Sort-Object
if ($uniqueTech.Count -gt 0) {
    $contextLines += "## Tech Stack Across All Projects"
    $contextLines += $uniqueTech -join ", "
    $contextLines += ""
}

Set-Content -Path $ContextMd -Value ($contextLines -join "`n") -Encoding UTF8
Write-Log "Updated: active-context.md"

# ─── Update skills/_index.md (detect undocumented tech) ─────────────

$existingSkillFiles = Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "_index.md" } |
    ForEach-Object { $_.BaseName.ToLower() }

$undocumentedTech = @()
foreach ($tech in $uniqueTech) {
    $techSlug = $tech.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
    if ($techSlug -notin $existingSkillFiles) {
        $undocumentedTech += $tech
    }
}

# Build the skills index
$indexLines = @()
$indexLines += "# Skills Registry"
$indexLines += ""
$indexLines += "> Auto-updated by brain-sync.ps1 when new tech is detected."
$indexLines += "> Last synced: $($Now.ToString('yyyy-MM-dd HH:mm'))"
$indexLines += ""
$indexLines += "## Registered Skills"
$indexLines += ""
$indexLines += "| Skill | File | Status |"
$indexLines += "|-------|------|--------|"

if ($existingSkillFiles.Count -gt 0) {
    foreach ($skillFile in $existingSkillFiles) {
        $indexLines += "| $skillFile | ``$skillFile.md`` | documented |"
    }
} else {
    $indexLines += "| *(none yet)* | | |"
}

$indexLines += ""
$indexLines += "## Detected Tech (Not Yet Documented)"
$indexLines += ""
if ($undocumentedTech.Count -gt 0) {
    $indexLines += "> Consider creating skill files for tech you use frequently:"
    $indexLines += ""
    foreach ($tech in $undocumentedTech) {
        $techSlug = $tech.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
        $indexLines += "- **$tech** → create ``skills/$techSlug.md``"
    }
} else {
    $indexLines += "*(all detected tech has skill files)*"
}

Set-Content -Path $SkillsIndex -Value ($indexLines -join "`n") -Encoding UTF8
Write-Log "Updated: skills/_index.md ($($existingSkillFiles.Count) documented, $($undocumentedTech.Count) undocumented)"

# ─── Git commit and push ─────────────────────────────────────────────

Set-Location $BrainRoot

# Check if this is a git repo
if (-not (Test-Path (Join-Path $BrainRoot ".git"))) {
    Write-Log "WARNING: AI-Brain is not a git repo yet. Skipping git operations."
    Write-Log "Run: git init && git remote add origin <your-repo-url>"
} else {
    git add -A 2>$null
    $status = git status --porcelain 2>$null
    if ($status) {
        $commitMsg = "brain-sync: $($Now.ToString('yyyy-MM-dd HH:mm'))"
        git commit -m $commitMsg 2>$null
        Write-Log "Committed: $commitMsg"

        if (-not $NoPush) {
            $remotes = git remote 2>$null
            if ($remotes) {
                try {
                    git push origin main 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        git push origin master 2>$null
                    }
                    Write-Log "Pushed to GitHub"
                } catch {
                    Write-Log "WARNING: Push failed — $($_.Exception.Message)"
                }
            } else {
                Write-Log "WARNING: No git remote configured. Run: git remote add origin <url>"
            }
        } else {
            Write-Log "Skipped push (--NoPush flag)"
        }
    } else {
        Write-Log "No changes to commit"
    }
}

Write-Log "=== Brain Sync Complete ==="
Write-Log "Active: $(($projects | Where-Object { $_.isActive }).Count) | Inactive: $(($projects | Where-Object { -not $_.isActive }).Count) | Total: $($projects.Count)"
