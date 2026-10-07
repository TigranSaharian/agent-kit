<#
.SYNOPSIS
    Syncs canonical DiPro project skills into host-discoverable generated copies.

.DESCRIPTION
    Skill content is authored once under .ai/project/skills/<name>/SKILL.md.
    This script creates managed mirrors under .agents/skills/<name>/ and
    .claude/skills/<name>/, appending a banner that marks each mirror as
    generated. The mirrors are not verbatim copies; do not edit them directly.

    Run without -CheckOnly to update valid mirrors after editing a canonical
    SKILL.md. Use -CheckOnly to detect missing or drifted mirrors, canonical
    skill directories without SKILL.md, and orphaned copies. Orphaned files
    are reported but not deleted; review and remove them manually if obsolete.

.PARAMETER CheckOnly
    Compare mirrors against canonical sources without writing files. Exits
    with code 1 if a mirror is missing/out of date, a canonical skill lacks
    SKILL.md, or an orphaned copy exists.

.EXAMPLE
    pwsh scripts/sync-skills.ps1
    pwsh scripts/sync-skills.ps1 -CheckOnly
#>
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$canonicalRoot = Join-Path $repoRoot '.ai/project/skills'
$targetDirs = @('.agents/skills', '.claude/skills')
$banner = '<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->'

if (-not (Test-Path $canonicalRoot -PathType Container)) {
    Write-Error "Canonical skills directory not found: $canonicalRoot"
    exit 1
}

$skillDirs = @(Get-ChildItem -Path $canonicalRoot -Directory)
$canonicalNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$driftFound = $false
$sourceProblemFound = $false
$orphanFound = $false
$syncedCount = 0

foreach ($skillDir in $skillDirs) {
    $skillName = $skillDir.Name
    [void]$canonicalNames.Add($skillName)
    $canonicalFile = Join-Path $skillDir.FullName 'SKILL.md'
    if (-not (Test-Path $canonicalFile -PathType Leaf)) {
        $sourceProblemFound = $true
        Write-Warning "Invalid canonical skill '$skillName': SKILL.md is missing. Existing host copies were left untouched."
        continue
    }

    $canonicalContent = (Get-Content -Raw -Path $canonicalFile).TrimEnd("`r", "`n")
    $generatedContent = "$canonicalContent`n`n$banner`n"

    foreach ($targetDir in $targetDirs) {
        $targetFile = Join-Path $repoRoot "$targetDir/$skillName/SKILL.md"
        $exists = Test-Path $targetFile -PathType Leaf
        $current = if ($exists) { Get-Content -Raw -Path $targetFile } else { $null }

        if ($current -ceq $generatedContent) {
            continue
        }

        if ($CheckOnly) {
            $driftFound = $true
            if ($exists) {
                Write-Warning "Drift: $targetDir/$skillName/SKILL.md is out of date with the canonical source."
            } else {
                Write-Warning "Missing: $targetDir/$skillName/SKILL.md does not exist."
            }
            continue
        }

        $targetParent = Split-Path -Parent $targetFile
        if (-not (Test-Path $targetParent -PathType Container)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        Set-Content -Path $targetFile -Value $generatedContent -NoNewline
        $syncedCount++
        Write-Host "Synced $targetDir/$skillName/SKILL.md"
    }
}

# Catch copies whose canonical skill was removed or renamed. Never delete
# these automatically: they may contain user edits or need deliberate review.
foreach ($targetDir in $targetDirs) {
    $targetRoot = Join-Path $repoRoot $targetDir
    if (-not (Test-Path $targetRoot -PathType Container)) {
        continue
    }
    foreach ($targetSkillDir in Get-ChildItem -Path $targetRoot -Directory) {
        $targetFile = Join-Path $targetSkillDir.FullName 'SKILL.md'
        if ((Test-Path $targetFile -PathType Leaf) -and -not $canonicalNames.Contains($targetSkillDir.Name)) {
            $orphanFound = $true
            Write-Warning "Orphaned copy: $targetDir/$($targetSkillDir.Name)/SKILL.md has no canonical skill directory. Review and remove it manually if obsolete."
        }
    }
}

if ($CheckOnly) {
    if ($driftFound -or $sourceProblemFound -or $orphanFound) {
        Write-Error 'Skill synchronization check failed. Fix missing/drifted mirrors and review invalid or orphaned skills.'
        exit 1
    }
    Write-Host 'All generated skill copies match canonical sources; no invalid or orphaned skills found.'
    exit 0
}

if ($sourceProblemFound -or $orphanFound) {
    Write-Error 'Some canonical skills or generated copies need manual review. Valid canonical skills were synchronized, but invalid/orphaned files were left untouched.'
    exit 1
}

if ($syncedCount -eq 0) {
    Write-Host 'All skill copies already match their canonical source. Nothing to do.'
} else {
    Write-Host "Synced $syncedCount file(s)."
}
