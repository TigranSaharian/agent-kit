# Model selection policy

This file sets task-based capability requirements, not permanent model names. The runtime must map each tier to a model that is actually available, tool-capable, and enabled for the account. Prefer the lowest-cost capable option. Use the Strong tier when task risk or reasoning difficulty justifies it, not simply because a specialist role is involved.

## Capability tiers

| Tier | Select when | Typical tasks |
|---|---|---|
| **Fast** | Low risk, familiar, bounded, and easy to verify | Mechanical edits, concise summaries, simple documentation, routine command execution |
| **Balanced** | Normal implementation or analysis with manageable uncertainty | Most scoped changes, routine debugging, standard design questions |
| **Strong** | High impact, broad uncertainty, hard reasoning, or critical independent review | Money/identity/security, public contracts, schema/migrations, cross-module design, difficult incidents |

If the work expands or the first attempt shows difficulty, reassess the tier. Do not silently use a weaker tier for high-impact work; if no Strong model is available, tell the user and choose the safest viable route. Keep a task at the capability tier required by its risk and difficulty: cost pressure or high token use alone is not a reason to downgrade it, and an easy task should not be escalated just because a stronger model is available.

### Same-tier fallback

- Prefer the lowest-cost model that can meet the task's requirements. For routine tasks, start in Fast; use Balanced or Strong only when the task's uncertainty, difficulty, or impact calls for it.
- If a selected model is unavailable, repeatedly fails, or is clearly inefficient for a bounded task, retry at most once with another model in the **same capability tier** when the host allows model selection. Keep the task's required tier unchanged.
- Before retrying, consider whether narrowing the prompt, removing irrelevant context, or making the handoff more focused will solve the issue without another model run.
- Move to a different tier only when the task itself changes or evidence shows the current tier cannot meet its requirements. Reclassify the work and explain the reason; do not move between tiers solely to chase lower cost.
- Model switching and tier selection are runtime capabilities, not powers granted by these instructions. If the host cannot select a different model or delegate to a pinned profile, state the limitation and provide the appropriate model/profile as guidance. Never claim a switch occurred unless the host confirms it.

## Role defaults

| Role | Default | Raise to Strong when |
|---|---|---|
| Coordinator | Balanced | Scope/risk routing is materially ambiguous or broad |
| PO/BM | Balanced | Business rules have competing high-impact interpretations |
| Architect | Balanced | Cross-module contracts, security, persistence, or operations have high impact |
| Implementer (Light weight) | Fast | The task turns out to be Medium or Heavy; stop and re-route |
| Implementer (Medium/Heavy weight) | Balanced | Broad/refactor-heavy work, difficult failures, or high-impact logic |
| Verifier | Fast | Failures require substantial diagnosis |
| Reviewer | Balanced | Security, money/identity, migration, contract, or broad change |
| Utility | Fast | The task stops being mechanical; stop and re-scope instead of drifting |

These are defaults only. Apply the task’s risk tier to every role involved. A Strong model for a reviewer does not compensate for an under-tiered implementation on critical work.

## Copilot runtime mapping

In Copilot, a custom agent's model is set in its own profile (`.github/agents/*.agent.md`, `model:` field), and Coordinator cannot switch its own model mid-session. Routing by task weight therefore means choosing **which profile** starts the work; each profile is pinned to one tier and family. `.ai/adapters/copilot-models.json` is the single source of truth for the pins. `scripts/sync-agent-profiles.ps1` generates both host profiles; the existing `scripts/sync-agent-models.ps1` remains the Copilot-only model validator and updater. Both provide `-CheckOnly` drift detection.

