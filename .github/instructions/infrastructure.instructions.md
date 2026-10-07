---
description: DiPro infrastructure-project guidance
applyTo: "**/*.Infrastructure/**/*.cs"
---
Golden examples: `DiPro.Wallet.Infrastructure/DependencyInjection.cs`, `.../Data/ApplicationDbContext.cs`, `.../Repositories/WalletRepository.cs`, `.../Services/WalletQueryService.cs`.

## Persistence layout
- Each module owns **two** contexts: `ApplicationDbContext` (writes, tracking) and `ReadOnlyDbContext` (`QueryTrackingBehavior.NoTracking`). Reads go through the read-only one.
- Both are configured with `.UseSnakeCaseNamingConvention()`. Table and column identifiers in the database are snake_case even though the C# is PascalCase — never hand-write SQL or an EF mapping that assumes PascalCase identifiers.
- `OnModelCreating` sets `modelBuilder.HasDefaultSchema(Config.DB_SCHEMA)`, calls `AddTransactionalOutboxEntities()`, and applies configurations by assembly scan. The module's migrations history table is scoped to its own schema (`MigrationsHistoryTable("__ef_migrations_history", Config.DB_SCHEMA)`).
- Entity mappings are `IEntityTypeConfiguration<T>` classes in `EntityTypeConfigurations/`, picked up automatically. Do not configure entities inline in `OnModelCreating`.
- The connection string is read per module from configuration, e.g. `WalletModule:ConnectionStrings:MSSQL`. Keep that key shape when adding a module.

## Repositories and query services
- `I<Aggregate>Repository` is declared in Domain and implemented here over `ApplicationDbContext`; it is the only write path.
- `I<Thing>QueryService` is declared in Application and implemented here over `ReadOnlyDbContext`, returning read models or DTOs — never aggregates.
- Projection repositories/services maintain local copies of data owned by another module, fed by consumers. Do not query another module's schema directly.
- Register everything in the module's `DependencyInjection.AddInfrastructureLayer`, keeping the existing grouping comments (Repositories / Projection / Application services / Domain services / Background jobs).

## High impact — requires explicit scope
- **Schema and migrations.** See the migrations instructions; treat any model change as a deployment event.
- **Outbox/inbox settings** (`DuplicateDetectionWindow`, `QueryDelay`, `UseBusOutbox`) change delivery semantics across modules.
- **Background jobs.** Hangfire schedulers live in `BackgroundJobs/`; changing a recurring schedule affects production timing.
- **Secrets and external clients.** Read credentials from configuration only. Never log request/response bodies of `EkengClient`, `OzForensics`, `IPayClient`, or the ArmSoft banking clients — they carry identity documents, biometric results, and card data.
