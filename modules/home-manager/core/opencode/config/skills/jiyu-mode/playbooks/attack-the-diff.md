# Attack the diff

Use this sequence before delivering a substantive code change, before a requested commit or PR, or
when the user says attack the diff. It is one review boundary for the completed coherent change, not
a loop after every file. Apply the distinct rubrics inline for routine bounded fixes. Use fresh
reviewers when an explicit attack request or consequential risk earns independent scrutiny. Obvious
one-line edits need only the relevant inline check.

1. Pin the scope and intent. Include task-owned staged, unstaged and untracked files, the consumer
   contract, required behavior and current verification. Preserve unrelated work.
2. Run `deslop` over that actual diff. Remove narration, redundant defenses, dead compatibility
   paths and casts that hide a missing type. Do not widen the task to nearby cosmetic cleanup.
3. Run `no-comments`. Use a fresh read-only `reviewer` when independent scrutiny is warranted.
   Preserve licenses, public contracts, external constraints and non-obvious rationale. Encode an
   accepted constraint when it is an in-scope improvement; do not erase it to satisfy a comment
   quota.
4. Run `interrogate` to attack correctness. Seek failing cases at the changed boundaries, rerun
   material reproductions, and separate proven defects from checks blocked by prerequisites.
5. Run `thermo-nuclear-code-quality-review` to challenge the implementation's structure. Look for a
   different owner, model or direct flow that removes whole branches, wrappers or shared state. Give
   this pass the current diff after cleanup, not only the correctness review's summary.
6. Fix accepted in-scope findings. Reject a suggestion with evidence when it violates the goal or
   adds more complexity. New scope remains a recommendation unless authorized. If a finding changes
   the design, revisit `architect` rather than adding another workaround.
7. Rerun affected checks and inspect the final diff. Reopen only the review affected by a material
   fix; do not restart every passing phase after a typo. Return the review outcomes, real findings,
   proof and remaining gaps. A review-only request reports findings without implementing them.

Independent review is most useful where the author can miss an assumption. The primary owns the
final judgment and verification. If a reviewer is unavailable, run the distinct passes inline, state
that independence was unavailable, and do not claim an independent verdict.
