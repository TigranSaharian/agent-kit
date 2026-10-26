# Cursor adapter

The main Cursor agent is the Coordinator and follows `.ai/roles/coordinator.md` and `.ai/WORKFLOW.md`. `.cursor/rules/agent-kit.mdc` is the always-on entry rule. Specialists in `.cursor/agents/` are generated from `.ai/agents.json`, `.ai/adapters/cursor.json`, and `.ai/adapters/cursor-models.json`; each embeds its role text and the shared delegate contract, so delegates do not read the workflow before every run.

## Routing

Follow the weight table in `.ai/WORKFLOW.md`. This file names the Cursor specialists and the host limits. It does not restate the workflow.

| Weight | Cursor specialist |
|---|---|
| Mechanical | Parent edits directly; `utility` for bulk mechanical edits across many files |
| Light | `implementer-light` |
| Medium | `implementer` |
| Heavy | `architect`, then `implementer`, then `reviewer` |
| Baseline and long runs | `verifier` |

`po-bm` clarifies material business uncertainty. The parent sequences handoffs in the foreground, owns authorization and the final response, and never lets a delegate start another subagent.

The parent may run a single isolated test class, a single-project build, and the kit sync checks itself. It does not create or edit implementation files, including generated migrations. Use `verifier` for baselines and long suite or solution runs, so their output stays out of the parent's context and runs on a cheaper model. An implementation delegate never claims verification or review.

## Permissions

`architect`, `po-bm`, and `reviewer` are `readonly: true`. Implementers, `utility`, and `verifier` are writable; `verifier` needs to create build and test outputs. The no-commands rule for implementers and the no-source-edits rule for `verifier` are instructions, not enforced allowlists. Copilot profiles, tool lists, and model pins do not control Cursor.

## Models

`cursor-models.json` pins `utility`, `verifier`, and `implementer-light` to `cursor-grok-4.6-high-fast`, `implementer` to `claude-sonnet-5-5-high`, `architect` to `claude-opus-5-5-medium`, and `reviewer` to `gpt-5.6-sol-medium`. `po-bm` inherits the parent model. The IDs come from the subagent model list the runtime exposed on the `verifiedOn` date; confirm the model on task cards before claiming it ran, and disclose plan-driven fallback.

When a Heavy implementation needs a stronger model than the implementer pin, request it at invocation if the host allows it, or report the limitation. The reviewer pin is a different family from the implementer. If the task card shows the parent model instead, say that cross-family review did not happen.

## Synchronization

Run from the repository root:

```powershell
pwsh -NoProfile -File scripts/sync-agent-profiles.ps1
pwsh -NoProfile -File scripts/sync-agent-profiles.ps1 -CheckOnly
pwsh -NoProfile -File scripts/sync-skills.ps1 -CheckOnly
pwsh -NoProfile -File scripts/check-agent-kit.ps1
pwsh -NoProfile -File scripts/test-agent-adapters.ps1
```

Without PowerShell 7, use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-agent-profiles.ps1 -CheckOnly`, and omit `-CheckOnly` to regenerate; the override applies only to that process. The fixture test runner and CI require `pwsh`.

Sync detects drift, regenerates both hosts, generates Cursor glob rules that reference `.github/instructions/`, preserves unrelated custom profiles, never overwrites unmarked collisions, and reports obsolete generated files instead of deleting them. The `sessionStart` hook attempts the same sync (see `.ai/adapters/SESSION_HOOKS.md`); it is asynchronous, so the first-implementation check in the entry rule remains. Start a fresh chat after profile changes. Static checks do not prove runtime delegation, glob attachment, or enforcement; record runtime evidence in `.cursor/CURSOR_VALIDATION.md`.

## Skills

Canonical project skills live in `.ai/project/skills/`, with generated copies in `.agents/skills/` and `.claude/skills/`. Observed on 2026-10-09: Cursor listed the `.claude/skills/` copies with no duplicate entries; discovery of `.agents/skills/` was not observed.

## Documentation checked

Checked on 2026-10-09 against official [Cursor subagents](https://cursor.com/docs/subagents), [rules](https://cursor.com/docs/rules) and [skills](https://cursor.com/docs/skills). This confirms documented formats, not the owner's installed runtime.
