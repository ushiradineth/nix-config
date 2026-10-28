---
name: loop-on-ci
description:
  "Inspect PR-attached checks and fix scoped failures until green. Use for get this PR green,
  monitor checks or loop on CI."
license: MIT
---

# Loop on CI

Use `gh pr checks` as the source of truth for attached checks, including checks outside GitHub
Actions. Resolve the exact PR and current head before polling.

1. Inspect current checks before waiting:
   `gh pr checks <pr> --json name,bucket,state,workflow,link`.
2. Diagnose existing failures first. Read the linked provider's logs; use
   `gh run view <run-id> --log-failed` for GitHub Actions.
3. For pending checks, use a bounded watch or periodic checks. Remain responsive; do not hold a
   blocking watch so long that the user cannot steer. Record the head SHA the results cover.
4. Fix the evidenced cause, run the relevant local checks and batch known fixes into one authorized
   push. Reinspect the whole attached check set after every push; it may change.
5. Stop when every required check on the current head passes, or a concrete missing prerequisite
   prevents progress. A flake can be retried once with evidence; repeated unexplained failures need
   diagnosis. Cancelled, skipped and missing checks are not automatically successful.

Do not bypass hooks, weaken tests or merge merely because checks pass. Inspect unrelated failures
against the base before importing trunk or widening the patch. A read-only status request reports
status and stops; it does not start this repair loop. Return the PR URL, fixes, final head and
checks.
