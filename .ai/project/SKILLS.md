# <Project name> skill catalog

Load an individual project skill only when its trigger matches. These procedures are project-specific and are not part of the reusable agent kit.

| Skill | Use when |
|---|---|
| `example-skill` | Replace with your own: when the trigger applies |

## Canonical source and generated copies

`.ai/project/skills/<name>/SKILL.md` is the canonical source for each skill. Edit it there.

Hosts that only discover skills at a fixed location get generated copies under `.agents/skills/` and `.claude/skills/`. Never hand-edit those. After changing a canonical `SKILL.md`, run `scripts/sync-skills.ps1`, or `scripts/sync-skills.ps1 -CheckOnly` to detect drift.

Add a project skill only for a recurring procedure with distinct steps, inputs, checks and outputs. Avoid duplicating path instructions or always-on rules.
