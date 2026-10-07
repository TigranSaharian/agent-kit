# DiPro backend project context

Facts recorded in this file were verified against a specific branch/SDK; see `.ai/project/VERIFIED.md` for the exact date, branch, and whether that record is still fresh. Commands in "Verification" were actually executed; their recorded results are below.

> **Freshness check — do this first.** Read `.ai/project/VERIFIED.md`'s "Stale past" date and compare it to today. Treat every fact, count, and baseline in this file as unverified past that date, or sooner if the solution, tests, or CI have changed materially since. Past that point, re-run the commands in "Verification" yourself before trusting any number here, then update `.ai/project/VERIFIED.md` (not a date here) once you do. Never cite a stale count as current without re-checking it.

## What DiPro is

A **modular monolith** for a digital wallet and payments product (Snapp). One ASP.NET Core host (`DiPro.Host`) loads every business module at startup. Modules are separate projects, not microservices, but they communicate through **integration events over RabbitMQ/MassTransit** as if they were, and each module owns its **own database schema**.

The domain is regulated: customer onboarding and KYC, wallets, balances, card binding, transfers, payments, partner settlement, and risk monitoring. Treat money, identity, and personal data as high-impact by default.

## Read this first: the Libra framework

Four directories contain projects whose **name and namespace do not match the folder**. This is the single most common source of confusion in this repository.

| Directory | Project file | Namespace root |
|---|---|---|
| `DiPro.Domain/` | `Libra.Domain.csproj` | `Libra.Domain` |
| `DiPro.Application/` | `Libra.Application.csproj` | `Libra.Application` |
| `DiPro.Result/` | `Libra.Result.csproj` | `Libra.Result` |
| `DiPro.Observability/` | `Libra.Observability.csproj` | `Libra.Observability` |

Libra is the in-repo framework every module is built on. It is **shared infrastructure owned by the platform, not by any module**. Changing it affects all 15 modules at once; treat any edit there as a cross-cutting change requiring explicit approval.

What Libra provides:

- `Libra.Domain.Primitives` — `AggregateRoot<TId>`, `Entity`, `ValueObject`, `DomainEvent`; abstractions `IRepository`, `IUnitOfWork`, `ISoftDeletable`, `IAuditable`, `IDomainEventDispatcher`.
- `Libra.Result.Primitives` — the `Result` / `Result<T>` / `Error` types used as the return value of nearly every handler. Implicit conversions mean `return new Error(...)` and `return someDto;` both work.
- `Libra.Application` — the `IModule` contract and `ModuleLoader`, the MediatR pipeline behaviors, `IdentityUser` and `[Authorize]`, `IntegrationEvent`, and MassTransit integration-event wiring.
- `Libra.Observability` — MediatR observability behavior and OpenTelemetry helpers.

## Module anatomy

A full business module is five projects. Using Wallet as the reference:

| Project | Contains |
|---|---|
| `DiPro.Wallet` | Controllers and `WalletModule : IModule`; the module's composition entry point |
| `DiPro.Wallet.Domain` | Aggregates, entities, value objects, domain events, domain services, repository interfaces |
| `DiPro.Wallet.Application` | MediatR commands/queries + handlers, FluentValidation validators, DTOs, read models, domain event handlers, `DependencyInjection.cs` |
| `DiPro.Wallet.Infrastructure` | `ApplicationDbContext` + `ReadOnlyDbContext`, EF configurations, migrations, repositories, query services, MassTransit consumers and definitions |
| `DiPro.Wallet.IntegrationEvents` | **Published contracts.** Other modules reference this project directly |

Inside Domain and Application, code is grouped **by aggregate first, then by pattern** (`Wallets/Commands/`, `Wallets/Validators/`, `WalletPolicies/Queries/`). Follow that shape; do not group by pattern at the top level.

`DiPro.Wallet` is the best end-to-end reference module: it is the only one with a complete layer set, a test project, consumers, projections, background jobs, and domain events.

## Module map

Full modules (`DiPro.<Name>` + `.Domain` + `.Application` + `.Infrastructure` + `.IntegrationEvents`):

Accounts, Customers, FileStore (also `.PublicApi`), Identity, InternalStaff, Kernel, Partners, ProviderServices, RiskAndMonitoring, Transactions, Wallet.

