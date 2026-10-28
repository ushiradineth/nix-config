---
name: benchmark-checklist
description:
  "Vet measured performance claims for correctness, tuning, repeatability, bottlenecks and
  end-to-end relevance before reporting or choosing a winner."
license: MIT
---

# Benchmark checklist

Write the exact claim being tested and read what the measurement actually includes. Record commits,
versions, workload, build mode and relevant machine conditions. Profile separately from timed runs.

Answer these questions with observations:

1. What limits the number? Find the hot path or constrained resource and map it to source. A
   saturated load generator measures the generator, not the service.
2. Were both sides tuned as production runs them? Match release mode, data, pools, transactions,
   cache conditions and flags. Untuned defaults cannot decide which implementation to adopt.
3. Is the result physically plausible? Compare throughput with bandwidth and cores. Removing 10% of
   a run cannot remove half its duration.
4. Did anything fail or return the wrong output? Count errors, timeouts and retries. Fast rejection
   is not successful work.
5. Does it repeat? Alternate at least five runs per side for a comparative claim. Report medians and
   ranges; a difference within run-to-run variation is not a measured win.
6. Does it matter on the path a user waits on? Measure the end-to-end effect alongside a
   microbenchmark.
7. Did the intended work happen inside the timed region? Await promises, consume generators, use
   outputs and read back the effect.

For an explicitly requested ballpark, one run can suffice; still check correctness and completed
work, label it a single run and do not use it to pick an option.

Return faster, slower, no measurable difference or inconclusive, with units, run count, range,
limiter and evidence. Missing correctness, untuned comparisons or an unknown limiter make a claimed
difference inconclusive. Do not replace measurement with an argument from source code.
