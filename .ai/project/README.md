# DiPro project overlay

This directory is optional project context, separate from the reusable agent kit in `.ai/`. It applies only when working in this DiPro repository. Do not copy its business or architecture rules to other projects.

Load only the files relevant to the current task:

- `PROJECT_CONTEXT.md` — verified architecture, local conventions, commands, known test baseline, and repository map.
- `VERIFIED.md` — the single dated record of when the overlay's facts were last verified and when they go stale; other files point here instead of repeating a date.
- `MODULE_TEMPLATE.md` — canonical module project/folder layout, dependency boundaries, and host integration checklist for adding a business module.
- `DEFINITION_OF_DONE.md` — DiPro-specific completion expectations.
- `PROTECTED_PATHS.txt` — paths whose changes need recorded approval; read by `scripts/check-protected-paths.ps1`.
- `EVALS_LOG.md` — results of running the routing scenarios in `.ai/EVALS.md` in this repository.
- `SKILLS.md` — DiPro-specific skill index and recommendations.
- `.github/instructions/` — path-scoped technical rules discovered by Copilot for matching files.
- `skills/` — canonical DiPro skill procedures. `.agents/skills/` and `.claude/skills/` hold generated, host-discoverable copies; see `SKILLS.md` for how they stay in sync.

The overlay records project facts and technical constraints. Product or business behavior that is not already specified in code or approved requirements must be clarified with the user; do not infer it from architecture notes.


