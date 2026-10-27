# Copilot setup validation

This checklist verifies discovery and behavior separately. Run it for each Copilot surface you intend to use, and again after changing profiles, instructions, or host settings. Do not transfer a result from one surface to another.

## VS Code

1. Open the repository root and select the Copilot agent harness. Inspect **Chat: Open Customizations** diagnostics; confirm repository instructions, relevant path instructions, skills, and custom agent profiles load without errors.
2. Start a new chat with the **default Copilot agent**, without manually selecting Coordinator. Submit a small task that requires a decision and one specialist. Inspect agent/tool activity to determine whether the default agent follows the Coordinator workflow and routes appropriately.
3. If default startup does not reliably coordinate, select **Coordinator** in the agent picker and repeat the task. Record both outcomes. The selected Coordinator is the reliable fallback for this surface.
4. Confirm a delegated specialist received repository instructions and returned evidence; check acceptance criteria and final reporting.
5. In model controls, record the choices actually available. Try a low-risk Fast task and a representative high-impact Strong-tier simulation without touching production data; record whether selection was automatic, manually selected, or unavailable. Record whether a hard token/spend cap is configurable.

## Visual Studio Chat

1. Enable repository custom instructions under **Tools > Options > GitHub > Copilot > Copilot Chat**. Labels can vary by version.
2. Confirm `.github/copilot-instructions.md` appears in the response's **References** list. With a matching source file in context, confirm applicable `.github/instructions/*.instructions.md` guidance is reflected.
3. Visual Studio Chat supports repository-wide and path-specific instructions but does not load `AGENTS.md`. The root Copilot instructions point code-editing tasks to `.ai/project/ALWAYS_ON_GUARDRAILS.md`. This checklist validates instruction following in a single-agent chat; do not record custom-agent delegation as available unless the surface visibly supports and completes it.
4. Record actual model choices and token/spend controls from Visual Studio settings. If the default agent does not follow the coordinator procedure, record the limitation; do not imply that the Coordinator profile is active here.

## Copilot CLI

1. Start Copilot CLI in the repository. Use its `/agent` interface to confirm the Coordinator and intended specialists are discoverable.
2. Submit one bounded task in the default session, without selecting Coordinator, and inspect whether Coordinator is invoked or the root agent follows its workflow. Then select/invoke Coordinator explicitly and repeat if automatic routing is not reliable.
3. Confirm a specialist receives repository instructions and returns evidence. Record the automatic result and the explicit Coordinator fallback separately.
4. Record model choices and whether the CLI enforces a hard task token/spend cap. Do not infer either from profile text.

## GitHub.com Copilot cloud agent

1. Confirm repository-wide instructions and custom-agent profiles are available for the repository.
2. Submit a small, reversible task from the default cloud agent and inspect whether the Coordinator is automatically selected and can invoke the intended specialists. If the cloud surface does not support that hierarchy, record it as instruction-aware single-agent operation rather than full orchestration.
3. Record which model choices and token/spend controls are actually exposed. Do not assume the VS Code or CLI `agents`/tool behavior applies here.

## Pinned model smoke test

Run after changing `.ai/adapters/copilot-models.json`, after `scripts/sync-agent-models.ps1`, and whenever the model picker changes. Each profile is pinned to one tier; this checks that the pins load and are usable on the surface you intend to use. Do not transfer a result from one surface to another.

1. Run `scripts/sync-agent-models.ps1 -CheckOnly`; it must pass.
2. Open the chat customization diagnostics and confirm every profile in `.github/agents/` loads without errors, including its `model:` value.
3. For each profile in the table, confirm the model it is pinned to is listed in the model picker under that exact name and is enabled for your account or organization. Where the surface shows the model a profile or subagent actually used, record it; if it does not, record "not observable". Do not infer the model from the profile text.
4. Run one small delegated task per family (a Light task and a Heavy-style review) and confirm the Coordinator started the intended profile and that the reviewer followed the opposite-family pairing in `.ai/MODEL_ASSIGNMENTS.md`. The scenarios in `.ai/EVALS.md` (E2, E4, E10, E11) cover this; record those results there.
5. Confirm terminal access matches `.ai/MODEL_ASSIGNMENTS.md`, "Tool boundaries": the Verifier can run a read-only test command, and no implementer, reviewer, or planner profile offers a terminal tool. Keep terminal-command approval prompts enabled for the Verifier.

| Profile | Pinned tier | Listed in picker? | Model actually observed | Date and surface |
|---|---|---|---|---|
| Coordinator | gpt-standard | _not run_ | _not run_ | |
| PO-BM | claude-standard | _not run_ | _not run_ | |
| Architect | claude-standard | _not run_ | _not run_ | |
| Implementer-Light | claude-light | _not run_ | _not run_ | |
| Implementer-Claude | claude-standard | _not run_ | _not run_ | |
| Implementer-GPT | gpt-standard | _not run_ | _not run_ | |
| Reviewer-Claude | claude-standard | _not run_ | _not run_ | |
| Reviewer-GPT | gpt-standard | _not run_ | _not run_ | |
| Verifier | gpt-light | _not run_ | _not run_ | |
| Utility | gpt-light | _not run_ | _not run_ | |

Until a row is filled for a surface, treat that profile's model pin as unverified there.

## Minimum live-evidence campaign

Before treating a Copilot surface as proven for consequential work, run and record E2 or E2a, E4, E8, E10, and E11 in `.ai/project/EVALS_LOG.md`. For each run record the surface and version, whether Coordinator was selected or automatic, the profiles and models visibly observed, approval behavior, terminal boundaries, exact verification result, and any host limitation. Do not convert a user report into a passing result unless the chat/tool activity was inspected.

## Validation log

For session synchronization, verify `.github/hooks/agent-kit-sync.json` is discovered by the selected harness and inspect a real session-start invocation. See `.ai/adapters/SESSION_HOOKS.md` for Local versus CLI/Agent Host payloads and runtime requirements. Record event firing separately from simulated script tests; Visual Studio support remains unverified.

Append a row only after performing the checks for that exact surface and version. Record observed behavior, not intended behavior. Keep separate rows for each surface.

| Date | Surface & version | Instructions loaded | Default Coordinator behavior (evidence) | Explicit Coordinator fallback | Specialists/tools observed | Models/tiers available | Hard token/spend cap | Notes |
|---|---|---|---|---|---|---|---|---|
| 2026-10-06 (user-reported) | VS Code Copilot Chat (version not recorded) | Coordinator read kit Markdown files; other instruction diagnostics not recorded | Not tested; Coordinator was explicitly selected | Observed Coordinator on GPT-6 Luna for a unit-test task | Verifier ran first on GPT-5.6 Luna, then implementation ran with Implementer-Claude on Claude Sonnet 5.5; user reports this matched the task flow | These three observed model selections only; full picker and all pins not checked | Not recorded | Unit-test work completed and was described as verified; see `.ai/project/EVALS_LOG.md`. User-reported evidence, not independently inspected. |


A row is stale if it is over 90 days old or if the surface, model access, profiles, or instructions changed. Until a current row exists for a surface, treat its automatic routing, model-tier selection, and budget enforcement as unverified.
