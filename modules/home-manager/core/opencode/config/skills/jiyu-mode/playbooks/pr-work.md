# PR work

Resolve the requested branch or PR and inspect its actual state. Status-only requests stay
read-only.

## Open a PR

1. Confirm the user's delivery scope and target branch. Preserve unrelated work. Use a worktree if
   isolation helps; do not move an existing change merely to satisfy a ritual.
2. Use [attack the diff](attack-the-diff.md) if the current patch has not had that review. Run the
   project's required gates and use `unslop` for the description. Explain the concrete problem,
   resulting behavior and verification.
3. Commit the scoped work and create the PR when authorized. Keep ordered commits useful to review;
   do not rewrite published history without permission.
4. Return the real PR URL and checks. Opening a PR does not start a CI-watching or merge loop.

## Address feedback or get green

Use `fix-merge-conflicts` for actual conflicts, verify each review finding against intent and
source, then use `loop-on-ci` for attached checks. Batch known fixes into one push. A request to get
a PR green authorizes the scoped fixes and pushes needed for it; it does not authorize merging. Post
replies only if the user requested communication with reviewers.

## Land

Require a request to merge. Recheck head SHA, required checks, review state and conflicts. For a
stack, verify each PR and land bottom-up without skipping an unverified dependency. A check result
from an older head is stale. Respect repository merge policy. Report what merged and the first
blocker. Never treat a green check set alone as permission to merge.
