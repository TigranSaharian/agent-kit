<#
.SYNOPSIS
    Flags changes to protected, high-impact paths that carry no recorded
    approval.

.DESCRIPTION
    Reads path rules from .ai/project/PROTECTED_PATHS.txt, one per line:

        glob => reason
        glob => reason => regex

    Lines starting with '#' and blank lines are ignored. Globs use '*'
    (within a directory), '**' (across directories), and '?'. The optional
    regex is matched against the added/removed lines of the file's diff, so a
    rule such as "**/*.csproj" can fire only when a package reference
    changes, not on every project-file edit.

    The set of changed files is the diff between a base and HEAD:
      - in a merge request pipeline, the merge request's diff base;
      - in a branch pipeline, the commit before the push;
      - otherwise, the previous commit (or whatever -BaseRef names).

    A hit is accepted as approved when either the merge request carries the
    approval label (CI_MERGE_REQUEST_LABELS), or any commit in the range has a
    "High-Impact-Approved: <who / why>" trailer. Unapproved hits fail the
    script with exit code 1.

    This is a speed bump and an audit trail, not authorization: anyone who
    can add a label or write a commit message can satisfy it. Pair it with
    CODEOWNERS or merge-request approval rules for real gating. It cannot
    detect triggers that are not tied to a path (for example authorization
    behavior or retry settings inside an otherwise unprotected file); those
    rely on the project guardrails and review.

.PARAMETER BaseRef
    Commit or ref to diff against. Defaults from the CI environment.

.PARAMETER HeadRef
    Commit or ref to diff to. Default: HEAD.

.PARAMETER RulesFile
    Rules file. Default: .ai/project/PROTECTED_PATHS.txt. If it does not
    exist, nothing is checked and the script exits 0.

.PARAMETER ApprovalLabel
    Merge request label that counts as approval. Default: high-impact-approved.

.PARAMETER ApprovalTrailer
    Commit trailer key that counts as approval. Default: High-Impact-Approved.

.PARAMETER ChangedFiles
    Check this explicit list of repository-relative paths instead of asking
    git. Rules with a diff regex are treated as triggered. Useful for trying
    out a rules file.

.EXAMPLE
    pwsh scripts/check-protected-paths.ps1
    pwsh scripts/check-protected-paths.ps1 -ChangedFiles 'Foo/Migrations/001.cs','README.md'
#>
param(
    [string]$BaseRef = '',
    [string]$HeadRef = 'HEAD',
    [string]$RulesFile = '',
    [string]$ApprovalLabel = 'high-impact-approved',
    [string]$ApprovalTrailer = 'High-Impact-Approved',
    [string[]]$ChangedFiles = @()
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $RulesFile) {
    $RulesFile = Join-Path $repoRoot '.ai/project/PROTECTED_PATHS.txt'
}

function ConvertTo-GlobRegex {
    param([string]$Glob)
    $g = $Glob.Replace('\', '/')
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('^')
    $i = 0
    while ($i -lt $g.Length) {
        $c = [string]$g[$i]
        if ($c -eq '*') {
            if (($i + 1 -lt $g.Length) -and ([string]$g[$i + 1] -eq '*')) {
                if (($i + 2 -lt $g.Length) -and ([string]$g[$i + 2] -eq '/')) {
                    [void]$sb.Append('(?:.*/)?')
                    $i += 3
                } else {
                    [void]$sb.Append('.*')
                    $i += 2
                }
            } else {
                [void]$sb.Append('[^/]*')
                $i += 1
            }
        } elseif ($c -eq '?') {
            [void]$sb.Append('[^/]')
            $i += 1
        } else {
            [void]$sb.Append([regex]::Escape($c))
            $i += 1
        }
    }
    [void]$sb.Append('$')
    return $sb.ToString()
}

function Invoke-Git {
    param([string[]]$GitArgs)
    $output = @(& git @GitArgs 2>&1 | ForEach-Object { "$_" })
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed: $($output -join ' ')"
    }
    return $output
}

# --- Load rules --------------------------------------------------------------
if (-not (Test-Path $RulesFile -PathType Leaf)) {
    Write-Host "No protected-path rules file at $RulesFile; nothing to check."
    exit 0
}

