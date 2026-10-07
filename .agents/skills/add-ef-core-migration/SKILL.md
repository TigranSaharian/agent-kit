---
name: add-ef-core-migration
description: Creates and reviews a DiPro EF Core migration using the repository's pinned tooling and module-owned schema conventions. Use for entity mapping changes, schema migrations, indexes, constraints, or database model changes.
---
# Add a DiPro EF Core migration

Migrations change production data. Follow `.github/instructions/migrations.instructions.md` and keep this workflow low-freedom.

1. **Stop at the approval gate.** Identify the owning module, schema, desired model change, expected table size, existing data, deployment compatibility, and rollback needs. Schema or migration work requires explicit approval unless the request already names it. Get separate approval for destructive changes, data SQL/backfills, or edits to shared Libra projects.
2. **Inspect history; never rewrite it.** Determine whether related migrations have reached `development` or another deployed environment. Never edit, rename, or remove an applied migration. Fix forward with a new one.
3. **Change the model source.** Edit the entity/value object and its `IEntityTypeConfiguration<T>`. Keep configuration out of `OnModelCreating`; preserve the module schema, snake_case naming, key/constraint conventions, and both write/read context compatibility.
4. **Capture the baseline.** Build the target Infrastructure project before generation and record the result. Check the working diff so the generated migration contains only the intended model delta.
5. **Use the pinned local tool.** From `DiPro.Host`, run:

   `dotnet tool restore`

   `dotnet ef migrations add <DescriptiveName> --project ../DiPro.<Module>.Infrastructure --startup-project . --context ApplicationDbContext`

   Confirm the context and paths against the target module rather than copying them blindly.
6. **Review every generated artifact.** Read `Up`, `Down`, the designer, and `ApplicationDbContextModelSnapshot`. Confirm the module schema and snake_case identifiers, and reject unrelated operations. Do not hand-edit generated files to conceal a model mismatch; correct the model and regenerate.
7. **Assess operational safety.** Call out non-null additions on populated tables, defaults/backfills, drops or narrowing, rename detection, unique/index creation, foreign-key locking, long-running operations, and whether old and new application versions can overlap safely. `Down` must reverse `Up`, or the report must state why rollback is irreversible.
8. **Verify without applying to shared data.** Build the target projects and inspect the generated SQL when risk warrants it. Do not run `database update` against any shared or production-like database unless explicitly requested and the target is confirmed. Follow `verify-dipro-change` for broader checks.

Report the module/schema, migration name, additive or destructive classification, backfill and rollout requirements, generated operations, rollback behavior, exact commands/results, and confirmation that no existing migration was altered.

<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->
