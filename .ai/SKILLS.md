# Skills policy

Skills are optional, task-specific procedures. Load one only when its stated trigger matches the work. A skill supplements the reusable workflow; it does not replace general safety, project context, or host configuration.

Keep the reusable kit free of project-specific steps. A project may maintain an optional skill catalog in its `.ai/project/` overlay. Host-discovered project skills may live under `.agents/skills/` or `.claude/skills/`; do not copy them to another project unless their procedures and examples are independently applicable.

If more than one host needs to discover the same skill, author it once under `.ai/project/skills/<name>/SKILL.md` as the canonical source, and generate the host-specific copies from it (see this repository's `scripts/sync-skills.ps1` for a working example and its `-CheckOnly` mode for drift detection). Do not hand-maintain the same skill content in two places — that is exactly the duplication this pattern exists to prevent.

Create a skill only for a recurring process with distinct steps, inputs, checks, and outputs. Prefer concise, verifiable guidance and avoid duplicating always-on rules.
