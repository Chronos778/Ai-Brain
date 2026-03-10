#Requires -Version 5.1
<#
.SYNOPSIS
    project-init - generate per-project .github/copilot-instructions.md from AI-Brain sources.
.USAGE
    project-init                                # Target current directory
    project-init -ProjectPath C:\path\to\repo
    project-init -AllActiveProjects
    project-init -AllActiveProjects -DryRun
    project-init -FullContext                  # Include all available sources
#>

param(
    [string]$ProjectPath = "",
    [switch]$AllActiveProjects,
    [switch]$DryRun,
    [switch]$Quiet,
    [switch]$FullContext,
    [string]$BrainRoot = "C:\Users\Maithil\AI-Brain",
    [string]$ActiveProjectsPath = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BrainRoot)) {
    throw "Brain root not found: $BrainRoot"
}

if (-not $ActiveProjectsPath) {
    $ActiveProjectsPath = Join-Path $BrainRoot "memory\active-projects.json"
}

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message
    }
}

function Normalize-Path {
    param([string]$InputPath)
    if (-not $InputPath) { return "" }
    try {
        return [System.IO.Path]::GetFullPath($InputPath).TrimEnd('\\').ToLowerInvariant()
    } catch {
        return $InputPath.TrimEnd('\\').ToLowerInvariant()
    }
}

function Get-RelevantTopLevelSkillFiles {
    param([object]$ProjectSnapshot)

    $always = @("skills\review-playbook.md", "skills\testing-playbook.md", "skills\deployment-patterns.md")
    $mapped = @()

    if ($ProjectSnapshot -and $ProjectSnapshot.techStack) {
        $techMap = @{
            "React" = @("skills\react.md", "skills\frontend-design.md")
            "TypeScript" = @("skills\typescript.md")
            "Next.js" = @("skills\next-js.md")
            "Tailwind CSS" = @("skills\tailwind-css.md")
            "Three.js" = @("skills\three-js.md")
            "Node.js" = @("skills\node-js.md")
            "Express" = @("skills\express.md")
            "Python" = @("skills\python.md")
            "Vite" = @("skills\vite.md")
            "Firebase" = @("skills\firebase.md")
            "Bun" = @("skills\bun.md")
        }

        foreach ($tech in $ProjectSnapshot.techStack) {
            if ($techMap.ContainsKey($tech)) {
                $mapped += $techMap[$tech]
            }
        }
    }

    return @($always + $mapped) | Select-Object -Unique
}

function Get-BrainSources {
    param(
        [string]$Root,
        [object]$ProjectSnapshot,
        [switch]$IncludeAll
    )

    $sources = @()

    $identityFiles = @(
        "identity\core-rules.md",
        "identity\preferences.md",
        "identity\profile.md",
        "identity\style.md"
    )

    $memoryFiles = if ($IncludeAll) {
        @("memory\active-context.md", "memory\decisions.md", "memory\learnings.md")
    } else {
        @("memory\active-context.md", "memory\decisions.md", "memory\learnings.md")
    }

    $skillIndex = @("skills\_index.md")

    $topLevelSkills = @()
    $skillsDir = Join-Path $Root "skills"
    if ($IncludeAll) {
        if (Test-Path $skillsDir) {
            $topLevelSkills = @(Get-ChildItem -Path $skillsDir -File -Filter "*.md" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ne "_index.md" } |
                Sort-Object Name |
                ForEach-Object { "skills\$($_.Name)" })
        }
    } else {
        $topLevelSkills = @(Get-RelevantTopLevelSkillFiles -ProjectSnapshot $ProjectSnapshot)
    }

    $nestedSkills = @()
    if ($IncludeAll -and (Test-Path $skillsDir)) {
        $nestedSkills = @(Get-ChildItem -Path $skillsDir -Recurse -File -Filter "SKILL.md" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch "\\skills\\review\\" } |
            Sort-Object FullName |
            ForEach-Object {
                $_.FullName.Substring($Root.Length).TrimStart('\\')
            })
    }

    foreach ($relative in @($identityFiles + $memoryFiles + $skillIndex + $topLevelSkills + $nestedSkills)) {
        $absolute = Join-Path $Root $relative
        if (Test-Path $absolute) {
            $sources += [PSCustomObject]@{
                RelativePath = $relative
                AbsolutePath = $absolute
            }
        }
    }

    return $sources
}

function Get-TrimmedMarkdownContent {
    param(
        [string]$AbsolutePath,
        [string]$RelativePath,
        [switch]$IncludeAll
    )

    $raw = Get-Content -Path $AbsolutePath -Raw -Encoding UTF8
    if ($IncludeAll) {
        return $raw.TrimEnd()
    }

    # Keep memory signal compact for project instruction files.
    if ($RelativePath -eq "memory\decisions.md" -or $RelativePath -eq "memory\learnings.md") {
        $lines = @($raw -split "`r?`n")
        $maxLines = 140
        if ($lines.Count -le $maxLines) {
            return $raw.TrimEnd()
        }
        $head = @($lines | Select-Object -First 20)
        $tail = @($lines | Select-Object -Last ($maxLines - 20))
        return (@($head + "" + "[... trimmed by project-init for compact context ...]" + "" + $tail) -join "`n").TrimEnd()
    }

    return $raw.TrimEnd()
}

function Get-ProjectSnapshot {
    param(
        [string]$ProjectsJsonPath,
        [string]$TargetProjectPath
    )

    if (-not (Test-Path $ProjectsJsonPath)) {
        return $null
    }

    try {
        $data = Get-Content -Path $ProjectsJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }

    $targetNorm = Normalize-Path -InputPath $TargetProjectPath
    foreach ($p in $data.projects) {
        if ((Normalize-Path -InputPath $p.path) -eq $targetNorm) {
            return $p
        }
    }

    return $null
}

