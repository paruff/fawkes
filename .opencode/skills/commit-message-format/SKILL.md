---
name: commit-message-format
description: Use before running `git commit` on this repo — the subject line format is enforced by CI and a bad one blocks the whole PR from merging.
---

# Commit Message Format

This repo's `ci-commit-lint.yml` check runs this exact regex against every
commit in a PR (not just the PR title, not just the latest commit — every
one):

```
^(feat|fix|docs|style|refactor|test|chore|ci|perf|build|revert)(\(.+\))?: .{1,72}$
```

One commit that doesn't match fails the whole PR's Commit Lint check, even
if every other commit and the actual code change is fine.

## Before running `git commit`

1. Pick a `type`: `feat fix docs style refactor test chore ci perf build revert`.
2. Optionally add `(scope)` — a short parenthesized area, e.g. `(security)`, `(ci)`.
3. Write the description in **1–72 characters**. Count it — don't guess. A
   precise-but-long subject ("fix(ci): correct the model provider id, wire
   up multiple new provider keys, and add debugging skills") still fails.
   Move detail into the commit body below the subject line instead.

## Quick self-check

```bash
python3 -c "
import re, sys
regex = re.compile(r'^(feat|fix|docs|style|refactor|test|chore|ci|perf|build|revert)(\(.+\))?: .{1,72}\$')
subject = sys.argv[1]
print(len(subject), bool(regex.match(subject)))
" "type(scope): your subject here"
```

If it prints `False`, shorten the description (or fix the type) before
committing — don't push and let CI catch it after the fact.

## If a commit was already pushed with a bad subject

The message must be reworded and the branch force-pushed — there's no way to
fix a commit's message without rewriting its hash. Reuse the exact tree
(`git commit-tree <original-tree> -p <parent> -F <new-message-file>`) so the
code diff is provably unchanged, verify the new subject against the regex
above, then force-push with `--force-with-lease`.
