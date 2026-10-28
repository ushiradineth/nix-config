# Feature

1. Ground the affected behavior with `how`. Identify the consumer, acceptance check and existing
   behavior that must remain.
2. Name the data shape and canonical owner. Use `architect` for consequential design choices, and a
   small prototype for an observable uncertainty.
3. Implement and verify coherent units. Use `tdd` for meaningful new behavior where the existing
   test path is cheap. Keep coupled changes under one owner; delegate independent slices only when
   doing so saves time or adds useful independence.
4. Exercise the changed consumer path and integration checks. For UI work, drive the actual flow;
   use the installed browser procedure when applicable. Do not substitute a screenshot for a
   behavioral assertion.
5. Run [attack the diff](attack-the-diff.md), then report what the user can now do with evidence.
   Stop here unless delivery through a commit, PR or deployment was requested.
