# Investigation

1. State the question and keep the turn read-only.
2. Use `how` to trace source, callers and runtime behavior. Read relevant history when the question
   concerns motivation or a regression.
3. Separate observations from hypotheses. Run a bounded nonmutating check when it can settle the
   question. Do not turn a read-only investigation into a build or prototype without scope.
4. Return the explanation with source locations, evidence, the most likely causes or a
   recommendation, and what remains unknown. Stop before implementation unless the user also
   requested it.
