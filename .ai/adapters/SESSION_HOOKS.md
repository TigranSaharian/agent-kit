# Session synchronization hooks

`.cursor/hooks.json` and `.github/hooks/agent-kit-sync.json` call the same `scripts/sync-agent-session-hook.ps1`. On a supported new agent session it regenerates both managed adapters from canonical sources, then checks consistency. No writes happen when outputs already match. It never deletes orphans, adopts unmarked collisions, commits, stages, installs tools, imports chat history, or changes persistent execution policy. Synchronization can modify generated profiles/rules in the working tree; review those changes normally.

The wrapper consumes the hook payload without retaining prompts or trusting its paths. It resolves this checkout from its own script directory, uses the current PowerShell runtime, serializes simultaneous wrapper invocations, and emits only a JSON context response. Failures are reported as context rather than blocking the chat; run the ordinary check command for detailed diagnostics. This is adapter maintenance outside the model's role tool permissions.

## Supported configuration and limits

- Cursor's project hook uses Windows PowerShell, matching the current local setup where `pwsh` may be absent. Its `sessionStart` runs asynchronously and cannot block session creation. It is unavailable on hosted Cursor cloud agents; the existing first-implementation check remains necessary. This Windows command is not a portable Linux/macOS launcher.
- Copilot uses the documented compatible format (`version: 1`, `sessionStart`, `powershell`/`bash`, `timeoutSec`). VS Code Local maps that configuration to its own event/payload. The wrapper returns Local `hookSpecificOutput` for a `SessionStart` snake_case payload and top-level `additionalContext` for CLI/Agent Host camelCase payloads. The POSIX command requires `pwsh` to be installed; no cloud/runtime availability is presumed.
- Hook support, workspace trust, disabled hooks and runtime versions determine whether commands fire. No host settings have been modified to force hooks on. Visual Studio support is unverified; do not infer it from VS Code support.
- A hook updates files, not an editor's cached agent inventory. Reload or start a fresh session if profiles were added, removed or changed after discovery. Hooks run at session start, not on every edit or switch inside an already-open chat. Keep manual synchronization after shared changes and CI drift checks.

## Checking execution

Start a new Cursor or supported Copilot chat after reloading the hook configuration. Inspect the host's hook diagnostics/output to confirm the session hook was invoked. In a disposable checkout, change a shared role, start a new session, and confirm adapters regenerate and `-CheckOnly` passes. Also check the failure context for an unmarked collision or obsolete generated file. Record observed runtime evidence in the appropriate validation log; simulated payload tests are not proof that an editor fired an event.

For Windows manual diagnostics:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-agent-profiles.ps1 -CheckOnly
```

Official schemas checked on 2026-10-09: [Cursor hooks](https://cursor.com/docs/hooks), [VS Code hook configuration](https://code.visualstudio.com/docs/agent-customization/hooks), [Local hook reference](https://code.visualstudio.com/docs/agents/reference/hooks-reference), and [Copilot hook reference](https://docs.github.com/en/copilot/reference/hooks-reference). Installed-editor event firing remains to be verified.
