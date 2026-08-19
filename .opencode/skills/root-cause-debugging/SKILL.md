---
name: root-cause-debugging
description: Use before proposing any fix for a failing test, CI job, security scan finding, or bug report. Front-load root-cause investigation over guessing.
---

# Root-Cause Debugging

**No fix without root-cause investigation first.** A fix that only makes the
symptom disappear (widening a try/except, bumping a timeout, pinning around
an error instead of understanding it) is not a fix — it is deferred rework,
and on this repo it gets caught in review.

## Before touching code

1. Read the full error/log output, not just the last line — stack traces and
   CI job logs usually name the exact failing line and cause.
2. Reproduce it. If you can't reproduce it, gather more evidence before
   guessing (add logging, run the failing step in isolation) — don't ship a
   fix for a failure you can't trigger.
3. Check what changed: `git log`/`git blame`/`git diff` on the affected file
   and its recent commits.
4. For multi-component failures (CI → build → deploy, API → service → DB),
   trace which layer actually breaks before fixing any of them — add a log
   line at each boundary if needed.
5. Grep every caller of the function/config you're about to touch. The
   root-cause fix is usually the smaller diff: one guard in the shared
   function beats patching every call site that happens to hit it.

## Fixing

- State the root cause in one sentence before writing the fix.
- Make the smallest change that addresses that cause — no bundled
  refactors, no "while I'm here" cleanup.
- If a fix doesn't resolve the issue, don't stack a second fix on top —
  re-open the investigation. Three failed fixes in a row on the same issue
  means the architecture is wrong, not that you need a fourth attempt —
  stop and say so in the PR/issue instead of continuing to guess.
