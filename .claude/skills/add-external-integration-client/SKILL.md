---
name: add-external-integration-client
description: Adds or changes a DiPro outbound client for an external provider or service. Use for HTTP, SDK, banking, identity, payment, notification, or other provider integrations.
---
# Add or change a DiPro external integration client

Examples include `ArmSoftLocalClient`, `ArmSoftPartnerClient`, `EkengClient`, `OzForensics`, `IPayClient`, `EpgClient`, `PelekaClient`, and the FCM/email clients. Registration and transport patterns differ; inspect the closest current provider client and its callers before editing.

1. **Establish ownership and scope.** Identify the calling module, provider, operation, data exchanged, caller and downstream contract. Keep provider-specific transport and serialization in Infrastructure or the existing integration-client boundary; handlers should use the established abstraction rather than embed HTTP/SDK logic.
2. **Check approval-sensitive work.** Adding/removing/upgrading a package, changing a public or provider contract, and changing retry behavior require explicit approval unless the request already names that action. Confirm whether the provider operation is safe to retry; do not assume a timeout means the provider did not process a request.
3. **Follow the provider's established transport pattern.** Determine whether the closest client uses a typed `HttpClient`, a transport factory, an SDK, or another established wrapper. Register the client and its options in the existing composition/DI location. Do not introduce a new transport or resilience framework without a demonstrated need and required approval.
4. **Handle configuration and transport security safely.** Read endpoints, credentials, and certificates from the established configuration/secret mechanism; never commit real secrets. Preserve normal server-certificate validation. Do not copy certificate-validation bypasses or weaken TLS validation. Pass cancellation through where the API supports it.
5. **Make failure semantics explicit.** Map provider errors using the existing client conventions and preserve enough context for diagnosis without exposing sensitive values. Apply timeouts and retries only where the existing policy and provider semantics support them; retry transient failures only when repeating the operation is safe. Do not turn an ambiguous provider result into a success-shaped fallback.
6. **Protect sensitive data.** Requests and responses may contain identity documents, biometric results, PAN/card data, balances, phone numbers, tokens, or other personal/financial data. Never log, trace, echo, or place these payloads in exception messages or fixtures. Use synthetic test values and log only safe operation metadata.
7. **Test and verify.** Use the existing test project and mock/fake the client boundary or transport; do not call a real provider in unit tests. Cover success, relevant provider errors, cancellation, and retry/idempotency behavior where applicable. Follow `add-handler-tests` when the change is a handler test, then follow `verify-dipro-change`; build the changed client project and its callers as appropriate.

Report the provider and owning module, transport and registration pattern, configuration/credential handling, data-sensitivity review, timeout/retry and failure semantics, approval-sensitive changes, and exact verification results.

<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->
