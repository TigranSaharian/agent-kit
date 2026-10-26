<#
.SYNOPSIS
    Exercises adapter generation in a disposable fixture without changing the checkout.
.DESCRIPTION
    Uses PowerShell and filesystem fixtures, with no external test framework or network.
    Covers drift, idempotence, shared updates, membership, collisions and orphan safety.
#>
$ErrorActionPreference = 'Stop'
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Host "PowerShell 7 (pwsh) is required to run scripts/test-agent-adapters.ps1. Install PowerShell 7 and rerun. scripts/sync-agent-profiles.ps1 -CheckOnly can run under Windows PowerShell."
    exit 1
}
$repoRoot = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('agent-kit-fixture-' + [guid]::NewGuid().ToString('N'))
$fixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
$passed = 0

function Write-Fixture([string]$RelativePath, [string]$Content) {
    $path = Join-Path $fixtureRoot $RelativePath
    [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}
function Read-Fixture([string]$RelativePath) {
    return [IO.File]::ReadAllText((Join-Path $fixtureRoot $RelativePath))
}
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Run-Sync([bool]$CheckOnly, [int]$ExpectedExit, [string]$Label) {
    $arguments = @('-NoProfile', '-File', (Join-Path $fixtureRoot 'scripts/sync-agent-profiles.ps1'))
    if ($CheckOnly) { $arguments += '-CheckOnly' }
    $output = & pwsh @arguments 2>&1
    $actualExit = $LASTEXITCODE
    Assert-True ($actualExit -eq $ExpectedExit) "$Label expected exit $ExpectedExit, got $actualExit`: $output"
}
function Passed([string]$Label) {
    $script:passed++
    Write-Host "PASS $Label"
}
function Run-Hook([string]$HookHost, [string]$Payload) {
    $hookArguments = @('-NoProfile', '-File', (Join-Path $fixtureRoot 'scripts/sync-agent-session-hook.ps1'), '-HookHost', $HookHost)
    $hookOutput = $Payload | & pwsh @hookArguments 2>&1
    Assert-True ($LASTEXITCODE -eq 0) "Hook transport failed: $hookOutput"
    # Any extra stdout (for example the generator's progress) makes this invalid JSON.
    return (($hookOutput -join "`n") | ConvertFrom-Json)
}

try {
    [IO.Directory]::CreateDirectory($fixtureRoot) | Out-Null
    foreach ($relativePath in @('AGENTS.md', '.ai', '.github/agents', '.github/instructions', '.github/hooks', '.cursor', 'scripts/sync-agent-profiles.ps1', 'scripts/sync-agent-session-hook.ps1')) {
        $source = Join-Path $repoRoot $relativePath
        $destination = Join-Path $fixtureRoot $relativePath
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Recurse
    }
    Run-Sync $true 0 'Initial consistency'
    Passed 'initial adapters are consistent'
    if (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
        $legacyOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixtureRoot 'scripts/sync-agent-profiles.ps1') -CheckOnly 2>&1
        Assert-True ($LASTEXITCODE -eq 0) "Windows PowerShell disagrees with the PowerShell 7 fingerprint: $legacyOutput"
        Passed 'Windows PowerShell and PowerShell 7 agree on fingerprints'
    }
    $originalProfile = Read-Fixture '.cursor/agents/architect.md'
    Run-Sync $false 0 'Idempotence'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq $originalProfile) 'No-op sync rewrote content.'
    Passed 'generation is idempotent'

    $role = Read-Fixture '.ai/roles/architect.md'
    Write-Fixture '.ai/roles/architect.md' ($role + "`nFixture criterion.`n")
    Run-Sync $true 1 'Shared-role drift'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq $originalProfile) 'CheckOnly changed an output.'
    Run-Sync $false 0 'Shared-role sync'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -cne $originalProfile) 'Cursor did not notice shared-role change.'
    Assert-True ((Read-Fixture '.github/agents/architect.agent.md').Contains('Fixture criterion.')) 'Copilot profile did not embed the updated role text.'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md').Contains('Fixture criterion.')) 'Cursor profile did not embed the updated role text.'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md').Contains('## Delegate contract')) 'Cursor profile is missing the delegate contract.'
    Assert-True (-not (Read-Fixture '.cursor/agents/architect.md').Contains('shared workflow')) 'Delegate profile still requires reading the shared workflow.'
    Run-Sync $true 0 'Shared-role consistency'
    Passed 'shared-role drift is detected and the updated role text is embedded in both hosts'

    $instruction = Read-Fixture '.github/instructions/tests.instructions.md'
    Write-Fixture '.github/instructions/tests.instructions.md' ($instruction.Replace('**/*Tests/**/*.cs', '**/*Specs/**/*.cs'))
    Run-Sync $true 1 'Instruction drift'
    Run-Sync $false 0 'Instruction sync'
    Assert-True ((Read-Fixture '.cursor/rules/tests.mdc').Contains('**/*Specs/**/*.cs')) 'Cursor glob did not update.'
    Passed 'canonical instruction globs synchronize'

    $generated = Read-Fixture '.cursor/agents/architect.md'
    Write-Fixture '.cursor/agents/architect.md' ($generated + "`nLocal drift.`n")
    Run-Sync $true 1 'Output drift'
    Run-Sync $false 0 'Output repair'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq $generated) 'Managed drift was not repaired.'
    Passed 'managed output edits are detected and repaired'

    $custom = "---`nname: custom-helper`n---`nUser-owned agent.`n"
    Write-Fixture '.cursor/agents/custom-helper.md' $custom
    Run-Sync $false 0 'Custom-agent preservation'
    Assert-True ((Read-Fixture '.cursor/agents/custom-helper.md') -ceq $custom) 'Custom agent was changed.'
    Passed 'unrelated custom agents survive'

    Write-Fixture '.cursor/agents/architect.md' 'User-owned collision'
    Run-Sync $false 1 'Collision refusal'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq 'User-owned collision') 'Unmanaged collision was overwritten.'
    Write-Fixture '.cursor/agents/architect.md' $generated
    Passed 'unmarked collisions are not overwritten'

    $registryText = Read-Fixture '.ai/agents.json'
    $copilotText = Read-Fixture '.ai/adapters/copilot.json'
    $cursorText = Read-Fixture '.ai/adapters/cursor.json'
    $copilotModelsText = Read-Fixture '.ai/adapters/copilot-models.json'
    $cursorModelsText = Read-Fixture '.ai/adapters/cursor-models.json'
    $registry = $registryText | ConvertFrom-Json
    $registry.agents += [pscustomobject]@{ id = 'fixture-agent'; role = '.ai/roles/utility.md'; description = 'Fixture role.' }
    Write-Fixture '.ai/agents.json' ($registry | ConvertTo-Json -Depth 20)
    Run-Sync $false 1 'Missing host mappings'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq $generated) 'Invalid config caused partial writes.'
    Passed 'new logical roles require both host mappings before writes'

    $copilot = $copilotText | ConvertFrom-Json
    $copilot.profiles += [pscustomobject]@{ id = 'fixture-agent'; agent = 'fixture-agent'; name = 'Fixture-Agent'; tools = @('read', 'search') }
    $cursor = $cursorText | ConvertFrom-Json
    $cursor.profiles += [pscustomobject]@{ id = 'fixture-agent'; agent = 'fixture-agent'; readonly = $false }
    $copilotModels = $copilotModelsText | ConvertFrom-Json
    $copilotModels.profiles | Add-Member -NotePropertyName 'Fixture-Agent' -NotePropertyValue 'gpt-light'
    $cursorModels = $cursorModelsText | ConvertFrom-Json
    $cursorModels.profiles | Add-Member -NotePropertyName 'fixture-agent' -NotePropertyValue 'inherit'
    Write-Fixture '.ai/adapters/copilot.json' ($copilot | ConvertTo-Json -Depth 20)
    Write-Fixture '.ai/adapters/cursor.json' ($cursor | ConvertTo-Json -Depth 20)
    Write-Fixture '.ai/adapters/copilot-models.json' ($copilotModels | ConvertTo-Json -Depth 20)
    Write-Fixture '.ai/adapters/cursor-models.json' ($cursorModels | ConvertTo-Json -Depth 20)
    Run-Sync $false 0 'Membership addition'
    Assert-True (Test-Path -LiteralPath (Join-Path $fixtureRoot '.cursor/agents/fixture-agent.md')) 'Cursor role was not added.'
    Assert-True ((Read-Fixture '.github/agents/coordinator.agent.md').Contains('Fixture-Agent')) 'Coordinator list did not update.'
    Run-Sync $true 0 'Added role consistency'
    Passed 'role additions update both hosts and Coordinator discovery'

    Write-Fixture '.ai/agents.json' $registryText
    Write-Fixture '.ai/adapters/copilot.json' $copilotText
    Write-Fixture '.ai/adapters/cursor.json' $cursorText
    Write-Fixture '.ai/adapters/copilot-models.json' $copilotModelsText
    Write-Fixture '.ai/adapters/cursor-models.json' $cursorModelsText
    Run-Sync $true 1 'Removed-role orphan check'
    Run-Sync $false 1 'Removed-role orphan sync'
    Assert-True (Test-Path -LiteralPath (Join-Path $fixtureRoot '.cursor/agents/fixture-agent.md')) 'Sync deleted an orphan.'
    Passed 'removed generated agents are reported and retained for review'

    # These exact fixture-owned files are deliberately removed, not by the generator.
    Remove-Item -LiteralPath (Join-Path $fixtureRoot '.cursor/agents/fixture-agent.md')
    Remove-Item -LiteralPath (Join-Path $fixtureRoot '.github/agents/fixture-agent.agent.md')
    Run-Sync $false 0 'After deliberate orphan removal'
    Run-Sync $true 0 'Final consistency'
    Passed 'synchronization recovers after deliberate orphan removal'

    $cursorHookConfig = (Read-Fixture '.cursor/hooks.json') | ConvertFrom-Json
    $copilotHookConfig = (Read-Fixture '.github/hooks/agent-kit-sync.json') | ConvertFrom-Json
    Assert-True ($cursorHookConfig.version -eq 1 -and $cursorHookConfig.hooks.sessionStart.Count -eq 1) 'Cursor hook schema/entry changed.'
    Assert-True ($cursorHookConfig.hooks.sessionStart[0].command.Contains('powershell.exe') -and $cursorHookConfig.hooks.sessionStart[0].command.Contains('sync-agent-session-hook.ps1 -HookHost Cursor')) 'Cursor hook is not connected to the Windows wrapper.'
    Assert-True ($copilotHookConfig.version -eq 1 -and $copilotHookConfig.hooks.sessionStart.Count -eq 1) 'Copilot hook schema/entry changed.'
    Assert-True ($copilotHookConfig.hooks.sessionStart[0].powershell.Contains('sync-agent-session-hook.ps1 -HookHost Copilot')) 'Copilot Windows wrapper is not connected.'
    Passed 'both hook configurations reference the shared wrapper'

    $beforeHook = Read-Fixture '.cursor/agents/architect.md'
    $hookResponse = Run-Hook 'Cursor' '{"session_id":"fixture","composer_mode":"agent","cwd":"../ignored"}'
    Assert-True ($hookResponse.additional_context.StartsWith('Agent-kit session hook synchronized')) 'Cursor success context is missing.'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq $beforeHook) 'Consistent session hook rewrote content.'
    Passed 'Cursor hook returns clean JSON and leaves consistent outputs unchanged'

    Write-Fixture '.ai/roles/architect.md' ((Read-Fixture '.ai/roles/architect.md') + "`nSession hook criterion.`n")
    $hookResponse = Run-Hook 'Cursor' '{"session_id":"fixture"}'
    Assert-True ($hookResponse.additional_context.StartsWith('Agent-kit session hook synchronized')) 'Hook did not synchronize role drift.'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -cne $beforeHook) 'Hook did not update stale profiles.'
    Run-Sync $true 0 'Hook synchronized drift'
    Passed 'session hook automatically repairs shared-policy drift'

    $hookResponse = Run-Hook 'Copilot' '{"sessionId":"fixture","cwd":"../ignored","source":"startup"}'
    Assert-True ($hookResponse.additionalContext.StartsWith('Agent-kit session hook synchronized')) 'Copilot camelCase output is wrong.'
    $hookResponse = Run-Hook 'Copilot' '{"hook_event_name":"SessionStart","session_id":"fixture","source":"new"}'
    Assert-True ($hookResponse.hookSpecificOutput.hookEventName -eq 'SessionStart' -and $hookResponse.hookSpecificOutput.additionalContext.StartsWith('Agent-kit session hook synchronized')) 'VS Code Local output is wrong.'
    Passed 'Copilot CLI and VS Code Local payloads receive their own output schemas'

    $beforeHook = Read-Fixture '.cursor/agents/architect.md'
    $hookResponse = Run-Hook 'Cursor' '{invalid'
    Assert-True ($hookResponse.additional_context.StartsWith('Agent-kit automatic synchronization did not complete')) 'Malformed input was presented as success.'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq $beforeHook) 'Malformed hook input changed outputs.'
    Passed 'invalid hook input reports failure without writes'

    Write-Fixture '.cursor/agents/architect.md' 'User-owned hook collision'
    $hookResponse = Run-Hook 'Cursor' '{}'
    Assert-True ($hookResponse.additional_context.StartsWith('Agent-kit automatic synchronization did not complete')) 'Failed sync was presented as success.'
    Assert-True ((Read-Fixture '.cursor/agents/architect.md') -ceq 'User-owned hook collision') 'Hook overwrote an unmanaged collision.'
    Write-Fixture '.cursor/agents/architect.md' $beforeHook
    Passed 'hook reports sync failures and preserves collisions'

    $cursor = $cursorText | ConvertFrom-Json
    $cursor.profiles[0].id = '../escape'
    Write-Fixture '.ai/adapters/cursor.json' ($cursor | ConvertTo-Json -Depth 20)
    Run-Sync $false 1 'Invalid path ID'
    Passed 'invalid path IDs are rejected'
    Write-Host "Adapter fixture tests passed: $passed passed, 0 failed."
} finally {
    # Verify the absolute target stays in our exact temporary fixture before recursive cleanup.
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    if (-not $resolvedFixture.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        (Split-Path -Leaf $resolvedFixture) -notmatch '^agent-kit-fixture-[a-f0-9]{32}$') {
        throw 'Refusing cleanup outside the verified fixture directory.'
    }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}
