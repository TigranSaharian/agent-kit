# Mandatory <project name> guardrails

> Template. These are technical safety constraints that apply to every task in this repository. Keep it short: it is loaded on every task.

## Sensitive data

Treat <list your sensitive data: personal identifiers, payment data, credentials, tokens, ...> as sensitive. Never log, trace, echo in responses, or place it in exception text, test fixtures, or commits.

## Authorization scope

Stop and get explicit approval before changing:

- <authentication or authorization behavior>
- <shared framework or foundation code used by many modules>
- <published contracts: public API, events, database schema>
- <dependencies: adding, removing or upgrading packages>

Path-based triggers are enforced by `PROTECTED_PATHS.txt`; the rest relies on review.

## Test-completion gate

A change that touches behavior is not complete until:

- The tests that cover it were run after the last edit, with the exact command and counts reported.
- New or changed tests were discovered and passed.
- Failures that existed before the change are named separately from new ones.
