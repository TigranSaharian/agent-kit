<#
.SYNOPSIS
    Synchronizes managed agent adapters when a supported host starts a session.
.DESCRIPTION
    Uses only canonical files in this checkout, ignores input paths/prompts,
    serializes simultaneous hook invocations, and emits host-specific JSON.
    Sync failures become context for the agent; this hook does not block a session.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Cursor', 'Copilot')]
    [string]$HookHost
)

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$mutex = $null
$lockHeld = $false
$hookPayload = $null
$context = $null

try {
    # Hosts close stdin after one JSON payload. Never retain or echo prompts,
    # transcript paths, credentials, or arbitrary workspace paths from it.
    $inputJson = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($inputJson)) { $hookPayload = $inputJson | ConvertFrom-Json }

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $rootBytes = [Text.Encoding]::UTF8.GetBytes($repoRoot.ToLowerInvariant())
        $lockId = ([BitConverter]::ToString($sha.ComputeHash($rootBytes))).Replace('-', '')
    } finally { $sha.Dispose() }
    $mutex = [Threading.Mutex]::new($false, ('AgentKitSessionSync-' + $lockId))
    try { $lockHeld = $mutex.WaitOne(15000) } catch [Threading.AbandonedMutexException] { $lockHeld = $true }
    if (-not $lockHeld) { throw 'Another sync hook is still running.' }

    # Launch the same runtime as this hook. Windows PowerShell works without pwsh.
    $runtime = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $syncScript = Join-Path $PSScriptRoot 'sync-agent-profiles.ps1'
    $arguments = @('-NoProfile')
    if ($env:OS -eq 'Windows_NT') { $arguments += @('-ExecutionPolicy', 'Bypass') }
    $arguments += @('-File', $syncScript)
    $syncOutput = & $runtime @arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Adapter generation failed.' }
    $checkOutput = & $runtime @arguments -CheckOnly 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Adapter consistency check failed.' }
    $context = 'Agent-kit session hook synchronized both host adapters and verified consistency. Read the current shared roles and project criteria. If profiles changed after this session loaded them, use a fresh session or reload to discover them; do not assume cached agents refreshed.'
} catch {
    $context = 'Agent-kit automatic synchronization did not complete. Run scripts/sync-agent-profiles.ps1 -CheckOnly for diagnostics and resolve collisions, obsolete outputs or invalid sources. Do not claim adapters are synchronized; check current guidance before implementation. Ordinary questions can continue.'
} finally {
    if ($lockHeld -and $mutex) { $mutex.ReleaseMutex() }
    if ($mutex) { $mutex.Dispose() }
}

if ($HookHost -eq 'Cursor') {
    $response = @{ additional_context = $context }
} elseif ($hookPayload -and $hookPayload.hook_event_name -eq 'SessionStart') {
    # VS Code Local maps Copilot-compatible config to its snake_case payload.
    $response = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $context } }
} else {
    # Copilot CLI/Agent Host receives camelCase input from the sessionStart entry.
    $response = @{ additionalContext = $context }
}
[Console]::Out.WriteLine(($response | ConvertTo-Json -Depth 5 -Compress))
exit 0
