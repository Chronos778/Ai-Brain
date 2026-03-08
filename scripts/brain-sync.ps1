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

function Scan-ProjectsForTech {
    <#
    .SYNOPSIS
        Deeply scans all projects that use a given tech and extracts real patterns.
    #>
    param(
        [string]$Tech,
        [array]$Projects
    )

    $relevantProjects = $Projects | Where-Object { $Tech -in $_.techStack }
    $findings = @{
        libraries     = @()
        configPatterns = @()
        fileStructure = @()
        codePatterns  = @()
        devDeps       = @()
    }

    foreach ($proj in $relevantProjects) {
        $rp = $proj.path

        # ── Read package.json deeply ──
        $pkgPath = Join-Path $rp "package.json"
        if (Test-Path $pkgPath) {
            try {
                $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
                $deps = @()
                $devD = @()
                if ($pkg.dependencies) { $deps = ($pkg.dependencies | Get-Member -MemberType NoteProperty).Name }
                if ($pkg.devDependencies) { $devD = ($pkg.devDependencies | Get-Member -MemberType NoteProperty).Name }

                # Categorize libs relevant to this tech
                switch ($Tech) {
                    "React" {
                        $reactLibs = $deps | Where-Object { $_ -match 'react|redux|zustand|jotai|recoil|mobx|framer|@radix|@tanstack|@clerk|cmdk|vaul|sonner|lucide|recharts' }
                        $findings.libraries += $reactLibs
                        # Detect state management
                        if ("zustand" -in $deps) { $findings.codePatterns += "Uses Zustand for state management" }
                        if ($deps -match "redux") { $findings.codePatterns += "Uses Redux for state management" }
                        if ("jotai" -in $deps) { $findings.codePatterns += "Uses Jotai for state management" }
                        if ("@tanstack/react-query" -in $deps) { $findings.codePatterns += "Uses TanStack Query for data fetching" }
                        if ("react-hook-form" -in $deps) { $findings.codePatterns += "Uses React Hook Form for forms" }
                        if ("react-router-dom" -in $deps) { $findings.codePatterns += "Uses React Router for routing" }
                        if ("framer-motion" -in $deps -or "motion" -in $deps) { $findings.codePatterns += "Uses Framer Motion for animations" }
                        if ($deps -match "@radix") { $findings.codePatterns += "Uses Radix UI primitives for accessible components" }
                        if ($deps -match "@clerk") { $findings.codePatterns += "Uses Clerk for authentication" }
                        if ("recharts" -in $deps) { $findings.codePatterns += "Uses Recharts for data visualization" }
                    }
                    "Three.js" {
                        $threeLibs = $deps | Where-Object { $_ -match 'three|@react-three|drei|fiber|postprocessing|cannon|rapier' }
                        $findings.libraries += $threeLibs
                        if ("@react-three/fiber" -in $deps) { $findings.codePatterns += "Uses React Three Fiber (R3F) — declarative Three.js" }
                        if ("@react-three/drei" -in $deps) { $findings.codePatterns += "Uses Drei helpers for common 3D patterns" }
                        if ("gsap" -in $deps -or "@gsap/react" -in $deps) { $findings.codePatterns += "Uses GSAP for advanced animations alongside Three.js" }
                    }
                    "Next.js" {
                        # Check app router vs pages
                        if (Test-Path (Join-Path $rp "app")) { $findings.codePatterns += "Uses App Router (app/ directory)" }
                        if (Test-Path (Join-Path $rp "pages")) { $findings.codePatterns += "Uses Pages Router (pages/ directory)" }
                        # Read next.config
                        $nextConfigs = @("next.config.ts", "next.config.js", "next.config.mjs")
                        foreach ($nc in $nextConfigs) {
                            $ncPath = Join-Path $rp $nc
                            if (Test-Path $ncPath) {
                                $ncContent = Get-Content $ncPath -Raw
                                if ($ncContent -match "reactStrictMode:\s*false") { $findings.configPatterns += "Strict mode disabled" }
                                if ($ncContent -match "images") { $findings.configPatterns += "Custom image configuration" }
                                if ($ncContent -match "env:") { $findings.configPatterns += "Environment variables configured in next.config" }
                                if ($ncContent -match "i18n") { $findings.configPatterns += "Internationalization configured" }
                            }
                        }
                        if ("@next/third-parties" -in $deps) { $findings.codePatterns += "Uses @next/third-parties for analytics/scripts" }
                    }
                    "TypeScript" {
                        $tsPath = Join-Path $rp "tsconfig.json"
                        if (Test-Path $tsPath) {
                            try {
                                $ts = Get-Content $tsPath -Raw | ConvertFrom-Json
                                $co = $ts.compilerOptions
                                if ($co.strict -eq $true) { $findings.configPatterns += "Strict mode enabled" }
                                if ($co.target) { $findings.configPatterns += "Target: $($co.target)" }
                                if ($co.paths) {
                                    $aliases = ($co.paths | Get-Member -MemberType NoteProperty).Name -join ", "
                                    $findings.configPatterns += "Path aliases: $aliases"
                                }
                                if ($co.jsx) { $findings.configPatterns += "JSX: $($co.jsx)" }
                            } catch {}
                        }
                        if ("zod" -in $deps) { $findings.codePatterns += "Uses Zod for runtime type validation" }
                    }
                    "Tailwind CSS" {
                        $twConfigs = @("tailwind.config.ts", "tailwind.config.js")
                        foreach ($tw in $twConfigs) {
                            $twPath = Join-Path $rp $tw
                            if (Test-Path $twPath) {
                                $twContent = Get-Content $twPath -Raw
                                if ($twContent -match "fontFamily") { $findings.configPatterns += "Custom font families configured" }
                                if ($twContent -match "colors") { $findings.configPatterns += "Custom color palette via CSS variables" }
                                if ($twContent -match "plugins") { $findings.configPatterns += "Tailwind plugins used" }
                            }
                        }
                        if ("tailwind-merge" -in $deps) { $findings.codePatterns += "Uses tailwind-merge for class deduplication" }
                        if ("class-variance-authority" -in $deps) { $findings.codePatterns += "Uses CVA (class-variance-authority) for component variants" }
                        if ("tailwindcss-animate" -in $deps -or "tailwindcss-animate" -in $devD) { $findings.codePatterns += "Uses tailwindcss-animate for animation utilities" }
                        if ("clsx" -in $deps) { $findings.codePatterns += "Uses clsx for conditional class names" }
                    }
                    "Express" {
                        $expressLibs = $deps | Where-Object { $_ -match 'express|cors|helmet|morgan|dotenv|rate-limit|cookie|session|passport|jwt|bcrypt|multer|libsql|prisma|drizzle|mongoose|pg|mysql' }
                        $findings.libraries += $expressLibs
                        if ("cors" -in $deps) { $findings.codePatterns += "CORS enabled" }
                        if ("dotenv" -in $deps) { $findings.codePatterns += "Environment variables via dotenv" }
                        if ("express-rate-limit" -in $deps) { $findings.codePatterns += "Rate limiting configured" }
                        if ("@libsql/client" -in $deps) { $findings.codePatterns += "Uses LibSQL/Turso for database" }
                        if ("helmet" -in $deps) { $findings.codePatterns += "Security headers via Helmet" }
                    }
                    "Node.js" {
                        # General Node patterns
                        if ("dotenv" -in $deps) { $findings.codePatterns += "Uses dotenv for env management" }
                        if ($pkg.type -eq "module") { $findings.codePatterns += "ES modules (type: module)" }
                        if ($pkg.scripts) {
                            $scripts = ($pkg.scripts | Get-Member -MemberType NoteProperty).Name
                            if ("dev" -in $scripts) { $findings.codePatterns += "Has dev script" }
                            if ("build" -in $scripts) { $findings.codePatterns += "Has build script" }
                            if ("lint" -in $scripts) { $findings.codePatterns += "Has lint script" }
                        }
                    }
                    "Vite" {
                        $viteConfigs = @("vite.config.ts", "vite.config.js")
                        foreach ($vc in $viteConfigs) {
                            $vcPath = Join-Path $rp $vc
                            if (Test-Path $vcPath) {
                                $vcContent = Get-Content $vcPath -Raw
                                if ($vcContent -match "@vitejs/plugin-react") { $findings.codePatterns += "Using Vite React plugin" }
                                if ($vcContent -match "proxy") { $findings.configPatterns += "Dev proxy configured" }
                            }
                        }
                    }
                    "Python" {
                        $reqPath = Join-Path $rp "requirements.txt"
                        if (Test-Path $reqPath) {
                            $reqs = Get-Content $reqPath | Where-Object { $_ -match '^\w' } | ForEach-Object { ($_ -split '[>=<]')[0].Trim().ToLower() }
                            $findings.libraries += $reqs
                            if ("flask" -in $reqs) { $findings.codePatterns += "Uses Flask web framework" }
                            if ("django" -in $reqs) { $findings.codePatterns += "Uses Django web framework" }
                            if ("fastapi" -in $reqs) { $findings.codePatterns += "Uses FastAPI" }
                            if ("tensorflow" -in $reqs -or "tensorflow-cpu" -in $reqs) { $findings.codePatterns += "Uses TensorFlow for ML" }
                            if ("pytorch" -in $reqs -or "torch" -in $reqs) { $findings.codePatterns += "Uses PyTorch for ML" }
                            if ("numpy" -in $reqs) { $findings.codePatterns += "Uses NumPy for numerical computing" }
                            if ("flask-cors" -in $reqs) { $findings.codePatterns += "CORS enabled via Flask-CORS" }
                            if ("gunicorn" -in $reqs) { $findings.codePatterns += "Uses Gunicorn for production serving" }
                            if ("pillow" -in $reqs) { $findings.codePatterns += "Uses Pillow for image processing" }
                            if ("scipy" -in $reqs) { $findings.codePatterns += "Uses SciPy for scientific computing" }
                        }
                        # Check for pyproject.toml
                        $pyProjPath = Join-Path $rp "pyproject.toml"
                        if (Test-Path $pyProjPath) { $findings.configPatterns += "Uses pyproject.toml for project config" }
                    }
                    "Bun" {
                        if (Test-Path (Join-Path $rp "bun.lockb")) { $findings.codePatterns += "Uses Bun as package manager (bun.lockb detected)" }
                        if (Test-Path (Join-Path $rp "bunfig.toml")) {
                            $findings.configPatterns += "Custom Bun configuration via bunfig.toml"
                        }
                    }
                }

                $findings.devDeps += $devD

            } catch {}
        }

        # ── Detect file structure patterns ──
        $srcDir = $null
        if (Test-Path (Join-Path $rp "src")) { $srcDir = Join-Path $rp "src" }
        elseif (Test-Path (Join-Path $rp "app")) { $srcDir = Join-Path $rp "app" }

        if ($srcDir) {
            $topDirs = Get-ChildItem $srcDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
            if ($topDirs.Count -gt 0) {
                $findings.fileStructure += "Project '$($proj.name)' structure: $($topDirs -join ', ')"
            }
        }

        # ── Detect component patterns (React/Next) ──
        if ($Tech -in @("React", "Next.js")) {
            $compDir = Get-ChildItem $rp -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "components" } | Select-Object -First 1
            if ($compDir) {
                $compFiles = Get-ChildItem $compDir.FullName -File -Filter "*.tsx" -ErrorAction SilentlyContinue
                if (-not $compFiles) { $compFiles = Get-ChildItem $compDir.FullName -File -Filter "*.jsx" -ErrorAction SilentlyContinue }
                if ($compFiles) {
                    $sampleComp = $compFiles | Select-Object -First 3
                    foreach ($cf in $sampleComp) {
                        $content = Get-Content $cf.FullName -Raw -ErrorAction SilentlyContinue
                        if ($content) {
                            if ($content -match "export default function") { $findings.codePatterns += "Uses default function exports for components" }
                            elseif ($content -match "export function") { $findings.codePatterns += "Uses named function exports for components" }
                            elseif ($content -match "export const.*=.*=>") { $findings.codePatterns += "Uses arrow function exports for components" }
                            if ($content -match "use client") { $findings.codePatterns += "Uses 'use client' directive (client components)" }
                            if ($content -match "use server") { $findings.codePatterns += "Uses 'use server' directive (server actions)" }
                        }
                    }
                }
            }
        }
    }

    # Deduplicate everything
    $findings.libraries = @($findings.libraries | Select-Object -Unique | Sort-Object)
    $findings.configPatterns = @($findings.configPatterns | Select-Object -Unique)
    $findings.fileStructure = @($findings.fileStructure | Select-Object -Unique)
    $findings.codePatterns = @($findings.codePatterns | Select-Object -Unique)

    return $findings
}

