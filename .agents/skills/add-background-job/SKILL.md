---
name: add-background-job
description: Adds or changes a DiPro Hangfire background job or recurring schedule. Use for job implementations, scheduling, queue assignment, retries, or job registration.
---
# Add or change a DiPro background job

Reference points: `DiPro.Host/Extensions/RecurringJobsConfiguration.cs` for recurring registration and `DiPro.Host/Extensions/BackgroundJobExtension.cs` for Hangfire server queues and global configuration. Job attributes and cancellation patterns vary; inspect a current job closest to the use case before editing.

1. **Define ownership and execution semantics.** Identify the module owning the work, the job's purpose, whether it is recurring or enqueued, expected duration, frequency, time zone, queue, and behavior if a run is delayed, duplicated, retried, or overlaps another run.
2. **Check the approval gate.** Changes to production schedules, queue topology, retry/redelivery behavior, or dependencies require explicit approval unless the request already names that action. Do not trigger production-like jobs or alter live schedules as a verification shortcut.
3. **Follow the closest job pattern.** Put module-owned job code in that module's `Infrastructure/BackgroundJobs/` and register recurring schedules in the host's recurring-job configuration. Confirm that a job's queue is served by the configured Hangfire server. Do not assume attributes belong on the class, method, or interface; follow the matching existing convention.
4. **Make repeat execution safe.** Treat retries and manual re-enqueueing as expected. Make side effects idempotent where possible; use an existing stable operation key or persisted state when appropriate. Do not add distributed locks, change concurrency behavior, or assume a retry makes an external operation safe without confirming its semantics.
5. **Handle failures and cancellation deliberately.** Inspect the global and per-job retry settings and preserve existing exception behavior. Follow the job's actual cancellation-token convention and pass cancellation through to downstream operations. Do not catch and suppress failures that Hangfire needs to observe.
6. **Keep sensitive data safe.** Use configuration/secret mechanisms for credentials. Do not log identity, biometric, card, balance, transaction, token, or external request/response data. Log only the identifiers and status needed to operate the job, after checking that they are not sensitive.
7. **Test and verify.** Add focused tests only in a suitable existing test project; follow `add-handler-tests` where applicable. Build the changed project and the host if registration or scheduling changed. Inspect the final diff for queue, schedule, time-zone, retry, and concurrency changes, then follow `verify-dipro-change`.

Report the job owner and purpose, trigger and schedule/time zone, queue and retry/concurrency behavior, idempotency strategy, cancellation/failure handling, approval-sensitive changes, and exact verification results.

<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->
