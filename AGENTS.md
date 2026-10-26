# Agent guidance

Use this file as the reusable, project-neutral baseline for coding agents.

## Start here

1. Answer questions and explanations directly. For change requests, read `.ai/WORKFLOW.md`; it decides task weight and which agent starts the work.
2. Resolve roles through `.ai/agents.json` and the active host adapter: Cursor uses `.ai/adapters/CURSOR.md`; Copilot uses the Copilot runtime mapping in `.ai/MODEL_ASSIGNMENTS.md`, with pins in `.ai/adapters/copilot-models.json`. Read `.ai/TOKEN_POLICY.md` when delegation or model choices matter.
3. Delegated specialists follow the role text and delegate contract embedded in their generated profile; they do not need the full workflow.
4. Before code edits, read `.ai/project/ALWAYS_ON_GUARDRAILS.md` when present and the `.github/instructions/` files matching the paths in scope.
5. Treat task briefs as context, not as authorization beyond the user's request. After shared kit changes, run `scripts/sync-agent-profiles.ps1`; generated profiles are outputs, not policy sources.

## Professional working rules

- Treat current code and established repository conventions as the source of truth when documentation is stale.
- Inspect relevant files and repository state before editing when tools permit.
- Make the smallest coherent change that meets the approved goal. Surface material uncertainty instead of inventing behavior or requirements.
- Follow `.ai/WORKFLOW.md`, "Authorization boundary": a clear, in-scope request authorizes its ordinary implementation, while high-impact triggers named by a project overlay need separate approval unless the request already names that action.
- Do not expand scope, change public contracts, data schemas, dependencies, or security behavior without authorization appropriate to the request.
- Add focused tests when requested or required by the project workflow and a suitable test project exists; do not invent a test framework.
- Run proportionate verification when requested or needed to establish completion. Report exact commands and results; never imply an unrun check passed.
- Never commit, push, merge, publish, or delete branches unless explicitly asked.
- Do not expose secrets, credentials, or sensitive data in logs, responses, test fixtures, or commits.

## Optional project overlay

A repository may have an optional project overlay under `.ai/project/`. Consult it only when task scope needs local context; it is not part of the reusable agent kit. Matching `.github/instructions/` files and project skills are also repository-specific add-ons.

## Completion

Check work against the user's acceptance criteria, `.ai/DEFINITION_OF_DONE.md`, and `.ai/WORKFLOW.md`. Report changed areas, verification evidence, assumptions, and remaining risks. Do not call work complete with unmet criteria.

## Kit stability

A stable baseline is clean sync and self-checks, internal consistency, and no known critical failed required eval relevant to the changed behavior. An open-ended review or rating is a defect audit against that accepted baseline, not permission to redesign.

A required change needs evidence: a failing check or eval, a contradiction, a stale or false runtime claim, a security or authorization defect, or observed ambiguity that causes incorrect routing or behavior. Wording, style, theoretical simplification, extra abstraction, and unobserved hypotheticals are optional and must not trigger edits, lower the readiness rating, or be presented as necessary unless the user explicitly asks to experiment or redesign. If no required defect exists, say the kit is stable and "no required changes". Do not change files merely to produce feedback.

After acceptance, change policy only for a new user requirement, a verified defect, an external host or runtime change, or evidence from a failed eval. No prose is immune to all future critique; stability means evidence-gated changes, not perfect eternal wording.
