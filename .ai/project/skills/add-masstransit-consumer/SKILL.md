---
name: add-masstransit-consumer
description: Adds or changes a MassTransit consumer in DiPro. Use for integration-message handling, consumer registration, or consumer tests.
---
# Add or change a DiPro MassTransit consumer

Reference implementation: `DiPro.Wallet.Infrastructure/Messaging/` — consumer, definition, base definition, and `Extensions/MessagingRegistrationExtensions.cs`.

1. **Establish ownership.** Which module publishes the event? Events live in `DiPro.<Owner>.IntegrationEvents` and are a published contract — you consume them, you do not reshape them.
2. **Write the consumer** in `DiPro.<Module>.Infrastructure/Messaging/Consumers/` as `internal sealed class <Event>Consumer(ISender sender) : IConsumer<<Event>>`. It maps `context.Message` to a command and sends it with `context.CancellationToken`. No business logic in the consumer — that belongs in the handler.
3. **Write the definition** in `Definitions/`, deriving from the module's `BaseIntegrationEventConsumerDefinition<TConsumer>`. Override retry/redelivery intervals or `concurrentMessageLimit` only if this consumer genuinely differs, and explain why.
4. **Register it — this is the step that gets missed.** Add `configurator.AddConsumer<TConsumer, TConsumerDefinition>();` to `AddModuleConsumers()` in `Extensions/MessagingRegistrationExtensions.cs`. Registration is explicit, not assembly-scanned: an unregistered consumer compiles cleanly and silently never runs.
5. **Handle idempotency deliberately.** The EF inbox de-duplicates by MassTransit `MessageId` for 24 hours. It does not protect against a semantically duplicate event carrying a new id, redelivery beyond the window, or out-of-order arrival. For anything that moves money or changes state, add an explicit check and say what guarantee you are relying on.
6. **Retries only cover transient exceptions** — `TimeoutException`, `HttpRequestException`, and `TransientIntegrationException`. Anything else goes straight to the error queue. Throw `TransientIntegrationException` if a new external call should be retried.
7. **Add focused tests** for the command handler in the module's existing test project, following its conventions. If the module has no test project, report that rather than creating one.
8. **Verify and review**: run the module's tests (check the baseline first — the suite is red), then review duplicate handling, failure semantics, logging, and whether any sensitive field reaches the logs.

Do not assume every consumer shares the same retry or delivery guarantees. Queue topology, endpoint naming, and concurrency limits are operational decisions requiring explicit approval.
