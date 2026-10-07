<#
.SYNOPSIS
    Pins each Copilot agent profile to the model named in the adapter map and
    validates the map itself.

.DESCRIPTION
    The single source of truth for which model each profile uses is
    .ai/adapters/copilot-models.json. This script writes the matching
    "model:" line into the front matter of every .github/agents/*.agent.md
    profile, so a model change is made in one place and never hand-edited.

    It also validates the map:
      - every profile has an entry, and every entry has a profile;
      - every tier a profile points to exists and lists qualified model
        names of the form "Model Name (copilot)";
      - no model belongs to a retired family (see "retiredFamilies");
      - profiles ending in -Claude or -GPT use a tier of that family, which
        protects the cross-family review rule;
      - warns (does not fail) when the map is older than "staleAfterDays".

    Run without -CheckOnly to rewrite drifted "model:" lines. Use -CheckOnly
    in CI and the pre-commit hook to detect drift without writing files.

.PARAMETER CheckOnly
    Compare profiles against the map without writing files. Exits with code 1
    if a profile has drifted or the map is invalid.

.EXAMPLE
    pwsh scripts/sync-agent-models.ps1
    pwsh scripts/sync-agent-models.ps1 -CheckOnly
#>
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$mapFile = Join-Path $repoRoot '.ai/adapters/copilot-models.json'
$agentsDir = Join-Path $repoRoot '.github/agents'

if (-not (Test-Path $mapFile -PathType Leaf)) {
    Write-Error "Model map not found: $mapFile"
    exit 1
}

$map = Get-Content -Raw -Path $mapFile | ConvertFrom-Json
$problems = @()
$driftFound = $false
$syncedCount = 0

# --- Validate tiers -----------------------------------------------------
$tierModels = @{}
foreach ($tier in $map.tiers.PSObject.Properties) {
    $models = @($tier.Value)
    if ($models.Count -eq 0) {
        $problems += "Tier '$($tier.Name)' lists no models."
        continue
    }
    foreach ($model in $models) {
        if ($model -notmatch '^.+ \(copilot\)$') {
            $problems += "Tier '$($tier.Name)': model '$model' must use the qualified form 'Model Name (copilot)'."
        }
        foreach ($retired in @($map.retiredFamilies)) {
            if ($retired -and ($model -match [regex]::Escape($retired))) {
                $problems += "Tier '$($tier.Name)': model '$model' belongs to the retired family '$retired'."
            }
        }
    }
    $tierModels[$tier.Name] = $models
}

# --- Staleness warning (non-fatal) ----------------------------------------
try {
    $verified = [datetime]$map.verifiedOn
    $ageDays = [int]((Get-Date) - $verified).TotalDays
    if ($ageDays -gt [int]$map.staleAfterDays) {
        Write-Warning "Model map was last verified $ageDays day(s) ago (limit $($map.staleAfterDays)). Re-check the Copilot model picker and update verifiedOn."
    }
} catch {
    $problems += "Model map 'verifiedOn' is missing or not a valid date."
}

# --- Sync / check each profile ------------------------------------------
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$profileFiles = @(Get-ChildItem -Path $agentsDir -Filter '*.agent.md' -File -ErrorAction SilentlyContinue)

foreach ($file in $profileFiles) {
    $content = Get-Content -Raw -Path $file.FullName
    $fm = [regex]::Match($content, '(?s)\A---\r?\n(.*?)\r?\n---')
    if (-not $fm.Success) {
        $problems += "Profile $($file.Name) has no YAML front matter."
        continue
    }
    $frontMatter = $fm.Groups[1].Value
    $nameMatch = [regex]::Match($frontMatter, '(?m)^name:\s*(.+?)\s*$')
    if (-not $nameMatch.Success) {
        $problems += "Profile $($file.Name) has no 'name:' entry."
        continue
    }
    $profileName = $nameMatch.Groups[1].Value.Trim().Trim('"', "'")
    [void]$seen.Add($profileName)

    $tierProp = $map.profiles.PSObject.Properties[$profileName]
    if (-not $tierProp) {
        $problems += "Profile '$profileName' ($($file.Name)) has no entry in .ai/adapters/copilot-models.json."
        continue
    }
    $tierName = [string]$tierProp.Value
    if (-not $tierModels.ContainsKey($tierName)) {
        $problems += "Profile '$profileName' points to unknown tier '$tierName'."
        continue
    }

    $familyMatch = [regex]::Match($profileName, '-(Claude|GPT)$')
    if ($familyMatch.Success) {
        $family = $familyMatch.Groups[1].Value.ToLowerInvariant()
        if (-not $tierName.StartsWith("$family-")) {
            $problems += "Profile '$profileName' must use a '$family-*' tier (cross-family review rule) but uses '$tierName'."
        }
    }

    $models = @($tierModels[$tierName])
    if ($models.Count -eq 1) {
        $desired = "model: '$($models[0])'"
    } else {
        $quoted = @($models | ForEach-Object { "'$_'" })
        $desired = 'model: [' + ($quoted -join ', ') + ']'
    }

    $existing = [regex]::Match($frontMatter, '(?m)^model:[^\r\n]*')
    if ($existing.Success -and $existing.Value -ceq $desired) {
        continue
    }

    if ($CheckOnly) {
        $driftFound = $true
        if ($existing.Success) {
            Write-Warning "Drift: $($file.Name) has '$($existing.Value)' but the map requires '$desired'."
        } else {
            Write-Warning "Missing: $($file.Name) has no 'model:' line; the map requires '$desired'."
        }
        continue
    }

    if ($existing.Success) {
        $start = $fm.Groups[1].Index + $existing.Index
        $updated = $content.Remove($start, $existing.Length).Insert($start, $desired)
    } else {
        $insertAt = $fm.Groups[1].Index + $fm.Groups[1].Length
        $updated = $content.Insert($insertAt, "`n$desired")
    }
    Set-Content -Path $file.FullName -Value $updated -NoNewline
    $syncedCount++
    Write-Host "Synced $($file.Name) -> $desired"
}

# --- Map entries without a profile --------------------------------------
foreach ($entry in $map.profiles.PSObject.Properties) {
    if (-not $seen.Contains($entry.Name)) {
        $problems += "The model map lists profile '$($entry.Name)' but no .github/agents/*.agent.md declares that name."
    }
}

# --- Report ---------------------------------------------------------------
if ($problems.Count -gt 0) {
    foreach ($p in $problems) {
        Write-Warning $p
    }
    Write-Error "Model map check failed: $($problems.Count) problem(s) found."
    exit 1
}

if ($CheckOnly) {
    if ($driftFound) {
        Write-Error 'Agent model pins are out of sync with .ai/adapters/copilot-models.json. Run scripts/sync-agent-models.ps1 and re-stage the profiles.'
        exit 1
    }
    Write-Host "All $($profileFiles.Count) agent profile(s) match the model map."
    exit 0
}

if ($syncedCount -eq 0) {
    Write-Host 'All agent profiles already match the model map. Nothing to do.'
} else {
    Write-Host "Synced $syncedCount profile(s)."
}
exit 0
