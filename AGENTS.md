# Agent guidance

Use this file as the reusable, project-neutral baseline for coding agents.

_Last structural review of this kit (roles, workflow, agent profiles, cross-references): 2026-10-07. This tracks the kit's own maintenance, not any project's facts — see `.ai/project/VERIFIED.md` for the project overlay's fact freshness. Update this date when the kit's structure changes materially (new role, new routing rule, renamed file) and after running `scripts/check-agent-kit.ps1` clean._

## Start here

1. Read `.ai/WORKFLOW.md` for task intake, routing, quality checks, and handoffs.
2. Read `.ai/MODEL_ASSIGNMENTS.md` and `.ai/TOKEN_POLICY.md` when model tier or delegation decisions matter. Task weight (Mechanical, Light, Medium, Heavy) in `.ai/WORKFLOW.md` decides which agent starts the work; the Copilot model pins live in `.ai/adapters/copilot-models.json`.
3. Read only role guidance in `.ai/roles/` that is assigned to the task.
4. Before code edits, read `.ai/project/ALWAYS_ON_GUARDRAILS.md` when present. Load matching `.github/instructions/` and other project context when relevant to the files or decisions in scope.
5. Treat task briefs as context, not as authorization beyond the user's request.

## Professional working rules

- Treat current code and established repository conventions as the source of truth when documentation is stale.
- Inspect relevant files and repository state before editing when tools permit.
- Make the smallest coherent change that meets the approved goal. Surface material uncertainty instead of inventing behavior or requirements.
- A clear, in-scope user request already authorizes ordinary implementation of that request; do not pause to re-confirm work the user has already asked for.
- Do not expand scope, change public contracts, data schemas, dependencies, or security behavior without authorization appropriate to the request. A project overlay (for example `.ai/project/ALWAYS_ON_GUARDRAILS.md`) may name specific high-impact triggers that always need separate, explicit approval — even inside an otherwise-authorized task — unless the user's own request already names that specific action.
- Add focused tests when requested or required by the project workflow and a suitable test project exists; do not invent a test framework.
- Run proportionate verification when requested or needed to establish completion. Report exact commands and results; never imply an unrun check passed.
- Never commit, push, merge, publish, or delete branches unless explicitly asked.
- Do not expose secrets, credentials, or sensitive data in logs, responses, test fixtures, or commits.

## Optional project overlay

A repository may have an optional project overlay under `.ai/project/`. Consult it only when task scope needs local context; it is not part of the reusable agent kit. Matching `.github/instructions/` files and project skills are also repository-specific add-ons.

## Completion

Check work against the user's acceptance criteria and `.ai/WORKFLOW.md`. Report changed areas, verification evidence, assumptions, and remaining risks. Do not call work complete with unmet criteria.


