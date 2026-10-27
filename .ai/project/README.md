# Project overlay (fill in per project)

This folder holds facts about ONE project. The reusable kit (`.ai/` outside this folder, `AGENTS.md`, `CLAUDE.md`, `scripts/`) must stay project-neutral; anything specific to your product, stack or architecture belongs here.

When you adopt the kit in a new repository, fill these files in. A good way to start is to ask your agent: "Read `.ai/project/README.md` and fill in the files in `.ai/project/` from this codebase; ask me about anything you cannot verify in code."

| File | Fill in |
|---|---|
| `PROJECT_CONTEXT.md` | Architecture, repository map, conventions agents get wrong, build and test commands |
| `ALWAYS_ON_GUARDRAILS.md` | Sensitive data, actions that need approval, test-completion gate |
| `PROTECTED_PATHS.txt` | Globs whose changes need recorded approval (read by `scripts/check-protected-paths.ps1`) |
| `PROJECT_TOKENS.txt` | Project and framework names that must never appear in the reusable layer |
| `MODULE_TEMPLATE.md` | Standard layout and dependency rules for adding a module or feature |
| `DEFINITION_OF_DONE.md` | Project-specific completion criteria on top of `.ai/DEFINITION_OF_DONE.md` |
| `SKILLS.md` and `skills/` | Recurring procedures; see `skills/example-skill/SKILL.md` for the format |
| `VERIFIED.md` | Date and branch the facts above were last verified (create when you first verify) |

Also adapt, outside this folder:

- `templates/path-instructions/example.instructions.md` is a pattern for path-scoped rules. Copy it to `.github/instructions/<name>.instructions.md`, set a real `applyTo` glob, then run `scripts/sync-agent-profiles.ps1` to generate the Cursor rules.
- `.gitlab-ci.yml` runs the kit's checks; merge it into your pipeline.

Record only technical and architectural facts. Product or business behavior that is not in code or approved requirements must be clarified with the user, not inferred from these notes.
