#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronizes local custom workspace skills to Claude Code and Google Antigravity.

.DESCRIPTION
    Discovers all local custom skills in the workspace (subfolders containing SKILL.md)
    and synchronizes them to Claude Code (~/.claude/skills) and/or Google Antigravity (~/.gemini/config/skills).
    Uses SHA256 content fingerprinting to ensure only new or modified skills are synced.
    When a skill is updated, the destination is cleanly refreshed so deleted files (such as obsolete manifests)
    are not left behind as orphans.

.PARAMETER Target
    Specifies which agent environment to sync skills to.
    Options: 'All' (default), 'Claude', 'Antigravity'.

.PARAMETER ClaudeOnly
    Convenience switch to sync only to Claude Code (~/.claude/skills).

.PARAMETER AntigravityOnly
    Convenience switch to sync only to Google Antigravity (~/.gemini/config/skills).

.PARAMETER Force
    Forces re-synchronizing of all skills even if fingerprints match.

.EXAMPLE
    .\import-skills.ps1
    Syncs all local workspace skills to both Claude Code and Antigravity.

.EXAMPLE
    .\import-skills.ps1 -Target Claude
    Syncs local workspace skills only to Claude Code.

.EXAMPLE
    .\import-skills.ps1 -ClaudeOnly

.EXAMPLE
    .\import-skills.ps1 -AntigravityOnly

.EXAMPLE
    .\import-skills.ps1 -Force
    Forces a complete clean re-sync of all skills.
#>

