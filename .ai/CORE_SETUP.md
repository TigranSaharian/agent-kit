# Reusing the agent kit

This kit contains project-neutral technical and professional guidance. Keep project facts, architecture decisions, domain language, data classifications, build commands, and baselines in an optional project overlay.

## Reusable kit

- `.ai/WORKFLOW.md` — task intake, routing, quality checks, handoffs, verification, and review
- `.ai/MODEL_ASSIGNMENTS.md` — capability tiers and provider/model selection policy
- `.ai/TOKEN_POLICY.md` — context minimization, delegation, and retry discipline
- `.ai/roles/` — generic specialist responsibilities and output contracts
- `.ai/agents.json` — shared logical agent registry; both hosts reference the same roles and descriptions
- `.ai/DEFINITION_OF_DONE.md` — generic completion criteria
- `.ai/EVALS.md` — repeatable routing scenarios and a results log; re-run them after changing the workflow, a role, a profile, or the model map
- `.ai/tasks/` — generic task-brief templates
- `.github/agents/` — generated Copilot agent profiles; each specialist embeds its role text and the shared delegate contract
- `.cursor/agents/` and `.cursor/rules/` — generated Cursor specialists (same embedded role and contract), entry rule, and references to canonical path instructions
- `.ai/adapters/copilot.json`, `.ai/adapters/cursor.json`, `.ai/adapters/cursor-models.json`, and `.ai/adapters/CURSOR.md` — host mappings and documented Cursor limits
- `.cursor/hooks.json`, `.github/hooks/agent-kit-sync.json`, and `scripts/sync-agent-session-hook.ps1` — project session-start triggers sharing one synchronization wrapper; limits are documented in `.ai/adapters/SESSION_HOOKS.md`
- `.ai/adapters/copilot-models.json` — dated Copilot adapter: the one place that names models and pins each agent profile to a tier (profiles are synced from it by `scripts/sync-agent-models.ps1`)
- `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` — host entry points
- `.ai/adapters/gitlab-ci.lint-agent-kit.snippet.yml` and `.ai/adapters/gitattributes.snippet` — reference snippets to merge by hand into the project's own `.gitlab-ci.yml` and `.gitattributes`
- `scripts/check-agent-kit.ps1`, `scripts/sync-agent-profiles.ps1`, `scripts/sync-agent-models.ps1`, `scripts/sync-skills.ps1` — the kit's own internal-consistency checks; profile sync generates both host adapters from canonical sources
- `scripts/test-agent-adapters.ps1` — disposable fixture checks for drift, idempotence, membership updates, collision/orphan safety and instruction synchronization
- `scripts/check-protected-paths.ps1` — flags changes to the overlay's protected paths (`.ai/project/PROTECTED_PATHS.txt`) that carry no recorded approval; does nothing if the overlay has no such file
- `scripts/install-agent-kit.ps1` and `templates/` — present only in the shared kit repository; install/update the files above into a project repository (see "Global source and local installation" below)

Keep provider model IDs, project architecture, business rules, tool names, and host-specific controls out of reusable guidance unless a file is explicitly an adapter.

## Kit maintenance

_Last structural review of this kit (roles, workflow, agent profiles, cross-references): 2026-10-21. This tracks the kit's own maintenance, not project facts; see the overlay's verification record for those. Update the date after a material structural change and a clean `scripts/check-agent-kit.ps1` run._

- Edit shared behavior in `.ai/roles/`, workflow and criteria in their canonical files, and agent membership and descriptions in `.ai/agents.json`. Host adapters map shared agents to profiles; model maps stay host-specific.
- After changes run `scripts/sync-agent-profiles.ps1`, then its `-CheckOnly` mode. Never author policy in generated profiles; the generator copies role text into them.
- Report obsolete generated files for deliberate removal; never delete unrelated custom agents.
- Each host reads the current repository state rather than importing another host's chat history. Sync checks are configuration evidence, not runtime eval results.