function Build-SkillContent {
    param(
        [string]$Tech,
        [string]$ProjectsList,
        [hashtable]$Findings
    )

    $lines = @()
    $lines += "# $Tech"
    $lines += ""
    $lines += "> Auto-generated by brain-sync from scanning your actual projects."
    $lines += "> Used in: $ProjectsList"
    $lines += "> Last scanned: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    $lines += ""

    # Code patterns
    if ($Findings.codePatterns.Count -gt 0) {
        $lines += "## Your Patterns (detected from your code)"
        $lines += ""
        foreach ($p in $Findings.codePatterns) {
            $lines += "- $p"
        }
        $lines += ""
    }

    # Libraries
    if ($Findings.libraries.Count -gt 0) {
        $lines += "## Libraries You Use"
        $lines += ""
        foreach ($lib in $Findings.libraries) {
            $lines += "- ``$lib``"
        }
        $lines += ""
    }

    # Config patterns
    if ($Findings.configPatterns.Count -gt 0) {
        $lines += "## Configuration"
        $lines += ""
        foreach ($c in $Findings.configPatterns) {
            $lines += "- $c"
        }
        $lines += ""
    }

    # File structure
    if ($Findings.fileStructure.Count -gt 0) {
        $lines += "## Project Structure"
        $lines += ""
        foreach ($f in $Findings.fileStructure) {
            $lines += "- $f"
        }
        $lines += ""
    }

    # Manual sections
    $lines += "## Your Preferences (edit this)"
    $lines += ""
    $lines += "- *(add things you always want AI to do with $Tech)*"
    $lines += ""
    $lines += "## Anti-Patterns (edit this)"
    $lines += ""
    $lines += "- *(add things you DON'T want AI to do with $Tech)*"
    $lines += ""

    # Online reference section placeholder
    $lines += "## Reference (from official docs)"
    $lines += ""
    $lines += "> Run ``brain-learn $($Tech.ToLower() -replace '[^a-z0-9]','-' -replace '-+','-')`` or wait for next brain-sync to populate this section."
    $lines += ""

    return $lines -join "`n"
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

# Find all git repos (recursive — searches deep until it finds .git)
$gitDirs = Get-ChildItem -Path $ProjectsRoot -Recurse -Directory -Filter ".git" -Force -ErrorAction SilentlyContinue
$repos = $gitDirs | ForEach-Object {
    [PSCustomObject]@{
        FullName     = $_.Parent.FullName
        RelativeName = $_.Parent.FullName.Replace("$ProjectsRoot\", "").Replace("\", "/")
    }
} | Sort-Object RelativeName

# Find top-level folders that have NO git repo anywhere inside them
$topLevelFolders = Get-ChildItem -Path $ProjectsRoot -Directory -ErrorAction SilentlyContinue
$repoTopFolders = $repos | ForEach-Object { ($_.RelativeName -split "/")[0] } | Select-Object -Unique
$noGitFolders = $topLevelFolders | Where-Object { $_.Name -notin $repoTopFolders }

Write-Log "Found $($repos.Count) git repositories"
if ($noGitFolders.Count -gt 0) {
    foreach ($folder in $noGitFolders) {
        Write-Log "  NO GIT: $($folder.Name) — no .git found anywhere inside"
    }
}

$projects = @()
$allDetectedTech = @()

foreach ($repo in $repos) {
    $repoPath = $repo.FullName
    $repoName = $repo.RelativeName

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

        # Auto-create skill file by scanning actual code
        $skillFilePath = Join-Path $SkillsDir "$techSlug.md"

        # Find which projects use this tech
        $usingProjects = $projects | Where-Object { $tech -in $_.techStack } | ForEach-Object { $_.name }
        $projectsList = if ($usingProjects) { $usingProjects -join ", " } else { "detected in projects" }

        Write-Log "  Scanning projects for $tech patterns..."
        $findings = Scan-ProjectsForTech -Tech $tech -Projects $projects
        $skillContent = Build-SkillContent -Tech $tech -ProjectsList $projectsList -Findings $findings

        Set-Content -Path $skillFilePath -Value $skillContent -Encoding UTF8
        Write-Log "  CREATED: skills/$techSlug.md ($(($findings.codePatterns).Count) patterns, $(($findings.libraries).Count) libraries detected)"
    }
}

# Refresh skill files list after creating new ones
$existingSkillFiles = Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "_index.md" } |
    ForEach-Object { $_.BaseName.ToLower() }

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
        $isNew = $skillFile -in ($undocumentedTech | ForEach-Object { $_.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', '' })
        $status = if ($isNew) { "auto-generated" } else { "documented" }
        $indexLines += "| $skillFile | ``$skillFile.md`` | $status |"
    }
} else {
    $indexLines += "| *(none yet)* | | |"
}

$indexLines += ""
$indexLines += "## Notes"
$indexLines += ""
$indexLines += "- Skill files are auto-created when new tech is detected in your projects."
$indexLines += "- Customize the auto-generated files with your patterns, anti-patterns, and conventions."
$indexLines += "- Once you customize a file, its status stays as ``documented`` on next sync."

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
