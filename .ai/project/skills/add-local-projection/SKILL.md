---
name: add-local-projection
description: Adds or changes a DiPro module-local read projection maintained from another module's integration events. Use for replicated read models, projection consumers, cross-module local copies, or event-fed query data.
---
# Add or change a DiPro local projection

Reference implementation: `DiPro.Wallet.Application/Common/ReadModels/` with its Infrastructure consumers, configurations, repositories, and query services.

1. **Justify the projection boundary.** Identify the source module and event owner, consuming module, queries that need the data, required fields, update/delete lifecycle, and freshness expectations. Prefer `DiPro.Host/Aggregator` when the need is request-time composition rather than a durable local read model.
2. **Define delivery behavior before coding.** Decide how create/update/delete events behave when duplicated, missing, delayed, or delivered out of order. The MassTransit inbox only de-duplicates the same `MessageId` for 24 hours. Use a stable source identifier and make projection writes idempotent; use source version/time ordering only when the source contract provides a trustworthy value.
3. **Respect ownership and approval gates.** Consume the source module's existing `.IntegrationEvents` contract without reshaping it. A new/changed contract and any local schema/migration require explicit approval unless the request already names that work. Never read another module's database schema or reference its Domain/Infrastructure project.
4. **Create the local model in Application.** Put the projection model and its repository/query-service interfaces under `Common/ReadModels/<Area>/` following the target module. Store only fields required by local queries, especially for personal or financial data.
5. **Implement persistence in Infrastructure.** Add the EF configuration, projection repository, and query service using the module's `ApplicationDbContext` for writes and `ReadOnlyDbContext` for reads. Register them in the module's established DI groups. If persistence shape changes, use `add-ef-core-migration`.
6. **Route each event through a command.** Use `add-masstransit-consumer` for the consumer, definition, and explicit registration. The consumer only maps the integration event to a projection command and sends it. The command handler owns idempotent create/update/delete behavior and returns `Result`.
7. **Expose reads through query services.** Application queries read the local projection through `I<Thing>QueryService`; they do not query the source aggregate or database. Apply `IPermissionMapper` when projected data contains fields restricted by caller permissions.
8. **Test failure and replay cases.** Where a suitable test project exists, test duplicate create, update-before-create or missing-row behavior, stale update handling when applicable, deletion/tombstone behavior, and normal success. Follow `add-handler-tests`.
9. **Verify the end-to-end wiring.** Build the consuming Application and Infrastructure projects; verify DbSets/configurations, DI, consumer definition and registration, migration when applicable, and focused tests. Follow `verify-dipro-change`.

Report source ownership, projection purpose and fields, duplicate/ordering strategy, retention/deletion behavior, contract and schema approvals, wiring checks, and exact verification results.