$rules = @()
foreach ($rawLine in (Get-Content -Path $RulesFile)) {
    $line = $rawLine.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    $parts = @($line -split '\s=>\s')
    if ($parts.Count -lt 2) {
        Write-Error "Invalid rule '$line'. Expected: glob => reason [=> diff regex]"
        exit 1
    }
    $diffRegex = ''
    if ($parts.Count -ge 3) { $diffRegex = $parts[2].Trim() }
    $rules += [pscustomobject]@{
        Glob      = $parts[0].Trim()
        Regex     = ConvertTo-GlobRegex $parts[0].Trim()
        Reason    = $parts[1].Trim()
        DiffRegex = $diffRegex
    }
}
if ($rules.Count -eq 0) {
    Write-Host 'Rules file has no rules; nothing to check.'
    exit 0
}

# --- Determine changed files ---------------------------------------------------
$mergeBase = ''
if ($ChangedFiles.Count -gt 0) {
    $changed = @($ChangedFiles | ForEach-Object { $_.Replace('\', '/') })
} else {
    if (-not $BaseRef) {
        if ($env:CI_MERGE_REQUEST_DIFF_BASE_SHA) {
            $BaseRef = $env:CI_MERGE_REQUEST_DIFF_BASE_SHA
        } elseif ($env:CI_COMMIT_BEFORE_SHA -and ($env:CI_COMMIT_BEFORE_SHA -notmatch '^0+$')) {
            $BaseRef = $env:CI_COMMIT_BEFORE_SHA
        } elseif ($env:CI_MERGE_REQUEST_TARGET_BRANCH_NAME) {
            $BaseRef = "origin/$($env:CI_MERGE_REQUEST_TARGET_BRANCH_NAME)"
        } else {
            $BaseRef = "$HeadRef~1"
        }
    }
    $mergeBase = @(Invoke-Git @('merge-base', $BaseRef, $HeadRef))[0]
    $changed = @(Invoke-Git @('diff', '--no-renames', '--name-only', $mergeBase, $HeadRef) | Where-Object { $_ })
}

# --- Match changed files against rules --------------------------------------------
$hits = @()
foreach ($file in $changed) {
    foreach ($rule in $rules) {
        if ($file -notmatch $rule.Regex) { continue }
        if ($rule.DiffRegex -and $mergeBase) {
            $diffLines = @(Invoke-Git @('diff', '--no-renames', '-U0', $mergeBase, $HeadRef, '--', $file) |
                Where-Object { ($_ -match '^[+-]') -and ($_ -notmatch '^(\+\+\+|---)') })
            $touched = @($diffLines | Where-Object { $_ -match $rule.DiffRegex })
            if ($touched.Count -eq 0) { continue }
        }
        $hits += [pscustomobject]@{ File = $file; Reason = $rule.Reason }
        break
    }
}

if ($hits.Count -eq 0) {
    Write-Host "No protected paths changed ($($changed.Count) changed file(s) checked against $($rules.Count) rule(s))."
    exit 0
}

# --- Look for a recorded approval ----------------------------------------------------
$approvalSource = ''
if ($env:CI_MERGE_REQUEST_LABELS) {
    $labels = @($env:CI_MERGE_REQUEST_LABELS -split ',' | ForEach-Object { $_.Trim() })
    if ($labels -contains $ApprovalLabel) {
        $approvalSource = "merge request label '$ApprovalLabel'"
    }
}
if (-not $approvalSource -and $mergeBase) {
    $messages = (Invoke-Git @('log', '--format=%B', "$mergeBase..$HeadRef")) -join "`n"
    if ($messages -match ('(?im)^' + [regex]::Escape($ApprovalTrailer) + ':\s*\S')) {
        $approvalSource = "commit trailer '$ApprovalTrailer'"
    }
}

foreach ($hit in $hits) {
    Write-Host "Protected: $($hit.File)  [$($hit.Reason)]"
}

if ($approvalSource) {
    Write-Host "Approval recorded via $approvalSource; $($hits.Count) protected file(s) changed."
    exit 0
}

Write-Warning "$($hits.Count) protected file(s) changed with no recorded approval."
Write-Error "Record approval with the '$ApprovalLabel' merge request label or a '$ApprovalTrailer: <who / why>' commit trailer, or revert the protected changes."
exit 1
