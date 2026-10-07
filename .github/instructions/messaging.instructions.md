---
description: DiPro messaging, consumer, and integration-event guidance
applyTo: "**/Messaging/**/*.cs,**/*IntegrationEvents/**/*.cs"
---
Golden examples: `DiPro.Wallet.Infrastructure/Messaging/Consumers/CustomerCreatedIntegrationEventConsumer.cs`, `.../Definitions/CustomerCreatedIntegrationEventConsumerDefinition.cs`, `.../Messaging/BaseIntegrationEventConsumerDefinition.cs`, `.../Messaging/WalletMassTransitRegistration.cs`.

## Contracts
Anything in a `DiPro.<Module>.IntegrationEvents` project is a **published contract** consumed by other modules that reference the project directly. Adding a field is usually safe; renaming, removing, retyping, or changing nullability is a breaking change requiring explicit approval and a compatibility plan. The owning module is the only one that publishes its events.

Internal messages and MediatR requests are not integration events — do not promote one to a published contract, or demote one, as a side effect of another task.

## Consumers
- `internal sealed class <Event>Consumer(ISender sender) : IConsumer<<Event>>`. The consumer does **no business logic**: it reads `context.Message`, maps it to a command, and `await sender.Send(command, context.CancellationToken)`. Business rules belong in the handler.
- Every consumer needs a matching `<Event>ConsumerDefinition` in `Definitions/`, deriving from the module's `BaseIntegrationEventConsumerDefinition<T>`. Override `RedeliveryIntervals`, `RetryIntervals`, `UseMessageRetry`, `UseDelayedRedelivery`, or the constructor's `concurrentMessageLimit` only when that consumer genuinely differs — and say why.
- **Registration is explicit, not scanned.** A new consumer is invisible until you add `configurator.AddConsumer<TConsumer, TConsumerDefinition>();` to `AddModuleConsumers()` in the module's `Extensions/MessagingRegistrationExtensions.cs` (the same file exists in Accounts, Customers, FileStore, Identity, InternalStaff, Notifications, Transactions, and Wallet). Forgetting this compiles cleanly and silently does nothing at runtime — always register the consumer and its definition together as a pair.

## Delivery semantics — verify, don't assume
- The base definition applies short in-memory retries (500ms, 1s) and then delayed redelivery (1, 5, 10 minutes by default), but **only for transient exceptions**: `TimeoutException`, `HttpRequestException`, and `TransientIntegrationException` from `DiPro.Messaging`. Anything else fails straight to the error queue. If a new external call should be retried, throw `TransientIntegrationException`.
- `UseEntityFrameworkOutbox` on the endpoint plus `UseBusOutbox()` in registration means messages published inside a handler are persisted with the transaction and dispatched only after commit. Do not publish outside the transaction to "make it faster".
- The inbox de-duplicates by MassTransit `MessageId` within a **24-hour** `DuplicateDetectionWindow`. That protects against redelivery of the *same* message. It does **not** make your consumer idempotent against a semantically duplicate event with a new id, or against redelivery after 24 hours. For anything that moves money or changes state, add an explicit idempotency check.
- Ordering is not guaranteed. Do not write a consumer that assumes event A arrives before event B.

## Blast radius
Queue topology, endpoint naming, concurrency limits, and retry configuration are operational settings with production impact. Treat changes to them as explicit design decisions, not incidental edits.