Open-ended reviews follow `AGENTS.md`, "Kit stability". Clean sync and self-checks there mean a clean `scripts/sync-agent-profiles.ps1 -CheckOnly` and `scripts/check-agent-kit.ps1`. Keep optional ideas outside the working tree until explicitly approved.

## Optional project overlay

Project-specific architecture, domain context, local completion criteria, technical conventions, and skills belong in an optional overlay under `.ai/project/`. Keep it separate from the reusable kit and load only the parts relevant to a task. Matching `.github/instructions/` and project skills may provide host-discovered project guidance; they are project add-ons, not reusable kit policy.

When adapting the kit to another project, create or replace the overlay with verified local facts and rules. Do not copy another project's business, architecture, or data rules into the kit.

## Global source and local installation

This repository's reusable kit files are typically maintained in one shared, dedicated repository and installed into each project repository by that shared repository's `scripts/install-agent-kit.ps1`. The installed copy in a project repository is checked into that project's own source control and is what agents and CI actually read; the project does not depend on the shared repository being present at run time.

Practical effect:

- Edit reusable policy (workflow, roles, model-tier policy, agent profiles, the maintenance scripts) in the shared kit repository, not in a project's installed copy. A hand-edit to an installed managed file is drift and will be overwritten the next time the installer runs, the same way `scripts/sync-skills.ps1` and `scripts/sync-agent-models.ps1` already treat their own generated files as authoritative.
- To pull in a policy update, re-run the shared repository's installer against the project, then re-run the project's own `scripts/sync-agent-models.ps1` and `scripts/sync-skills.ps1` (to reconcile with that project's local adapter map and canonical skills) and `scripts/check-agent-kit.ps1` (to confirm consistency).
- Files that hold local customization or accumulated history — host adapter/model maps, `.github/COPILOT_VALIDATION.md`, `.cursor/CURSOR_VALIDATION.md`, and the project overlay under `.ai/project/` — should be scaffolded once if missing and never overwritten by the installer. The external installer must be updated to include this Cursor integration before it is used again; it is not present in this checkout and has not been changed here.
- This working process (Coordinator routing, task weight, verification, review) does not change based on how the kit got into the repository; the installer only changes how the files arrive and stay current.

## Host adapters and limits

Host entry points should remain short and point to the reusable kit. Link or load a project overlay only when relevant. Each host has its own discovery, agent delegation, model selection, tools, and usage controls; similar Markdown files do not guarantee equivalent behavior.

For a new host, verify supported instruction/skill/agent locations, automatic routing behavior, model selection, and token/spend controls. Run `.github/COPILOT_VALIDATION.md` for Copilot surfaces and record the result in its **Validation log**. No instruction file can grant unavailable capabilities or enforce a budget the runtime does not support. Before assuming a host actually supports delegation, per-agent model tiers, or an enforceable spend cap, check that log for a current, matching-surface row; if there is none, treat the capability as unverified for that host.

For Cursor use `.cursor/CURSOR_VALIDATION.md` and `.ai/adapters/CURSOR.md`. Keep shared policy and agent membership in `.ai/`; edit host mappings/models in `.ai/adapters/` and regenerate with `scripts/sync-agent-profiles.ps1`. Profiles/rules are generated outputs, not independent sources. Its fingerprints detect changed roles, shared policy, top-level project criteria and canonical path instructions. Project skills keep their existing canonical source and sync; Cursor discovers the existing `.agents/skills/` mirrors without another copy.

After weeks on another host, use the same updated checkout/branch, run profile and skill drift checks, and read the current shared/project guidance. Project session-start hooks attempt profile synchronization automatically on supported hosts; Cursor's asynchronous hook does not replace its first-implementation check. Event firing must be observed on the installed host before claiming it works. Do not copy conversations or refresh validation dates without runtime evidence. Keep local changes in this checkout until they can be carried to the shared kit source; an old installer may overwrite managed changes.