| Profile | Role | Tier | Family |
|---|---|---|---|
| Coordinator | Routing and final report | Balanced | GPT |
| PO-BM | Product intent and acceptance criteria | Balanced | Claude |
| Architect | Consequential design | Balanced (best available) | Claude |
| Utility | Mechanical edits | Fast | GPT |
| Verifier | Baselines and scoped checks | Fast | GPT |
| Implementer-Light | Small, fully specified code changes | Fast | Claude |
| Implementer-Claude | Medium and Heavy implementation | Balanced (best available) | Claude |
| Implementer-GPT | Medium and Heavy implementation | Balanced (best available) | GPT |
| Reviewer-Claude | Review of changes written by the GPT family | Balanced (best available) | Claude |
| Reviewer-GPT | Review of changes written by the Claude family | Balanced (best available) | GPT |

Rules for the Coordinator:

- Default implementer family is Claude (Implementer-Claude); use Implementer-GPT when the user asks for it or for the single repair pass after a failed first attempt.
- **Copilot cross-family review:** Reviewer-GPT after Claude-family edits (Implementer-Light, Implementer-Claude); Reviewer-Claude after GPT-family edits (Implementer-GPT, Utility). This is the Copilot adapter implementation of the generic independent-review requirement in `.ai/WORKFLOW.md`.
- No Strong tier exists in the current model list, so "Strong" resolves to the best model available in each family. If a larger model is added later, add a Strong tier in the adapter file and repoint Architect and the heavy-task implementers; do not edit profiles by hand.
- Fallback models inside a tier stay in the same family. If neither the primary nor its fallback is available, the profile falls back to the session model; report that cross-family review may not have happened.
- Same-tier model fallback is a runtime decision only where the Copilot surface supports it; the pinned profile map itself defines fixed models and does not dynamically change them based on token consumption.

### Tool boundaries

Least privilege is part of the design: each profile gets only the tools its role needs.

| Profiles | Tools |
|---|---|
| Coordinator | delegate, read, search |
| PO-BM, Architect, Reviewer-Claude, Reviewer-GPT | read, search |
| Implementer-Light, Implementer-Claude, Implementer-GPT, Utility | edit, read, search (no terminal) |
| Verifier | read, search, **execute** (the only profile that runs commands) |

`scripts/check-agent-kit.ps1` fails if any profile other than the Verifier gains a terminal tool. Keep your host's terminal-command approval prompts enabled for the Verifier; a terminal tool can run arbitrary commands.

### Host support

What works depends on the Copilot surface. Observations are dated and are not transferable between surfaces.

| Surface | Delegation to custom agents | Per-profile model pins | Practical mode |
|---|---|---|---|
| VS Code Copilot Chat | Supported: custom agents run as subagents with their own model and tools | Supported through the `model:` field | Full: Coordinator routes by weight and runs the profiles |
| Visual Studio Copilot Chat | Reported unavailable in this repository's sessions (observed 2026-10; public reporting in 2026-05 called subagents "coming soon") | Unverified | Advisory only: Coordinator classifies and writes a brief; apply it in VS Code or with the host's built-in agent mode |
| Other surfaces (cloud agent, CLI) | Unverified | Unverified | Treat as advisory until verified and recorded in `.github/COPILOT_VALIDATION.md` |

When delegation is unavailable the Coordinator must say so and must not claim any profile or model ran. `.github/copilot-instructions.md` still applies on surfaces that honor it, so the host's built-in agent mode can follow the same weight rubric by itself.

A mapping is only as good as its last check. Verify available models in the exact surface being used and record the result in `.github/COPILOT_VALIDATION.md`. If per-agent model selection is unavailable on a surface, keep the task-weight guidance, report the limitation when it matters, and do not pretend the policy routed models automatically.

## Cursor runtime mapping

Read `.ai/adapters/CURSOR.md`. `.ai/adapters/cursor.json` maps shared logical agents to Cursor specialists; the main session acts as Coordinator. `.ai/adapters/cursor-models.json` pins Utility, Verifier, and Implementer-Light to a Fast model, Implementer to Claude Sonnet, Architect to Claude Opus, and Reviewer to GPT. PO/BM inherits the parent model. Inspect actual task-card models before claiming selection. Heavy work uses the GPT reviewer so the review is independent of the Claude implementer. Copilot's family-named profiles and tool allowlists apply only to Copilot.