Partial modules: **Localization** and **Notifications** have no `.IntegrationEvents` project. **Aggregator** and **Orchestration** are `DiPro.<Name>` + `.Application` only — they compose across modules and own no persistence.

Platform and shared: `DiPro.Host` (composition root and the cross-module `Aggregator` read layer), `DiPro.Messaging` (RabbitMQ options, `IModuleMassTransitRegistry`, transient exception types), `DiPro.Shared.Infrastructure` (field-level permission mappers), `DiPro.Kernel` (shared reference data: MCC, service groups, restrictions, VPOS), plus `DiPro.Elastic`, `DiPro.FileExport`, `DiPro.Logging`, `DiPro.Redis`.

External integration clients: `ArmSoftLocalClient`, `ArmSoftPartnerClient` (core banking), `EkengClient` (Armenian state registry), `OzForensics` (biometric liveness), `IPayClient`, `EpgClient`, `PelekaClient`, `FcmClient`, `EmailClient`, `MailGunClient`, `Integrations` / `Integrations.Client`.

`DiPro.sln` contains 104 projects.

## Conventions that agents get wrong

**Target framework.** All checked projects target `net8.0`. The machine's default SDK is **10.0.401**, and the solution builds with it, producing ~1150 MSB3277 assembly-unification warnings. There is no `global.json`, so the SDK used is whatever is installed. Do not "fix" those warnings as part of an unrelated task.

**Results, not exceptions, in Application.** Handlers return `Result` or `Result<T>`. Failure is `return new Error(ApplicationErrorMessages.<Area>.Errors.<Name>);` — messages live in per-area `ApplicationErrorMessages` classes, never inline. Domain code is the exception: it throws `*DomainException` for invariant violations, and `ExceptionHandlingBehavior` converts those at the pipeline edge.

**MediatR pipeline order.** Registered in `DiPro.Host/Program.cs` as `AddExceptionHandling().AddAuthorization().AddValidation().AddUnitOfWork()`. Behaviors run in registration order, so exception handling is outermost and unit of work is closest to the handler. Order is load-bearing; do not reorder.

**Unit of work is automatic and name-driven.** `UnitOfWorkBehavior` inspects the request type name: anything ending in `Query` skips `SaveChangesAsync` entirely. A command named `...Query`, or a query named `...Command`, silently changes transactional behavior. Handlers call `repository.AddAsync(...)` and **do not** call `SaveChangesAsync` themselves.

**Authorization is an attribute on the request.** `[Authorize]` from `Libra.Application.Identity.Attributes` goes on the command/query record, not only on the controller. `AuthorizationBehavior` enforces it.

**Controllers are thin.** They inherit `AdminBaseController` or `WalletBaseController` (which carry `[ApiController]`, `[ApiVersion(1)]`, and route templates like `api/wallet/v{version:apiVersion}/[controller]`), inject `ISender`, send one request, and return `result.ToActionResult()`. Each module has its own `ResultExtensions`. Never put logic in a controller.

**Persistence.** Every module has its own `ApplicationDbContext` plus a `ReadOnlyDbContext` configured `NoTracking`. Both use `.UseSnakeCaseNamingConvention()` (EFCore.NamingConventions) — generated SQL identifiers are snake_case. Each module sets `modelBuilder.HasDefaultSchema(Config.DB_SCHEMA)` and its own migrations history table, e.g. `__ef_migrations_history` in the module schema. Connection strings are read per module from configuration, e.g. `WalletModule:ConnectionStrings:MSSQL`.

**Messaging is outbox-backed.** `ApplicationDbContext.OnModelCreating` calls `AddTransactionalOutboxEntities()`. Module registration calls `AddEntityFrameworkOutbox<ApplicationDbContext>` with `UseBusOutbox()`, so publishes commit with the database transaction. The inbox gives duplicate detection over a 24-hour window — consumers are protected against redelivery of the same `MessageId`, but **not** against a semantically duplicate event with a new id. Consumers derive their definition from a module-local `BaseIntegrationEventConsumerDefinition<T>`, which applies retry intervals, delayed redelivery, and `UseEntityFrameworkOutbox`. Consumers are `internal sealed`, inject `ISender`, and delegate immediately to a command.