function Build-InstructionsContent {
    param(
        [string]$Root,
        [string]$TargetProjectPath,
        [object]$ProjectSnapshot,
        [object[]]$Sources,
        [switch]$IncludeAll
    )

    $lines = @()
    $lines += "# Copilot Instructions"
    $lines += ""
    $lines += "> Generated by project-init on $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
    $lines += "> Brain root: $Root"
    $lines += "> Project path: $TargetProjectPath"
    $lines += "> Mode: $(if ($IncludeAll) { 'full' } else { 'compact' })"
    $lines += "> Sources included: $($Sources.Count)"
    $lines += ""

    if ($ProjectSnapshot) {
        $tech = if ($ProjectSnapshot.techStack -and $ProjectSnapshot.techStack.Count -gt 0) { $ProjectSnapshot.techStack -join ', ' } else { "unknown" }
        $lastMessage = if ($ProjectSnapshot.lastCommit -and $ProjectSnapshot.lastCommit.message) { $ProjectSnapshot.lastCommit.message } else { "" }

        $lines += "## Project Snapshot"
        $lines += ""
        $lines += "- Name: $($ProjectSnapshot.name)"
        $lines += "- Branch: $($ProjectSnapshot.branch)"
        $lines += "- Tech stack: $tech"
        if ($lastMessage) {
            $lines += "- Last commit: $lastMessage"
        }
        $lines += ""
    }

    foreach ($src in $Sources) {
        $lines += "## Source: $($src.RelativePath.Replace('\\', '/'))"
        $lines += ""
        $content = Get-TrimmedMarkdownContent -AbsolutePath $src.AbsolutePath -RelativePath $src.RelativePath -IncludeAll:$IncludeAll
        if ($content) {
            $lines += $content.TrimEnd()
        }
        $lines += ""
    }

    return ($lines -join "`n")
}

function Write-ProjectInstructions {
    param(
        [string]$TargetPath,
        [string]$Root,
        [string]$ProjectsJsonPath,
        [switch]$IsDryRun,
        [switch]$IncludeAll
    )

    if (-not (Test-Path $TargetPath)) {
        return [PSCustomObject]@{ Project = $TargetPath; Status = "missing"; OutputPath = ""; SourceCount = 0 }
    }

    $snapshot = Get-ProjectSnapshot -ProjectsJsonPath $ProjectsJsonPath -TargetProjectPath $TargetPath
    $sources = @(Get-BrainSources -Root $Root -ProjectSnapshot $snapshot -IncludeAll:$IncludeAll)

    $githubDir = Join-Path $TargetPath ".github"
    $outputPath = Join-Path $githubDir "copilot-instructions.md"

    if ($IsDryRun) {
        return [PSCustomObject]@{ Project = $TargetPath; Status = "dry-run"; OutputPath = $outputPath; SourceCount = $sources.Count }
    }

    if (-not (Test-Path $githubDir)) {
        New-Item -ItemType Directory -Path $githubDir -Force | Out-Null
    }

    $payload = Build-InstructionsContent -Root $Root -TargetProjectPath $TargetPath -ProjectSnapshot $snapshot -Sources $sources -IncludeAll:$IncludeAll
    Set-Content -Path $outputPath -Value $payload -Encoding UTF8

    return [PSCustomObject]@{ Project = $TargetPath; Status = "written"; OutputPath = $outputPath; SourceCount = $sources.Count }
}

$targets = @()
if ($AllActiveProjects) {
    if (-not (Test-Path $ActiveProjectsPath)) {
        throw "active-projects.json not found: $ActiveProjectsPath"
    }

    $data = Get-Content -Path $ActiveProjectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $targets = @($data.projects | Where-Object { $_.isActive -eq $true } | ForEach-Object { [string]$_.path })
} elseif ($ProjectPath) {
    $targets = @($ProjectPath)
} else {
    $targets = @((Get-Location).Path)
}

$targets = @($targets | Where-Object { $_ } | Select-Object -Unique)

if ($targets.Count -eq 0) {
    Write-Info "No target projects found."
    exit 0
}

$results = @()
foreach ($target in $targets) {
    try {
        $result = Write-ProjectInstructions -TargetPath $target -Root $BrainRoot -ProjectsJsonPath $ActiveProjectsPath -IsDryRun:$DryRun -IncludeAll:$FullContext
        $results += $result
    } catch {
        $results += [PSCustomObject]@{ Project = $target; Status = "error"; OutputPath = ""; SourceCount = 0; Error = $_.Exception.Message }
    }
}

foreach ($r in $results) {
    if ($r.Status -eq "written") {
        Write-Info "[OK] $($r.Project) -> $($r.OutputPath) ($($r.SourceCount) sources)"
    } elseif ($r.Status -eq "dry-run") {
        Write-Info "[DRY] $($r.Project) -> $($r.OutputPath) ($($r.SourceCount) sources)"
    } elseif ($r.Status -eq "missing") {
        Write-Info "[SKIP] $($r.Project) (path missing)"
    } else {
        Write-Info "[ERR] $($r.Project) - $($r.Error)"
    }
}

$writtenCount = @($results | Where-Object { $_.Status -eq "written" }).Count
$dryCount = @($results | Where-Object { $_.Status -eq "dry-run" }).Count
$errorCount = @($results | Where-Object { $_.Status -eq "error" }).Count

if (-not $Quiet) {
    Write-Host ""
    Write-Host "project-init summary: written=$writtenCount dry-run=$dryCount errors=$errorCount"
}
