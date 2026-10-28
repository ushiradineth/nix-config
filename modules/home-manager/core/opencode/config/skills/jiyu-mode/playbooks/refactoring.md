# Refactoring

1. Trace the current contract. Capture a meaningful baseline before moving structure: existing
   tests, recorded outputs, snapshots or an equivalence check.
2. State the target owner, types and module shape. Use `architect` when those choices are unsettled.
   The target should remove concepts, repeated rules or hidden state.
3. Subtract obsolete layers. Move in coherent steps, preserving the baseline. Migrate every caller
   and delete the retired API in the same change. Search strings, config and documentation too.
4. Prove equivalence on the real behavior and run the required integration checks.
5. Run [attack the diff](attack-the-diff.md), then report the structural improvement, the contract
   held and the proof. Keep discovered feature changes or unrelated bugs separate unless the user
   authorizes them.
