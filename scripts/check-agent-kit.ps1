<#
.SYNOPSIS
    Checks the agent kit's internal references for rot: broken Markdown
    links, agent profiles pointing at missing role files, and path
    instructions whose applyTo glob matches nothing in the repository.

.DESCRIPTION
    This checks that the kit's own cross-references still resolve to real
    files, the same way a linter checks that imports resolve, and that the
    documented solution and test inventory still match DiPro.sln. Run it
    after renaming, moving, or removing any kit file (a role, a
    path-instruction file, an agent profile, an entry point) to catch a
    dangling reference before an agent trips over it mid-task.

    Fourteen checks:
    1. Markdown links ("[text](path)") inside .ai/, .github/, and the root
       entry-point files must resolve to an existing file (relative to the
       linking file's own directory). External (http/https/mailto) links
       and in-page anchors are skipped.
    2. Every .github/agents/*.agent.md that references a ".ai/roles/*.md"
       path must have that role file exist.
    3. Every front-matter "applyTo" glob in .github/instructions/*.md must
       match at least one file in the repository (excluding bin/obj/.git/.vs).
    4. Genericity: the reusable kit layer (AGENTS.md/CLAUDE.md,
       .ai/ outside .ai/project/, .github/copilot-instructions.md, and
       .github/agents/*.agent.md) must not contain project-specific facts.
       A project overlay declares its own identifying tokens (project name,
       internal framework codenames, etc.) in
       .ai/project/PROJECT_TOKENS.txt, one per line. Any of those tokens
       found in the generic layer is flagged, so project facts cannot drift
       into reusable guidance undetected. Skipped if that file is absent.
    5. Every name in an agent profile's "agents:" list (the subagents it may
       delegate to) must be the "name:" of an existing profile.
    6. Retired model families listed in .ai/adapters/copilot-models.json
       ("retiredFamilies") must not appear in kit Markdown, and no entry-point
       file named after one (<FAMILY>.md) may exist.
    7. Section references written as `path/file.md`, "Heading" (or without
       backticks) must point to a file that exists and a Markdown heading
       that exists in it, so a renamed or deleted section cannot leave a
       dangling reference behind.
    8. The PowerShell image used by the lint job must be pinned by sha256
       digest, and the digest must be identical in .gitlab-ci.yml and
       .ai/adapters/gitlab-ci.lint-agent-kit.snippet.yml when both exist.
    9. Tool boundaries: every agent profile declares a "tools:" list (a
       missing list grants every tool); only profiles named in
       $executeAllowed may hold a terminal ("execute") tool, and those
       profiles must hold it.
   10. Size budgets: always-loaded files (entry points and the overlay's
       always-on guardrails) stay under a character budget so their context
       cost cannot creep up unnoticed.
   11. Every scripts/*.ps1 named in .gitlab-ci.yml, the CI snippet, or the
       git hook must exist.
   12. The routing-evaluation catalog must retain the essential high-risk and
       host-fallback scenarios, so a policy edit cannot silently remove them.
   13. Every scripts/*.ps1 file must parse as valid PowerShell, so a syntax
       error cannot silently disable an enforcement check.
   14. DiPro.sln must match the one
       "DiPro.sln contains N solution entries: N C# projects and N solution
       folders" statement in .ai/project/PROJECT_CONTEXT.md. Solution test
       projects (a C# project whose file name ends in Tests.csproj) must
       match the baseline rows under "Recorded test baseline" in
       .ai/project/VERIFIED.md. Slash direction and case are normalized.
       Non-test projects are excluded. The expected numbers are read from
       the solution and the docs; they are not hard-coded in this script.

.PARAMETER Quiet
    Suppress the per-check "OK" lines; still prints warnings/errors.

.EXAMPLE
    pwsh scripts/check-agent-kit.ps1
#>
param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$problems = @()

function Resolve-RepoPath {
    param([string]$BaseDir, [string]$Target)
    $clean = $Target.Split('#')[0].Split('?')[0].Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { return $null }
    try {
        return [System.IO.Path]::GetFullPath((Join-Path $BaseDir $clean))
    } catch {
        return $null
    }
}

function ConvertTo-ComparableRepoPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    return ($Path.Trim() -replace '\\', '/').ToLowerInvariant()
}

function Get-RepoLeafName {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    $normalized = $Path.Trim() -replace '\\', '/'
    $slash = $normalized.LastIndexOf('/')
    if ($slash -ge 0 -and $slash -lt ($normalized.Length - 1)) {
        return $normalized.Substring($slash + 1)
    }
    return $normalized
}

# --- Check 1: Markdown links resolve -----------------------------------
$linkScanRoots = @(
    (Join-Path $repoRoot 'AGENTS.md'),
    (Join-Path $repoRoot 'CLAUDE.md'),
    (Join-Path $repoRoot '.ai'),
    (Join-Path $repoRoot '.github'),
    (Join-Path $repoRoot '.cursor')
)
$linkPattern = '\[[^\]]*\]\(([^)]+)\)'
$mdFiles = foreach ($root in $linkScanRoots) {
    if (Test-Path $root -PathType Leaf) {
        Get-Item $root
    } elseif (Test-Path $root -PathType Container) {
        Get-ChildItem -Path $root -Recurse -File | Where-Object { $_.Extension -in @('.md', '.mdc') }
    }
}

$linkChecked = 0
foreach ($file in $mdFiles) {
    $content = Get-Content -Raw -Path $file.FullName
    $matches = [regex]::Matches($content, $linkPattern)
    foreach ($m in $matches) {
        $target = $m.Groups[1].Value
        if ($target -match '^(https?|mailto):' -or $target -match '^#') {
            continue
        }
        $linkChecked++
        $resolved = Resolve-RepoPath -BaseDir $file.DirectoryName -Target $target
        if (-not $resolved -or -not (Test-Path $resolved)) {
            $problems += "Broken link in $($file.FullName.Substring($repoRoot.Length + 1)): target '$target' does not resolve."
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $linkChecked Markdown link(s) across $($mdFiles.Count) file(s)."
}

# --- Check 2: agent profiles reference existing role files --------------
$agentProfiles = Get-ChildItem -Path (Join-Path $repoRoot '.github/agents') -Filter '*.agent.md' -File -ErrorAction SilentlyContinue
$rolePattern = '\.ai/roles/([a-zA-Z0-9\-]+)\.md'
$roleChecked = 0
foreach ($profile in $agentProfiles) {
    $content = Get-Content -Raw -Path $profile.FullName
    foreach ($m in [regex]::Matches($content, $rolePattern)) {
        $roleChecked++
        $roleFile = Join-Path $repoRoot ".ai/roles/$($m.Groups[1].Value).md"
        if (-not (Test-Path $roleFile -PathType Leaf)) {
            $problems += "Agent profile $($profile.Name) references missing role file: .ai/roles/$($m.Groups[1].Value).md"
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $roleChecked role reference(s) across $($agentProfiles.Count) agent profile(s)."
}

# --- Check 3: applyTo globs match at least one file ----------------------
$instructionFiles = Get-ChildItem -Path (Join-Path $repoRoot '.github/instructions') -Filter '*.md' -File -ErrorAction SilentlyContinue
$excludeDirs = @('\bin\', '\obj\', '\.git\', '\.vs\')
$globChecked = 0
foreach ($instrFile in $instructionFiles) {
    $content = Get-Content -Raw -Path $instrFile.FullName
    $applyToMatch = [regex]::Match($content, 'applyTo:\s*"([^"]+)"')
    if (-not $applyToMatch.Success) {
        $problems += "Instruction file $($instrFile.Name) has no parsable 'applyTo' front-matter entry."
        continue
    }
    $globs = $applyToMatch.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() }
    foreach ($glob in $globs) {
        $globChecked++
        # Convert a repo-relative glob (e.g. "**/*.Domain/**/*.cs") into a
        # regex and test it against real file paths, since PowerShell has no
        # built-in recursive ** glob matcher.
        $pattern = [regex]::Escape($glob) `
            -replace '\\\*\\\*/', '(?:.*/)?' `
            -replace '\\\*\\\*', '.*' `
            -replace '\\\*', '[^/\\\\]*'
        $regex = "^$pattern$"
        $found = $false
        foreach ($candidate in Get-ChildItem -Path $repoRoot -Recurse -File -ErrorAction SilentlyContinue) {
            $rel = $candidate.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/'
            if ($excludeDirs | Where-Object { $rel -match [regex]::Escape($_.Trim('\')) }) {
                continue
            }
            if ($rel -match $regex) {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $problems += "Instruction file $($instrFile.Name): applyTo glob '$glob' matches no file in the repository."
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $globChecked applyTo glob(s) across $($instructionFiles.Count) instruction file(s)."
}

# --- Check 4: generic layer must not contain project-specific tokens ----
# The reusable kit (AGENTS.md/CLAUDE.md, .ai/ outside .ai/project/,
# .github/copilot-instructions.md, and .github/agents/*.agent.md) must stay
# project-neutral so it can be reused across repositories. A project overlay
# declares its own identifying tokens (project/codename, internal framework
# names, etc.) in .ai/project/PROJECT_TOKENS.txt, one per line ("#" comments
# and blank lines are ignored). This check flags any of those tokens found
# in the generic layer, catching accidental project-fact leakage before it
# undermines reusability. If no PROJECT_TOKENS.txt exists, the check is
# skipped — there is nothing declared to guard against.
$tokensFile = Join-Path $repoRoot '.ai/project/PROJECT_TOKENS.txt'
$tokenChecked = 0
$tokens = @()
$genericFiles = @()
if (Test-Path $tokensFile -PathType Leaf) {
    $tokens = @(Get-Content -Path $tokensFile |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') })

    foreach ($name in @('AGENTS.md', 'CLAUDE.md', '.github/copilot-instructions.md')) {
        $p = Join-Path $repoRoot $name
        if (Test-Path $p -PathType Leaf) { $genericFiles += Get-Item $p }
    }
    $aiRoot = Join-Path $repoRoot '.ai'
    $projectRoot = Join-Path $repoRoot '.ai/project'
    if (Test-Path $aiRoot -PathType Container) {
        $genericFiles += Get-ChildItem -Path $aiRoot -Filter '*.md' -Recurse -File |
            Where-Object { -not $_.FullName.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase) }
    }
    $agentsDir = Join-Path $repoRoot '.github/agents'
    if (Test-Path $agentsDir -PathType Container) {
        $genericFiles += Get-ChildItem -Path $agentsDir -Filter '*.agent.md' -File
    }

    foreach ($file in $genericFiles) {
        $lines = @(Get-Content -Path $file.FullName)

        # COPILOT_VALIDATION.md's "Validation log" table intentionally
        # records project-specific evidence; only scan the checklist text
        # above that heading. Other generic files are scanned in full:
        # project evidence belongs in the overlay (.ai/project/).
        $scanUpTo = $lines.Count
        if ($file.Name -eq 'COPILOT_VALIDATION.md') {
            $logHeader = $lines | Select-String -Pattern '^##\s*Validation log' | Select-Object -First 1
            if ($logHeader) { $scanUpTo = $logHeader.LineNumber - 1 }
        }

        foreach ($token in $tokens) {
            $tokenChecked++
            # Match a declared token, not an incidental substring such as
            # a framework name appearing inside the generic word "libraries".
            $escaped = '(?<![A-Za-z0-9_])' + [regex]::Escape($token) + '(?![A-Za-z0-9_])'
            for ($i = 0; $i -lt $scanUpTo; $i++) {
                if ($lines[$i] -match $escaped) {
                    $rel = $file.FullName.Substring($repoRoot.Length + 1)
                    $problems += "Generic-layer file ${rel}:$($i + 1) contains project-specific token '$token' (declared in .ai/project/PROJECT_TOKENS.txt). Move this fact into the project overlay."
                    break
                }
            }
        }
    }
}
if (-not $Quiet) {
    if (Test-Path $tokensFile -PathType Leaf) {
        Write-Host "Checked $tokenChecked token/file combination(s) against $($tokens.Count) declared project token(s) across $($genericFiles.Count) generic-layer file(s)."
    } else {
        Write-Host 'Skipped project-token genericity check: .ai/project/PROJECT_TOKENS.txt not found.'
    }
}

# --- Check 5: subagent lists name real profiles ------------------------
$profileNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($agentFile in $agentProfiles) {
    $agentContent = Get-Content -Raw -Path $agentFile.FullName
    $nameMatch = [regex]::Match($agentContent, '(?m)^name:\s*(.+?)\s*$')
    if ($nameMatch.Success) {
        [void]$profileNames.Add($nameMatch.Groups[1].Value.Trim().Trim('"', "'"))
    }
}
$agentRefChecked = 0
foreach ($agentFile in $agentProfiles) {
    $agentContent = Get-Content -Raw -Path $agentFile.FullName
    $listMatch = [regex]::Match($agentContent, '(?m)^agents:\s*\[([^\]]*)\]')
    if (-not $listMatch.Success) { continue }
    foreach ($ref in ($listMatch.Groups[1].Value -split ',')) {
        $refName = $ref.Trim().Trim('"', "'")
        if (-not $refName -or $refName -eq '*') { continue }
        $agentRefChecked++
        if (-not $profileNames.Contains($refName)) {
            $problems += "Agent profile $($agentFile.Name) lists subagent '$refName' in its 'agents' property, but no profile with that name exists."
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $agentRefChecked subagent reference(s) across $($agentProfiles.Count) agent profile(s)."
}

# --- Check 6: retired model families do not linger ------------------------
$mapPath = Join-Path $repoRoot '.ai/adapters/copilot-models.json'
$retiredFamilies = @()
if (Test-Path $mapPath -PathType Leaf) {
    $mapData = Get-Content -Raw -Path $mapPath | ConvertFrom-Json
    $retiredFamilies = @($mapData.retiredFamilies | Where-Object { $_ })
}
$retiredChecked = 0
foreach ($family in $retiredFamilies) {
    $entryName = $family.ToUpperInvariant() + '.md'
    if (Test-Path (Join-Path $repoRoot $entryName) -PathType Leaf) {
        $problems += "Retired model family '$family' still has an entry-point file: $entryName."
    }
    foreach ($mdFile in $mdFiles) {
        $retiredChecked++
        $mdContent = Get-Content -Raw -Path $mdFile.FullName
        if ($mdContent -match [regex]::Escape($family)) {
            $problems += "$($mdFile.FullName.Substring($repoRoot.Length + 1)) mentions retired model family '$family'."
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $retiredChecked file/family combination(s) against $($retiredFamilies.Count) retired model famil(ies)."
}

# --- Check 7: section references name real headings ----------------------
$sectionRefChecked = 0
$headingCache = @{}
foreach ($mdFile in $mdFiles) {
    $mdText = Get-Content -Raw -Path $mdFile.FullName
    $relSource = $mdFile.FullName.Substring($repoRoot.Length + 1)
    foreach ($refMatch in [regex]::Matches($mdText, '(?<path>[\w./-]+\.md)`?,\s*["\u201C](?<h>[^"\u201D\r\n]+)["\u201D]')) {
        $sectionRefChecked++
        $refPath = $refMatch.Groups['path'].Value
        $heading = $refMatch.Groups['h'].Value.Trim()
        $target = Join-Path $repoRoot $refPath
        if (-not (Test-Path $target -PathType Leaf)) {
            $target = Join-Path $mdFile.DirectoryName $refPath
        }
        if (-not (Test-Path $target -PathType Leaf)) {
            $problems += "$relSource references section '$heading' in $refPath, but that file does not exist."
            continue
        }
        if (-not $headingCache.ContainsKey($target)) {
            $found = @()
            foreach ($line in (Get-Content -Path $target)) {
                $headingMatch = [regex]::Match($line, '^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$')
                if ($headingMatch.Success) {
                    $found += $headingMatch.Groups[1].Value.Trim().ToLowerInvariant()
                }
            }
            $headingCache[$target] = $found
        }
        if ($headingCache[$target] -notcontains $heading.ToLowerInvariant()) {
            $problems += "$relSource references section '$heading' in $refPath, but that file has no such heading."
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $sectionRefChecked section reference(s)."
}

# --- Check 8: CI lint image pinned by digest and consistent ---------------
$ciFiles = @(
    (Join-Path $repoRoot '.gitlab-ci.yml'),
    (Join-Path $repoRoot '.ai/adapters/gitlab-ci.lint-agent-kit.snippet.yml')
)
$ciImages = @{}
foreach ($ciFile in $ciFiles) {
    if (-not (Test-Path $ciFile -PathType Leaf)) { continue }
    $ciText = Get-Content -Raw -Path $ciFile
    $imageMatch = [regex]::Match($ciText, '(?m)^\s*image:\s*(mcr\.microsoft\.com/powershell\S*)')
    if (-not $imageMatch.Success) { continue }
    $image = $imageMatch.Groups[1].Value
    $ciImages[$ciFile] = $image
    $relCi = $ciFile.Substring($repoRoot.Length + 1)
    if ($image -notmatch '@sha256:[0-9a-f]{64}$') {
        $problems += "$relCi uses PowerShell image '$image', which is not pinned by sha256 digest."
    }
}
$distinctImages = @($ciImages.Values | Select-Object -Unique)
if ($distinctImages.Count -gt 1) {
    $problems += "The lint job's PowerShell image differs between .gitlab-ci.yml and the adapter snippet; update both together."
}
if (-not $Quiet) {
    Write-Host "Checked $($ciImages.Count) CI file(s) for a digest-pinned PowerShell image."
}

# --- Check 9: tool boundaries (terminal only for the Verifier) -------------
$executeAllowed = @('Verifier')
$toolChecked = 0
foreach ($agentFile in $agentProfiles) {
    $agentContent = Get-Content -Raw -Path $agentFile.FullName
    $nameMatch = [regex]::Match($agentContent, '(?m)^name:\s*(.+?)\s*$')
    if (-not $nameMatch.Success) { continue }
    $agentName = $nameMatch.Groups[1].Value.Trim().Trim('"', "'")
    $toolsMatch = [regex]::Match($agentContent, '(?m)^tools:\s*\[([^\]]*)\]')
    if (-not $toolsMatch.Success) {
        $problems += "Agent profile $($agentFile.Name) declares no 'tools:' list, which grants every tool including the terminal."
        continue
    }
    $toolChecked++
    $tools = @($toolsMatch.Groups[1].Value -split ',' | ForEach-Object { $_.Trim().Trim('"', "'") } | Where-Object { $_ })
    $hasExecute = @($tools | Where-Object { $_ -eq 'execute' -or $_ -like 'execute/*' }).Count -gt 0
    $mayExecute = $executeAllowed -contains $agentName
    if ($hasExecute -and -not $mayExecute) {
        $problems += "Agent profile $($agentFile.Name) ($agentName) has a terminal tool but only $($executeAllowed -join ', ') may."
    }
    if ($mayExecute -and -not $hasExecute) {
        $problems += "Agent profile $($agentFile.Name) ($agentName) must have the 'execute' tool so verification can run."
    }
}
if (-not $Quiet) {
    Write-Host "Checked tool boundaries for $toolChecked agent profile(s)."
}

# --- Check 10: always-loaded files stay within their size budget ----------
$sizeBudgets = [ordered]@{
    'AGENTS.md'                       = 4000
    '.github/copilot-instructions.md' = 2600
    'CLAUDE.md'                       = 900
    '.ai/project/ALWAYS_ON_GUARDRAILS.md' = 3200
}
foreach ($budgetPath in $sizeBudgets.Keys) {
    $budgetFile = Join-Path $repoRoot $budgetPath
    if (-not (Test-Path $budgetFile -PathType Leaf)) { continue }
    $budgetLength = (Get-Content -Raw -Path $budgetFile).Length
    if ($budgetLength -gt $sizeBudgets[$budgetPath]) {
        $problems += "$budgetPath is $budgetLength characters, over its budget of $($sizeBudgets[$budgetPath]). Trim it, or raise the budget in check-agent-kit.ps1 deliberately."
    }
}
if (-not $Quiet) {
    Write-Host "Checked $($sizeBudgets.Count) size budget(s)."
}

# --- Check 11: scripts named by CI and hooks exist -------------------------
$scriptRefChecked = 0
$scriptRefSources = @(
    '.gitlab-ci.yml',
    '.ai/adapters/gitlab-ci.lint-agent-kit.snippet.yml',
    '.githooks/pre-commit'
)
foreach ($sourcePath in $scriptRefSources) {
    $sourceFile = Join-Path $repoRoot $sourcePath
    if (-not (Test-Path $sourceFile -PathType Leaf)) { continue }
    $sourceText = Get-Content -Raw -Path $sourceFile
    foreach ($scriptMatch in [regex]::Matches($sourceText, 'scripts/[A-Za-z0-9._-]+\.ps1')) {
        $scriptRefChecked++
        if (-not (Test-Path (Join-Path $repoRoot $scriptMatch.Value) -PathType Leaf)) {
            $problems += "$sourcePath runs $($scriptMatch.Value), but that script does not exist."
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $scriptRefChecked script reference(s) in CI and hook files."
}

# --- Check 12: routing-evaluation coverage remains intact -------------------
$evalCatalog = Join-Path $repoRoot '.ai/EVALS.md'
$requiredEvals = @('E4', 'E8', 'E9', 'E10', 'E11', 'E16', 'E17')
if (-not (Test-Path $evalCatalog -PathType Leaf)) {
    $problems += '.ai/EVALS.md is missing; required routing-evaluation scenarios cannot be checked.'
} else {
    $evalText = Get-Content -Raw -Path $evalCatalog
    foreach ($evalId in $requiredEvals) {
        if ($evalText -notmatch "(?m)^\|\s*$evalId\s*\|") {
            $problems += ".ai/EVALS.md is missing required routing-evaluation scenario $evalId."
        }
    }
}
if (-not $Quiet) {
    Write-Host "Checked $($requiredEvals.Count) required routing-evaluation scenario(s)."
}

# --- Check 13: PowerShell scripts parse cleanly ----------------------------
$scriptParseChecked = 0
$scriptsRoot = Join-Path $repoRoot 'scripts'
if (Test-Path $scriptsRoot -PathType Container) {
    foreach ($scriptFile in Get-ChildItem -Path $scriptsRoot -Filter '*.ps1' -File) {
        $scriptParseChecked++
        $tokens = $null
        $parseErrors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $scriptFile.FullName,
            [ref]$tokens,
            [ref]$parseErrors)
        foreach ($parseError in @($parseErrors)) {
            $problems += "PowerShell syntax error in scripts/$($scriptFile.Name):$($parseError.Extent.StartLineNumber): $($parseError.Message)"
        }
    }
}
if (-not $Quiet) {
    Write-Host "Parsed $scriptParseChecked PowerShell script(s) for syntax errors."
}

# --- Check 14: solution inventory matches PROJECT_CONTEXT and VERIFIED -----
# Read-only. Counts and test paths come from DiPro.sln and the docs.
$entryCount = 0
$csharpCount = 0
$folderCount = 0
$solutionTestPaths = New-Object System.Collections.Generic.List[string]
$baselinePaths = New-Object System.Collections.Generic.List[string]
$baselineSectionFound = $false
$slnPath = Join-Path $repoRoot 'DiPro.sln'
$contextPath = Join-Path $repoRoot '.ai/project/PROJECT_CONTEXT.md'
$verifiedPath = Join-Path $repoRoot '.ai/project/VERIFIED.md'
$slnExists = Test-Path -LiteralPath $slnPath -PathType Leaf
$csharpProjectType = 'FAE04EC0-301F-11D3-BF4B-00C04F79EFBC'
$solutionFolderType = '2150E333-8FDC-42A3-9474-1A3956D46DE8'

if (-not $slnExists) {
    $problems += 'DiPro.sln is missing, so the solution inventory cannot be checked.'
} else {
    $slnText = Get-Content -Raw -LiteralPath $slnPath
    if ($null -eq $slnText) { $slnText = '' }
    $projectPattern = '(?m)^Project\("\{(?<type>[0-9A-Fa-f-]+)\}"\)\s*=\s*"(?<name>[^"]*)"\s*,\s*"(?<path>[^"]*)"\s*,\s*"\{[0-9A-Fa-f-]+\}"'
    foreach ($projectMatch in [regex]::Matches($slnText, $projectPattern)) {
        $entryCount++
        $typeId = $projectMatch.Groups['type'].Value
        $relativePath = $projectMatch.Groups['path'].Value
        if ($typeId.Equals($solutionFolderType, [System.StringComparison]::OrdinalIgnoreCase)) {
            $folderCount++
            continue
        }
        if (-not $typeId.Equals($csharpProjectType, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $csharpCount++
        $leaf = Get-RepoLeafName $relativePath
        if ($leaf.EndsWith('Tests.csproj', [System.StringComparison]::OrdinalIgnoreCase)) {
            [void]$solutionTestPaths.Add($relativePath)
        }
    }
}

if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) {
    $problems += '.ai/project/PROJECT_CONTEXT.md is missing, so the declared solution counts cannot be checked.'
} else {
    $contextText = Get-Content -Raw -LiteralPath $contextPath
    if ($null -eq $contextText) { $contextText = '' }
    $statementPattern = 'DiPro\.sln`?\s+contains (\d+) solution entries: (\d+) C# projects and (\d+) solution folders'
    $statementMatches = [regex]::Matches($contextText, $statementPattern)
    if ($statementMatches.Count -ne 1) {
        $problems += ".ai/project/PROJECT_CONTEXT.md must contain exactly one 'DiPro.sln contains N solution entries: N C# projects and N solution folders' statement (found $($statementMatches.Count))."
    } elseif ($slnExists) {
        $declaredEntries = [int]$statementMatches[0].Groups[1].Value
        $declaredCsharp = [int]$statementMatches[0].Groups[2].Value
        $declaredFolders = [int]$statementMatches[0].Groups[3].Value
        if ($declaredEntries -ne $entryCount -or $declaredCsharp -ne $csharpCount -or $declaredFolders -ne $folderCount) {
            $problems += ".ai/project/PROJECT_CONTEXT.md declares $declaredEntries solution entries, $declaredCsharp C# projects, and $declaredFolders solution folders, but DiPro.sln has $entryCount entries, $csharpCount C# projects, and $folderCount solution folders."
        }
    }
}

if (-not (Test-Path -LiteralPath $verifiedPath -PathType Leaf)) {
    $problems += '.ai/project/VERIFIED.md is missing, so the test baseline cannot be checked.'
} else {
    $verifiedText = Get-Content -Raw -LiteralPath $verifiedPath
    if ($null -eq $verifiedText) { $verifiedText = '' }
    $sectionMatch = [regex]::Match($verifiedText, '(?s)## Recorded test baseline\b(.*?)(?:\r?\n## |\z)')
    if (-not $sectionMatch.Success) {
        $problems += ".ai/project/VERIFIED.md has no 'Recorded test baseline' section."
    } else {
        $baselineSectionFound = $true
        $rowPattern = '(?m)^\|\s*`?([A-Za-z0-9_.\\/-]+\.csproj)`?\s*\|'
        foreach ($rowMatch in [regex]::Matches($sectionMatch.Groups[1].Value, $rowPattern)) {
            [void]$baselinePaths.Add($rowMatch.Groups[1].Value)
        }
    }
}

if ($slnExists) {
    $solutionByKey = @{}
    foreach ($solutionTestPath in $solutionTestPaths) {
        $solutionKey = ConvertTo-ComparableRepoPath $solutionTestPath
        if ($solutionByKey.ContainsKey($solutionKey)) {
            $problems += "DiPro.sln repeats test project '$solutionTestPath'."
        } else {
            $solutionByKey[$solutionKey] = $solutionTestPath
        }
    }
    if ($baselineSectionFound) {
        $baselineByKey = @{}
        foreach ($baselinePath in $baselinePaths) {
            $baselineKey = ConvertTo-ComparableRepoPath $baselinePath
            if ($baselineByKey.ContainsKey($baselineKey)) {
                $problems += ".ai/project/VERIFIED.md repeats baseline row '$baselinePath'."
            } else {
                $baselineByKey[$baselineKey] = $baselinePath
            }
        }
        foreach ($solutionKey in @($solutionByKey.Keys)) {
            if (-not $baselineByKey.ContainsKey($solutionKey)) {
                $problems += "Solution test project '$($solutionByKey[$solutionKey])' has no baseline row in .ai/project/VERIFIED.md."
            }
        }
        foreach ($baselineKey in @($baselineByKey.Keys)) {
            if (-not $solutionByKey.ContainsKey($baselineKey)) {
                $problems += ".ai/project/VERIFIED.md baseline row '$($baselineByKey[$baselineKey])' is not a solution test project."
            }
        }
    }
}

if (-not $Quiet) {
    Write-Host "Checked solution inventory: $entryCount entries, $csharpCount C# project(s), $folderCount solution folder(s); $($solutionTestPaths.Count) solution test project(s) against $($baselinePaths.Count) baseline row(s)."
}

# --- Report ---------------------------------------------------------------
if (Test-Path (Join-Path $repoRoot '.ai/agents.json') -PathType Leaf) {
    foreach ($hookPath in @('.cursor/hooks.json', '.github/hooks/agent-kit-sync.json')) {
        $hookFile = Join-Path $repoRoot $hookPath
        if (-not (Test-Path -LiteralPath $hookFile -PathType Leaf)) {
            $problems += "Missing session synchronization hook: $hookPath"
            continue
        }
        try {
            $hookConfig = Get-Content -Raw -LiteralPath $hookFile | ConvertFrom-Json
            if ($hookConfig.version -ne 1 -or -not $hookConfig.hooks.sessionStart) {
                $problems += "Invalid sessionStart configuration in $hookPath"
            }
            $hookCommands = @($hookConfig.hooks.sessionStart | ForEach-Object { $_.command; $_.powershell; $_.bash })
            if (-not ($hookCommands | Where-Object { $_ -match 'scripts/sync-agent-session-hook\.ps1' })) {
                $problems += "$hookPath does not invoke the shared synchronization wrapper."
            }
        } catch { $problems += "Invalid hook JSON in $hookPath" }
    }
    if (-not (Test-Path (Join-Path $PSScriptRoot 'sync-agent-session-hook.ps1') -PathType Leaf)) {
        $problems += 'Shared session synchronization wrapper is missing.'
    }
}

if (Test-Path (Join-Path $repoRoot '.ai/agents.json') -PathType Leaf) {
    & (Join-Path $PSScriptRoot 'sync-agent-profiles.ps1') -CheckOnly
    if ($LASTEXITCODE -ne 0) { $problems += 'Copilot/Cursor profiles or rules are out of sync with shared sources.' }
}

if ($problems.Count -gt 0) {
    foreach ($p in $problems) {
        Write-Warning $p
    }
    Write-Error "Agent kit self-check failed: $($problems.Count) problem(s) found."
    exit 1
}

Write-Host 'Agent kit self-check passed: all links, role references, applyTo globs, genericity, subagent references, retired-family, section-reference, CI image, tool-boundary, size-budget, script-reference, routing-evaluation, PowerShell-syntax, and solution-inventory checks are clean.'
exit 0
