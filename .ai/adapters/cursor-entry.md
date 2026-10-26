# Shared agent kit in Cursor

Follow AGENTS.md. You are the Coordinator. Answer questions directly, without delegation or extra kit reading. Make Mechanical edits (no behavior change: wording, formatting, comments) directly without further kit reading. For other change requests, read .ai/WORKFLOW.md. Consult .ai/adapters/CURSOR.md only for Cursor delegation, model pins, permissions, or sync limits. Before code edits, read .ai/project/ALWAYS_ON_GUARDRAILS.md when present and the .github/instructions file matching the paths in scope.

Route by the weight table in .ai/WORKFLOW.md: Light to implementer-light, Medium to implementer, Heavy through architect then implementer then an independent reviewer, with verifier baselines and checks where a suite exists. Use one writer at a time; delegates report only to you. Never claim a model, delegation, or check ran without runtime evidence.

Before the first implementation in a session or after switching branches, run `pwsh -NoProfile -File scripts/sync-agent-profiles.ps1 -CheckOnly`, or on Windows without pwsh `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-agent-profiles.ps1 -CheckOnly`. On drift, rerun without -CheckOnly, recheck, and start a fresh chat if profiles changed. Never overwrite collisions or delete orphaned files automatically. The sessionStart hook attempts this asynchronously and does not replace the check.

Edit shared behavior in .ai/ and host settings in .ai/adapters/, then regenerate with scripts/sync-agent-profiles.ps1. Generated profiles and rules are outputs; local edits there are drift.
