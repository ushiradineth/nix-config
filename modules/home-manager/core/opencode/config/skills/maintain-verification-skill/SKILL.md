---
name: maintain-verification-skill
description:
  "Check a project verification recipe and feature map against current source and live behavior;
  repair only the verification package."
license: MIT
---

# Maintain a verification skill

Locate the named project-local verify skill and read its launch, doctor, drive, evidence and cleanup
instructions. If no target exists, report that and use `create-verification-skill` only when
requested.

Compare its feature map and commands with current source. Cover every mapped feature and look for
new entrypoints the map misses. Parallel source readers can help independent features, but one
coordinator owns a shared live instance.

Run the recipe on the real consumer paths. Health-check after surprising failures, reset to known
state when needed, clean failed attempts and preserve existing proof artifacts. A feature that
cannot be reached needs its actual missing prerequisite and attempted route.

Edit only the verification package. Correct doc or driver drift and rerun every affected recipe.
Report product regressions as findings; do not change the product or weaken the expected behavior to
make a journey pass.

Return clean, changed or blocked, with feature coverage, proof, gaps and cleanup status. A
source-only pass is not clean live coverage. Commit or open a PR only within the user's delivery
request.