[CmdletBinding()]
param(
    [ValidateSet('All', 'Claude', 'Antigravity')]
    [string]$Target = 'All',

    [switch]$ClaudeOnly,
    [switch]$AntigravityOnly,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if ($ClaudeOnly -and $AntigravityOnly) {
    throw "Cannot specify both -ClaudeOnly and -AntigravityOnly simultaneously."
}
if ($ClaudeOnly) {
    $Target = 'Claude'
}
elseif ($AntigravityOnly) {
    $Target = 'Antigravity'
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     Agent Skills Sync (Claude Code & Antigravity)        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# Destination Paths & Targets
# -----------------------------------------------------------------------------
$claudeDir      = Join-Path $env:USERPROFILE '.claude\skills'
$antigravityDir = Join-Path $env:USERPROFILE '.gemini\config\skills'
$workspaceDir   = $PSScriptRoot

$activeTargets = [System.Collections.Generic.List[PSCustomObject]]::new()

if ($Target -in @('All', 'Claude')) {
    $activeTargets.Add([PSCustomObject]@{
        Id   = 'Claude'
        Name = 'Claude Code'
        Path = $claudeDir
    })
}

if ($Target -in @('All', 'Antigravity')) {
    $activeTargets.Add([PSCustomObject]@{
        Id   = 'Antigravity'
        Name = 'Google Antigravity'
        Path = $antigravityDir
    })
}

# -----------------------------------------------------------------------------
# Helper: Directory fingerprint (combines relative filenames and SHA256 hashes)
# -----------------------------------------------------------------------------
function Get-SkillFingerprint([string]$skillPath) {
    if (-not (Test-Path $skillPath)) { return $null }

    $ignoredNames = @('.DS_Store', 'desktop.ini', 'Thumbs.db')
    $files = Get-ChildItem -Path $skillPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $ignoredNames -notcontains $_.Name } |
        Sort-Object FullName

    if (-not $files -or $files.Count -eq 0) { return "" }

    $parts = foreach ($f in $files) {
        $relativeName = $f.FullName.Substring($skillPath.TrimEnd('\').Length + 1).Replace('\', '/')
        $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
        "${relativeName}:${hash}"
    }
    return ($parts -join '|')
}

# -----------------------------------------------------------------------------
# Helper: Discover local custom skills in workspace
# -----------------------------------------------------------------------------
function Get-WorkspaceSkills([string]$rootDir) {
    $skills = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
    if (-not (Test-Path $rootDir)) { return $skills }

    # Primary: check .\skills\* subdirectories
    $nestedSkillsDir = Join-Path $rootDir 'skills'
    if (Test-Path $nestedSkillsDir) {
        $nestedDirs = Get-ChildItem -Path $nestedSkillsDir -Directory -ErrorAction SilentlyContinue
        foreach ($nd in $nestedDirs) {
            if ($nd.Name -like '.*' -or $nd.Name -eq 'node_modules') { continue }
            if (Test-Path (Join-Path $nd.FullName 'SKILL.md')) {
                $skills.Add($nd)
            }
        }
    }

    # Fallback: check direct subdirectories in workspace root
    $dirs = Get-ChildItem -Path $rootDir -Directory -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        if ($d.Name -like '.*' -or $d.Name -eq 'node_modules' -or $d.Name -eq 'skills') { continue }
        if (Test-Path (Join-Path $d.FullName 'SKILL.md')) {
            if (-not ($skills | Where-Object { $_.Name -eq $d.Name })) {
                $skills.Add($d)
            }
        }
    }

    return $skills
}

# -----------------------------------------------------------------------------
# Step 1: Discover Local Workspace Skills
# -----------------------------------------------------------------------------
Write-Host "`n[1/3] Discovering local skills in workspace..." -ForegroundColor Yellow

$discoveredSkills = Get-WorkspaceSkills -rootDir $workspaceDir

if ($discoveredSkills.Count -eq 0) {
    Write-Warning "No skills containing a 'SKILL.md' found under '$workspaceDir\skills'."
    Write-Host "Create a skill folder under .\skills\<skill-name>\ with a SKILL.md to sync." -ForegroundColor DarkGray
    exit 0
}

Write-Host "  [OK] Found $($discoveredSkills.Count) local skill(s): $(($discoveredSkills | ForEach-Object { $_.Name }) -join ', ')" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 2: Synchronize Skills to Active Targets
# -----------------------------------------------------------------------------
Write-Host "`n[2/3] Synchronizing skills to target environments..." -ForegroundColor Yellow

$summaryResults = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($targetObj in $activeTargets) {
    Write-Host "`n  --> Target: $($targetObj.Name) ($($targetObj.Path))" -ForegroundColor Cyan

    if (-not (Test-Path $targetObj.Path)) {
        New-Item -ItemType Directory -Path $targetObj.Path -Force | Out-Null
        Write-Host "      Created target directory: $($targetObj.Path)" -ForegroundColor DarkGray
    }

    $added     = [System.Collections.Generic.List[string]]::new()
    $updated   = [System.Collections.Generic.List[string]]::new()
    $unchanged = [System.Collections.Generic.List[string]]::new()

    foreach ($skillDir in $discoveredSkills) {
        $skillName = $skillDir.Name
        $srcPath   = $skillDir.FullName
        $dstPath   = Join-Path $targetObj.Path $skillName

        $srcFingerprint = Get-SkillFingerprint -skillPath $srcPath
        $dstFingerprint = Get-SkillFingerprint -skillPath $dstPath

        if ($dstFingerprint -eq $null) {
            # Brand new skill
            New-Item -ItemType Directory -Path $dstPath -Force | Out-Null
            Copy-Item -Path "$srcPath\*" -Destination $dstPath -Recurse -Force
            $added.Add($skillName)
            Write-Host "      [+] NEW:       $skillName" -ForegroundColor Green
        }
        elseif ($srcFingerprint -ne $dstFingerprint -or $Force) {
            # Skill modified or force flag active: clean destination to remove deleted files
            Remove-Item -Path $dstPath -Recurse -Force
            New-Item -ItemType Directory -Path $dstPath -Force | Out-Null
            Copy-Item -Path "$srcPath\*" -Destination $dstPath -Recurse -Force
            $updated.Add($skillName)
            Write-Host "      [*] UPDATED:   $skillName" -ForegroundColor Yellow
        }
        else {
            # Identical content
            $unchanged.Add($skillName)
            Write-Host "      [=] UNCHANGED: $skillName" -ForegroundColor DarkGray
        }
    }

    $summaryResults.Add([PSCustomObject]@{
        Target    = $targetObj.Name
        Path      = $targetObj.Path
        Added     = $added
        Updated   = $updated
        Unchanged = $unchanged
    })
}

# -----------------------------------------------------------------------------
# Step 3: Execution Summary
# -----------------------------------------------------------------------------
Write-Host "`n[3/3] Execution Summary" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($res in $summaryResults) {
    Write-Host "Target Environment: $($res.Target)" -ForegroundColor White
    Write-Host "  Directory:  $($res.Path)" -ForegroundColor DarkGray
    Write-Host "  Skills Added:     $($res.Added.Count)" -ForegroundColor Green
    Write-Host "  Skills Updated:   $($res.Updated.Count)" -ForegroundColor Yellow
    Write-Host "  Skills Unchanged: $($res.Unchanged.Count)" -ForegroundColor DarkGray

    if ($res.Added.Count -gt 0) {
        Write-Host "  Newly Added:      $(($res.Added) -join ', ')" -ForegroundColor Green
    }
    if ($res.Updated.Count -gt 0) {
        Write-Host "  Updated:          $(($res.Updated) -join ', ')" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
}

$totalModified = ($summaryResults | ForEach-Object { $_.Added.Count + $_.Updated.Count } | Measure-Object -Sum).Sum

if ($totalModified -eq 0) {
    Write-Host "`nAll skills are up-to-date across all selected targets." -ForegroundColor Green
} else {
    Write-Host "`nSynchronization complete! $totalModified skill update(s) applied." -ForegroundColor Green
}
