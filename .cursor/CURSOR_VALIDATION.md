# Cursor validation

Configuration formats were checked against official documentation on 2026-10-09. Cursor runtime scenarios E2, E4, E9, E12, and E16 were observed on 2026-10-20. E9 did not meet its no-delegation precondition. The first two E12 runs failed to report the pre-existing failure. The third E12 run passed. E16 passed. The remaining checklist items are still open. Keep that distinction when reporting readiness.

## Checklist

1. Open the repository in Cursor Agent mode. Record Cursor version, surface (editor/CLI/cloud), kit revision, and account model access.
2. Run `scripts/sync-agent-profiles.ps1 -CheckOnly`, `scripts/sync-skills.ps1 -CheckOnly` and `scripts/check-agent-kit.ps1`; record actual exit codes. Start a fresh chat after generating profiles.
3. Confirm seven specialists are discoverable and the main agent acts as Coordinator. Explicitly invoke Architect and Verifier once and inspect task cards; profile existence alone is not evidence of invocation.
4. Check Architect/Reviewer read-only enforcement in a disposable fixture. Confirm Verifier can run a local build/test and create outputs while leaving source untouched. Implementer terminal restrictions are instructions, not an enforced allowlist.
5. Run relevant `.ai/EVALS.md` scenarios: E1b/E2/E3/E4 for routing, baseline, verification and independent review; E9 for fallback; E12-E15 for failure paths; E16/E17 for drift and host switching. Adapt roles through the Cursor map. Heavy review expects the pinned GPT reviewer after the Claude implementer. A parent-model task card is Partial when disclosed, and a Fail when the report claims the pinned pairing ran. The parent writing implementation files fails a scenario whose route names an implementer.
6. Confirm generated glob rules attach for representative source paths and cause the canonical instructions to be read. Confirm a relevant project skill is available without contradictory duplicate copies.
7. Test a shared role/criterion update, role addition/removal and adapter change in a disposable checkout. Check drift fails, regenerate both hosts, inspect obsolete-file reporting, and confirm a new Cursor chat reads the updated state without Copilot history.
8. Confirm the pinned models in `.ai/adapters/cursor-models.json` on actual task cards: Fast for Utility, Verifier, and Implementer-Light; Claude Sonnet for Implementer; Claude Opus for Architect; GPT for Reviewer. Disclose fallback. Rerun affected scenarios after meaningful kit or model changes.
9. Verify `.cursor/hooks.json` is discovered and the session-start command fires in a new chat. Inspect hook diagnostics and test regeneration/failure reporting in a disposable fixture. Its asynchronous response does not block session creation or refresh cached profiles; retain the first-implementation check. See `.ai/adapters/SESSION_HOOKS.md`.

Record detailed per-scenario evidence in `.ai/project/EVALS_LOG.md`. Keep model access/date in the local adapter map. Do not mark runtime validation passed merely because static checks pass.

## Validation log

| Date | Surface/version | Kit revision | Capability/scenarios | Result | Evidence |
|---|---|---|---|---|---|
| 2026-10-20 | Cursor Agent, version not recorded | `62d9eaa8` | E2 | Pass | `.ai/project/EVALS_LOG.md`; transcript `55e1ae79-3d0a-41ae-9f33-25de286326b9` |
| 2026-10-20 | Cursor Agent, version not recorded | `62d9eaa8` | E4 | Pass | `.ai/project/EVALS_LOG.md`; transcript `4d745652-0ef8-445d-94f0-ca1ee3402f03` |
| 2026-10-20 | Cursor Agent, version not recorded | `62d9eaa8` | E9 | Not evaluated | `.ai/project/EVALS_LOG.md`; transcript `3adabd2d-b58e-4e66-b29c-0fefe8d3e4c6` |
| 2026-10-20 | Cursor Agent, version not recorded | `62d9eaa8` | E12 | Fail | `.ai/project/EVALS_LOG.md`; transcript `e09dc39a-ab68-4dd0-9c1f-d64927eccaf7` |
| 2026-10-20 | Cursor Agent, version not recorded | `62d9eaa8` plus uncommitted reporting instruction | E12 rerun | Fail | `.ai/project/EVALS_LOG.md`; transcript `bc3f5ec1-285b-4833-88e2-4752790978a6` |
| 2026-10-20 | Cursor Agent, version not recorded | `62d9eaa8` plus uncommitted `git status` instruction | E12 rerun | Pass | `.ai/project/EVALS_LOG.md`; transcript `1f636f34-af6e-410c-a95c-225ab3568713` |
| 2026-10-21 | Cursor Agent, version not recorded | uncommitted | Model pins | Not evaluated | `.ai/adapters/cursor-models.json` pins Fast roles to `cursor-grok-4.6-high-fast`, Implementer to `claude-sonnet-5-5-high`, Architect to `claude-opus-5-5-medium`, and Reviewer to `gpt-5.6-sol-medium`. PO/BM inherits. Task-card selection has not been observed. |
| 2026-10-21 | Review chat, not a fresh Coordinator chat | uncommitted policy edit | E3, E4, E8, E12 | Not evaluated | Dirty-test names, the Cursor load path, stricter Heavy scoring, and the single size scale were edited. Specified Heavy was added in that chat and removed before any scenario run. No fresh-chat task cards were observed. |
| 2026-10-20 | Cursor Agent, version not recorded | `62d9eaa8` | E16 | Pass | `.ai/project/EVALS_LOG.md`; transcript `e2fcd499-3e94-4c34-980d-4ad3ed006218` |
