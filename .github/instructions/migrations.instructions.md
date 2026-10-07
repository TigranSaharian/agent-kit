---
description: DiPro EF Core migration guidance
applyTo: "**/Migrations/**/*.cs"
---
**A migration changes the production database. It is the highest-risk change an agent can make in this repository.** Eleven modules own migrations; the data includes wallets, balances, transactions, and customer identity records.

## Do not edit generated files by hand
`<timestamp>_<Name>.cs`, `<timestamp>_<Name>.Designer.cs`, and `ApplicationDbContextModelSnapshot.cs` are generated. Hand-editing them desynchronizes the snapshot from the migration history and breaks the next migration for everyone. Change the entity or its `IEntityTypeConfiguration` in `EntityTypeConfigurations/`, then regenerate.

## Never modify a migration that has been applied
Once a migration is merged to `development` it has run in a deployed environment. Fix forward with a new migration; do not amend, rename, or delete an existing one.

## Generating one
`dotnet-ef` is a **local tool pinned to 9.0.6**, declared in `DiPro.Host/.config/dotnet-tools.json`. Run `dotnet tool restore` first, and run the command from `DiPro.Host` so the manifest resolves — a globally installed `dotnet ef` may be a different version. Note the tool is 9.x while projects target `net8.0`.

Every module has its own `ApplicationDbContext` in its own migrations assembly, so the context must be named explicitly and the startup project must be the host:

```
dotnet ef migrations add <DescriptiveName> \
  --project ../DiPro.<Module>.Infrastructure \
  --startup-project . \
  --context ApplicationDbContext
```

Then read the generated `Up` **and** `Down` before committing. This command has not been executed as part of writing these instructions — confirm the exact invocation against the module you are changing, and report what you actually ran.

## Review checklist
- Identifiers are snake_case (`.UseSnakeCaseNamingConvention()` is active) and the migration targets the module's own schema, recorded in its own `__ef_migrations_history` table. A migration that touches another module's schema is a bug.
- Adding a non-nullable column to a populated table needs a default or a backfill plan; state it.
- Dropping or renaming a column, or narrowing a type, is destructive and **requires explicit approval** — EF renders a rename as drop+add unless written otherwise.
- New indexes on large tables have a locking cost; call it out.
- No data manipulation (`InsertData`, `Sql(...)` touching customer rows) without explicit approval. Never embed real customer data, credentials, or tokens in a migration.
- `Down` must actually reverse `Up`, or you must say clearly that the change is irreversible.

## Report
A migration is never "just a code change". In your summary, name the module and schema affected, whether the change is additive or destructive, whether a backfill is required, and confirm you did not alter an existing migration.
