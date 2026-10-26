# Token and cost policy

## Optimize each task

- Keep the root instruction concise. Load detailed project context, path rules, and skills only when the task needs them.
- Inspect only relevant files and use targeted searches. Do not dump the whole repository or repeat information already in the conversation.
- Delegate only when a separate role or isolated context is likely to save total effort or improve quality.
- Use one implementer. Avoid duplicate implementations, unnecessary specialist chains, and overlapping edits.
- Give each delegate only the context and output format needed for its subtask. Ask for concise findings and specific evidence.
- Run the narrowest useful verification. Widen it only when the change’s impact requires it.
- Bound retries: one focused fix-and-reverify cycle by default. Re-plan before additional loops or scope expansion.

## Session and credit hygiene

Every turn resends the conversation history, so cost grows with chat length. Where the host allows it:

- Keep one task per chat. Start a new chat when you switch to an unrelated task; for a long task, use the host's compaction feature when available instead of carrying irrelevant history forward. Turn count alone is not a reliable measure of context cost.
- Before restarting, write a short carry-over summary (goal, decisions, files changed, open issues, next step), or record it in `.ai/tasks/` for multi-session work.
- Reference files by path; paste only the failing lines of build or test output, not full logs.
- For Mechanical and Light work, use a Fast-tier profile or model when you want predictable, explicit routing. Auto selection is also reasonable where supported; compare actual model choice, result quality, and credit use on your Copilot surface before making a default rule. For Medium and Heavy work, select the tier required by the task's difficulty and risk.
- Questions and explanations skip routing and delegation. Mechanical edits follow the routing table in `.ai/WORKFLOW.md`: direct when the Coordinator can edit, otherwise Utility.
- Every delegate run pays a fixed instruction cost. Generated profiles embed only the role and a short contract; pass the brief, paths, and excerpts the delegate needs rather than asking it to read kit-wide documents.
- Check credit usage before and after a large task so expensive task types become visible.

## Plan before delegation

Before delegation, record a brief execution plan. Task weight in `.ai/WORKFLOW.md` is the only size classification and decides the route. The plan covers:

- Which files and context are necessary?
- Which roles, if any, materially add value?
- What is the minimum verification that establishes the acceptance criteria?
- Does the runtime offer a token/spend cap, and what cap is appropriate?

Use the smallest route the weight table allows. Add a role only when it materially improves the result or the weight requires it. Use checkpoints and stop if the task exceeds its agreed scope or budget.

## Caps and reporting

If the host provides enforceable token or spend controls, set a task limit before execution and stop at that limit. If it does not, this policy is an optimization target only. Never claim a numerical cap, exact token savings, or guaranteed low cost without runtime evidence. When a limit prevents completing required work, report what remains and ask before continuing.

Token economy must not remove necessary context for security, money/identity, contracts, persistence, or production-impacting work. Use focused context and strong reasoning where risk requires it.
