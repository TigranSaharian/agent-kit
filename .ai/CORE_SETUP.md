# Reusing the agent kit

This kit contains project-neutral technical and professional guidance. Keep project facts, architecture decisions, domain language, data classifications, build commands, and baselines in an optional project overlay.

## Reusable kit

- `.ai/WORKFLOW.md` — task intake, routing, quality checks, handoffs, verification, and review
- `.ai/MODEL_ASSIGNMENTS.md` — capability tiers and provider/model selection policy
- `.ai/TOKEN_POLICY.md` — context minimization, delegation, and retry discipline
- `.ai/roles/` — generic specialist responsibilities and output contracts
- `.ai/DEFINITION_OF_DONE.md` — generic completion criteria
- `.ai/EVALS.md` — repeatable routing scenarios and a results log; re-run them after changing the workflow, a role, a profile, or the model map
- `.ai/tasks/` — generic task-brief templates
- `.github/agents/` — Copilot agent profiles for this kit
- `.ai/adapters/copilot-models.json` — dated Copilot adapter: the one place that names models and pins each agent profile to a tier (profiles are synced from it by `scripts/sync-agent-models.ps1`)
- `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` — host entry points
- `.ai/adapters/gitlab-ci.lint-agent-kit.snippet.yml` and `.ai/adapters/gitattributes.snippet` — reference snippets to merge by hand into the project's own `.gitlab-ci.yml` and `.gitattributes`
- `scripts/check-agent-kit.ps1`, `scripts/sync-agent-models.ps1`, `scripts/sync-skills.ps1` — the kit's own internal-consistency checks
- `scripts/check-protected-paths.ps1` — flags changes to the overlay's protected paths (`.ai/project/PROTECTED_PATHS.txt`) that carry no recorded approval; does nothing if the overlay has no such file
- `scripts/install-agent-kit.ps1` and `templates/` — present only in the shared kit repository; install/update the files above into a project repository (see "Global source and local installation" below)

Keep provider model IDs, project architecture, business rules, tool names, and host-specific controls out of reusable guidance unless a file is explicitly an adapter.

## Optional project overlay

Project-specific architecture, domain context, local completion criteria, technical conventions, and skills belong in an optional overlay under `.ai/project/`. Keep it separate from the reusable kit and load only the parts relevant to a task. Matching `.github/instructions/` and project skills may provide host-discovered project guidance; they are project add-ons, not reusable kit policy.

When adapting the kit to another project, create or replace the overlay with verified local facts and rules. Do not copy another project's business, architecture, or data rules into the kit.

## Global source and local installation

This repository's reusable kit files are typically maintained in one shared, dedicated repository and installed into each project repository by that shared repository's `scripts/install-agent-kit.ps1`. The installed copy in a project repository is checked into that project's own source control and is what agents and CI actually read; the project does not depend on the shared repository being present at run time.

Practical effect:

- Edit reusable policy (workflow, roles, model-tier policy, agent profiles, the maintenance scripts) in the shared kit repository, not in a project's installed copy. A hand-edit to an installed managed file is drift and will be overwritten the next time the installer runs, the same way `scripts/sync-skills.ps1` and `scripts/sync-agent-models.ps1` already treat their own generated files as authoritative.
- To pull in a policy update, re-run the shared repository's installer against the project, then re-run the project's own `scripts/sync-agent-models.ps1` and `scripts/sync-skills.ps1` (to reconcile with that project's local adapter map and canonical skills) and `scripts/check-agent-kit.ps1` (to confirm consistency).
- Files that hold local customization or accumulated history — `.ai/adapters/copilot-models.json`, `.github/COPILOT_VALIDATION.md`, and the project overlay under `.ai/project/` — are scaffolded once if missing and never overwritten by the installer.
- This working process (Coordinator routing, task weight, verification, review) does not change based on how the kit got into the repository; the installer only changes how the files arrive and stay current.

## Host adapters and limits

Host entry points should remain short and point to the reusable kit. Link or load a project overlay only when relevant. Each host has its own discovery, agent delegation, model selection, tools, and usage controls; similar Markdown files do not guarantee equivalent behavior.

For a new host, verify supported instruction/skill/agent locations, automatic routing behavior, model selection, and token/spend controls. Run `.github/COPILOT_VALIDATION.md` for Copilot surfaces and record the result in its **Validation log**. No instruction file can grant unavailable capabilities or enforce a budget the runtime does not support. Before assuming a host actually supports delegation, per-agent model tiers, or an enforceable spend cap, check that log for a current, matching-surface row; if there is none, treat the capability as unverified for that host.
