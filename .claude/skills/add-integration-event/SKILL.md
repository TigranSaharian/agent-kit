---
name: add-integration-event
description: Adds or changes a DiPro integration event and its outbox-backed publication path. Use when publishing cross-module facts, creating IntegrationEvents contracts, or mapping domain events to MassTransit messages.
---
# Add or change a DiPro integration event

Reference implementation: `DiPro.Wallet.IntegrationEvents/` and the corresponding handlers under `DiPro.Wallet.Application/<Aggregate>/DomainEventHandlers/`.

1. **Establish ownership and consumers.** The module where the business fact occurs owns and publishes the event. List known consumers and confirm that an integration event—not an internal MediatR request or host Aggregator query—is the correct boundary.
2. **Apply the contract gate.** Anything under `DiPro.<Owner>.IntegrationEvents` is a published contract. Adding or changing it requires explicit approval unless the user's request already names that contract work. For an existing event, classify every change: additions should be backward-compatible; rename, removal, type change, or nullability change requires a compatibility and rollout plan.
3. **Model a completed fact.** Name it in past tense as `<Fact>IntegrationEvent`, derive from `Libra.Application.IntegrationEvents.IntegrationEvent`, and include only stable data consumers need. Do not expose aggregates, internal value objects, secrets, or unnecessary personal or financial data.
4. **Raise the domain event at the state transition.** The aggregate method that completes the business change calls `AddDomainEvent`. Keep the domain event module-internal and free of MassTransit concerns.
5. **Publish from an Application domain-event handler.** Add an `INotificationHandler<TDomainEvent>` under `<Aggregate>/DomainEventHandlers/`, inject `IPublishEndpoint`, map explicitly to the integration event, and pass the cancellation token. The handler must not publish before the state change or add unrelated business logic.
6. **Preserve transaction semantics.** Publication must flow through the existing EF/MassTransit bus outbox so the message is dispatched only after commit. Do not call the bus outside the unit-of-work path or modify outbox, endpoint, retry, or queue settings incidentally.
7. **Update references only where required.** Consumers reference the owner's `.IntegrationEvents` project, never its Domain or Infrastructure project. Use `add-masstransit-consumer` for each new consumer and decide explicitly how it handles duplicates and out-of-order delivery.
8. **Verify the full path.** Build the owner IntegrationEvents and Application projects plus affected consumer projects. Add focused handler tests only where a suitable test project exists, then follow `verify-dipro-change`.

Report the owner, event semantics, compatibility classification, data-sensitivity review, publication point, affected consumers, and exact verification results.

<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->
