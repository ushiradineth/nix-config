# cshu incident playbook

## Intake

Before collecting broadly, establish:

- exact symptom and user-visible impact
- first and most recent occurrence, including timezone
- affected players or clients and whether `shuwin` reproduces it
- last known good time
- recent server, client, mod, config, Java, launcher, or network changes
- whether the request is informational, read-only diagnosis, or a requested fix

Do not run live commands outside user-invoked `sudo`. Within `sudo`, keep diagnosis read-only until
a specific mutation is separately confirmed.

## Build the feedback loop

Apply `diagnose` before proposing causes:

1. Choose one bounded signal that can reproduce or directly detect the reported symptom. Examples
   are a timestamped log slice, crash signature, connection failure, startup outcome, or measured
   tick/load symptom.
2. Record why that signal distinguishes this incident from nearby failures, its runtime, and whether
   it is deterministic.
3. Gather the smallest evidence set needed to rank 3 to 5 falsifiable hypotheses.
4. Test one variable at a time. Do not mutate the environment during hypothesis testing without the
   action-specific confirmation required by the skill contract.

No red-capable signal means no confident root-cause claim. Ask for the missing artifact or read-only
access instead.

## Evidence matrix

| Fault domain   | Minimum evidence                                                                        | Useful discriminator                                                     |
| -------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Server runtime | Server log/crash window around the symptom, startup completion, player join/leave event | Does the server record the same time and failure?                        |
| Client runtime | `shuwin` latest log/crash report from the active profile                                | Does failure occur before connection, during login, or after world load? |
| Version/loader | Minecraft, Java, and loader versions from both sides                                    | Are protocol and loader expectations aligned?                            |
| Mod set        | Normalized mod filenames and versions; hashes when practical                            | Is a mod missing, extra, wrong-loader, or version-skewed?                |
| Configuration  | Relevant server and client config with source and timestamp                             | Is the difference intentional, generated, or stale?                      |
| Network        | Resolved game endpoint and bounded reachability evidence                                | Is the failure before application protocol startup?                      |
| Backup/mirror  | Latest mirror and Restic success time, artifact source, and age                         | Is recovery material current enough for the proposed rollback?           |

Normalize timestamps before correlating evidence. Record timezone, source host, file origin, and
whether an artifact is live, mirrored on `shupi`, or restored from Restic.

## Triage order

1. Separate server-wide symptoms from one-client symptoms.
2. Confirm the current game endpoint, profile, Minecraft/Java/loader versions, and last known good
   time.
3. Align server and client logs to the same event window.
4. Compare mod manifests before interpreting loader, mixin, registry, recipe, or data-pack errors.
5. Compare only the configuration files relevant to the symptom.
6. For lag or stalls, establish resource/tick evidence before blaming warning volume.
7. Rank hypotheses with a prediction and a read-only falsification check for each.

## Historical signal patterns

These are prior observations, not permanent causes:

- A 2026-10-01 `shuwin` NeoForge log skipped several Fabric jars, reported duplicate embedded
  dependencies, and emitted many refmap/mixin warnings.
- The same client session logged Voxy and compatibility warnings but still reached the world.
  Presence alone does not prove the reported incident.
- A 2026-09-30 server log contained registry, loot-table, recipe, tag, and physics-property parsing
  errors plus many biome-category warnings. Correlate any recurrence with the current symptom and
  mod versions before treating it as causal.

Warnings that predate the symptom, occur on successful starts, or do not align across affected
clients are background until a falsifiable test connects them to impact.

## Mutation and rollback gate

Before requesting confirmation for a fix:

1. State the confirmed cause or the hypothesis being tested.
2. Name one exact mutation, target, and arguments.
3. State expected effect, verification signal, and rollback action.
4. Report the age/source of the backup or original file needed for rollback.
5. Ask for confirmation immediately before that mutation only.

Do not bundle an edit with an upload or restart. A retry, changed target, changed arguments,
follow-up restart, restore, or cleanup needs new confirmation. If the live lifecycle-control
interface is unknown, stop rather than assuming SFTP can control the service.

## Post-change verification

After each confirmed mutation:

- rerun the targeted signal
- rerun the original unminimized symptom check
- inspect the same server/client log window for new failures
- confirm no unrelated file or mod changed
- report rollback readiness and remaining uncertainty

## Incident report shape

Return:

1. `Symptom`: exact impact and scope.
2. `Evidence`: source, timestamp/timezone, and key observation.
3. `Fault domain`: server, client, network, compatibility, configuration, or unknown.
4. `Hypotheses`: ranked prediction and falsification result.
5. `Conclusion`: confirmed cause or bounded uncertainty.
6. `Next action`: one read-only check or one mutation awaiting exact confirmation.