**Consumer registration is explicit.** Unlike validators and entity configurations, consumers are *not* discovered by assembly scan. Each module hand-lists `AddConsumer<TConsumer, TDefinition>()` pairs in `Extensions/MessagingRegistrationExtensions.AddModuleConsumers()`. A consumer missing from that list compiles fine and silently never runs. Eight modules have this file: Accounts, Customers, FileStore, Identity, InternalStaff, Notifications, Transactions, Wallet.

**EF tooling is a pinned local tool.** `dotnet-ef` 9.0.6 is declared in `DiPro.Host/.config/dotnet-tools.json`. Run `dotnet tool restore` and invoke it from `DiPro.Host` so the manifest resolves; a global `dotnet ef` may differ. The tool is 9.x while projects target `net8.0`.

**Queries vs repositories.** Writes go through `I<Aggregate>Repository` (Domain-owned interface, Infrastructure implementation). Reads go through `I<Thing>QueryService` returning read models or DTOs, backed by `ReadOnlyDbContext`. Do not query aggregates for read paths.

**Cross-module reads.** Modules do not reference each other's Domain or Infrastructure. They either consume integration events and maintain a local projection (see `DiPro.Wallet.Application/Common/ReadModels/`), or compose through `DiPro.Host/Aggregator`.

**Field-level permissions.** `IPermissionMapper` implementations in Application are registered in each module's `DependencyInjection.AddApplicationLayer` and strip fields the caller may not see. When adding a response that exposes sensitive fields, check whether the area already has a mapper.

## Verification

Verified on the date and branch recorded in `.ai/project/VERIFIED.md` — check that file's "Stale past" date before trusting the build/test numbers below.

```
dotnet build DiPro.sln
```
→ **0 errors, 1153 warnings, 7m21s.** The warnings are pre-existing (mostly MSB3277 unification and CS9113 unread parameters). A cold full build is slow; prefer building the single project you changed.

```
dotnet test <project>.csproj --no-build
```

**The test baseline is red. Know it before you run anything.**

The per-project numbers live in one place: "Recorded test baseline" in `.ai/project/VERIFIED.md`. In short: Customers and Wallet have pre-existing failures, Wallet and Identity runs abort with a stack overflow, FileStore passes, and Kernel discovers no tests.

Consequences for any agent doing verification work:

- Always capture the baseline for the suite you are touching **before** editing, then compare. A failing test after your change is only yours if it passed before.
- Never report "tests pass" for Customers or Wallet without naming the pre-existing failures you did not introduce.
- Do not attempt to fix these failures as a side effect of another task. Report them.
- `DiPro.Kernel.Tests` and `DiPro.Identity.Tests` currently provide no usable signal.

Note: the test project folder `DiPro.Customer.Tests` (singular) holds `DiPro.Customers.Tests.csproj` (plural). `DiPro.ProviderServices.Tests/` is a stale directory containing only `bin`/`obj`; there is no such project in the solution.

Only 5 of 104 projects have tests, and the CI pipeline (`.gitlab-ci.yml`) runs **no `dotnet test` step at all** — it builds a Docker image, bumps an image tag in a GitOps repo, and triggers an external QA project. `semgrep-sast` does run on every pipeline. Nothing automatically verifies .NET correctness, so your own verification is the only gate.

## Where to put things

- New endpoint on an existing aggregate → controller in `DiPro.<Module>`, query/command + handler + validator in `DiPro.<Module>.Application/<Aggregate>/`.
- New business rule or state transition → the aggregate in `DiPro.<Module>.Domain`, raising a domain event if other code must react.
- Reacting to another module's event → consumer in `DiPro.<Module>.Infrastructure/Messaging/Consumers/` + definition in `Definitions/`, **and** an `AddConsumer<,>()` line in that module's `Extensions/MessagingRegistrationExtensions.cs`.
- Telling other modules something happened → a record in `DiPro.<Module>.IntegrationEvents/`. This is a **published contract**; changing its shape is a breaking change.
- Anything in `DiPro.Domain/`, `DiPro.Application/`, `DiPro.Result/`, `DiPro.Observability/` → the Libra framework. Stop and get approval.

