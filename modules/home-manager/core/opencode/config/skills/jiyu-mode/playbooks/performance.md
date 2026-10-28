# Performance and hillclimbing

1. Define the metric, workload, correctness checks and target. Capture and vet the baseline using
   `benchmark-checklist`. Name the exact versions or commits being compared.
2. Profile separately from the reported timed runs. Trace the bottleneck with `how`.
3. Test one hypothesis at a time. Prefer eliminating work, repetition or waiting before optimizing
   the remaining work. Keep only changes supported by the measurement and correctness checks.
4. For sustained improvement, freeze the measurement method, log each hypothesis and result with
   `show-me-your-work`, and continue until the agreed target or stopping condition.
5. Run [attack the diff](attack-the-diff.md) on a substantive code change. Vet the final
   measurements. Report the limiter, alternating run count, median, range, end-to-end relevance and
   artifact. Uncontrolled noise, untuned comparisons or skipped work are inconclusive.
