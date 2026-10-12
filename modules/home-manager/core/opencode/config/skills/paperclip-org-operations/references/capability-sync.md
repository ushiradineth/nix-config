# Capability publication and refresh

Repository skills are canonical. The offline exporter produces complete packages, byte hashes and
role proposals; an authorized operator publishes them through Paperclip and verifies the final
inventory before binding a worker. Export success proves source coherence, not runtime behavior.

## Check and export

Run from the repository root with Python 3.9 or newer, using only the standard library:

```sh
python3 tests/agent-capabilities-test.py
python3 modules/home-manager/core/opencode/config/skills/paperclip-org-operations/scripts/export_capabilities.py check
python3 modules/home-manager/core/opencode/config/skills/paperclip-org-operations/scripts/export_capabilities.py export --output .agents/docs/agent-capabilities/export
```

For public CLI fixture tests, `--source-root` selects a skill-directory root and `--manifest`
selects its JSON manifest. Defaults stay inside the repository skill tree; the helper never
discovers external installed roots, reads credentials, runs exported scripts or calls an API.
External-root inventory was denied. Add external material only after separate source and license
approval; do not work around that denial. Classify `browser-workflow` after its canonical source is
created.

Every immediate source directory must have exactly one manifest entry, including empty placeholders.
Each entry declares `source`, `disposition`, `inclusion`, `roles`, `dependencies`,
`runtime_constraints` and `reason`. Dependencies are semantic skill identities; required tools and
approval conditions belong in runtime constraints. They are conditional loading requirements, not an
automatic execution graph. `complete-tree` includes every regular file, reference, license,
attribution file and executable bit. `exclude` uses `none` and explains why no package is exported.

- `import` keeps reusable guidance and all original bytes.
- `adapt` also keeps original bytes; the binding proposal supplies runtime constraints. Apply those
  constraints with the shared `engineering-quality` Paperclip mapping before assigning the package.
  OpenCode lane/helper wording cannot grant Paperclip authority. Review remains inline and leaf
  executors never dispatch nested agents.
- Role labels describe capabilities of existing eligible workers. Match them against current task,
  role, tools and approvals. Preserve report-only workers, unrelated skills and existing permission
  boundaries; importing domain or security guidance creates no new tool/service grant.

The output contains:

- `skills/<semantic-identity>/`: complete source trees, byte-for-byte, with executable files
  normalized to mode `0755` and others to `0644`. The ledger records executable status, not
  incidental umask bits.
- `ledger.json`: sorted dispositions, manifest SHA-256 and per-file source-relative path,
  decoded-byte SHA-256, byte size and executable status. There are no timestamps or machine-specific
  source paths.
- `patches.json`: offline proposals grouped by semantic identity. Each `files` item is a single file
  PATCH body with `path`, `content`, `encoding` (`utf8` or `base64`) and `executable`. Decode base64
  before hashing; UTF-8 content must be encoded without newline or Unicode normalization.
- `bindings.json`: capability/role proposals and mandatory runtime notes, without guessed agent IDs,
  skill keys or version pins. It is not a request to replace an agent's desired inventory.
- `.export-state.json`: local ownership and hash record used to verify the entire previous export
  before refresh. Retain it with the export; do not publish it as a skill file.

## Local safety and recovery

Validation rejects incomplete coverage, missing selected `SKILL.md`, mismatched frontmatter
identity, empty descriptions, unresolved declared local references, unsafe paths, case collisions,
symlinks, hardlinks, special files, dependency caches and credential-bearing filenames or recognized
content. Local file links and explicit inline reference/script pointers must stay inside their
package; traversal components are rejected. Command examples in fenced blocks are not reference
declarations. Each file is bounded to 16 MiB. The credential detector checks private-key headers,
common provider token formats and literal credential assignments; manual source review is still
required for unknown formats and encoded/opaque content. Errors never print file contents or matched
credential values.

Choose a new output path. Existing unmanaged output, even an empty directory, is rejected. Output
cannot contain or sit inside the source tree or contain the manifest. Existing symlink ancestors are
rejected. A managed refresh first verifies file hashes, executable status and exact inventory;
tampering or unrelated additions stop the export without overwriting them. Unchanged exports leave
bytes, modes and file modification times stable. Source changes update only verified owned files and
remove obsolete owned files. The helper expects exclusive local use; it is not an OS sandbox against
concurrent hostile filesystem mutation, and the ownership record is not a signed attestation.

If an export is interrupted, changed by hand or gains unrelated files, preserve it for inspection
and export to a fresh path. Do not repair its ownership record to hide drift. Keep exports private
to the operator/task; operational references can contain internal topology even when they contain no
secret.

## Publish and read back

Use the existing approved company-scoped session or semantic tools. Keep credentials in the approved
secret store/runtime context, never in this manifest, proposals, shell arguments, logs or issue
artifacts. Confirm deployed API semantics before each publication. The verified deployment at commit
`467125fafb47a8520856504fecc48d6e32055db1` has the contracts below; later deployments need fresh
checks.

1. Capture the current company catalog, targeted agents' complete bindings/pins, managed instruction
   revisions/hashes and previous immutable skill version inventories. Record rollback IDs privately.
   Preview exact source hashes, recipients, runtime notes and changes. Verify role instruction
   content is readable through an approved surface before editing it; denied access is a blocker.
   With an explicitly approved instruction-preserving task contract, keep the role content
   untouched, compare its metadata hash, and carry runtime notes in the task plus pinned skills
   instead.
2. Resolve each package by semantic identity and recorded source ownership, then verify its actual
   company skill ID/key. Generated runtime names have suffixes; neither cross-skill lookup nor
   update targeting may assume the exported directory name equals the installed runtime name. A
   collision with an unrelated skill is a blocker, not permission to overwrite it.
3. Compare the complete current version inventory against the ledger: exact file paths, decoded byte
   hashes and executable status. If all match, reuse that version and skip file PATCH and version
   POST. If bindings already use the intended verified pin, skip binding sync too. Do not version
   unchanged packages merely to record a new label or export date.
4. For an approved missing skill, `POST /api/companies/{companyId}/skills` uses the verified `name`,
   `markdown`, description and company-restricted sharing scope. Publish every reviewed file with
   `PATCH /api/companies/{companyId}/skills/{skillId}/files`, one generated file body per request.
   Never PATCH unowned files. If remote inventory has obsolete or unrelated files, stop and resolve
   them through separately verified/approved file operations; partial PATCH cannot prove exact
   parity.
5. File PATCH automatically creates versions on this deployment, so intermediate versions are not
   assignment targets. `POST /api/companies/{companyId}/skills/{skillId}/versions` accepts an
   optional `label` and snapshots the complete current inventory. Finish all files, then use the
   final verified snapshot. Re-read current inventory before finalization and abort on concurrent
   edits or conflicts.
6. `GET /api/companies/{companyId}/skills/{skillId}/files` reads **one file**, with the documented
   path selector; it is not complete inventory evidence. Use the complete files returned by
   `GET /api/companies/{companyId}/skills/{skillId}/versions/{versionId}` (and version-list
   metadata) for readback. Independently decode UTF-8/base64, calculate byte size/hash, compare
   executable status and require exact file-set equality. Server readback does not provide hashes.
   Never dump internal contents or credentials into public evidence.
7. Only after final readback, apply authorized runtime notes and additive pinned bindings using
   `POST /api/agents/{id}/skills/sync` with `mode: "add"` and
   `desiredSkills: [{"key": actualKey, "versionId": verifiedFinalVersionId}]`. Preserve all
   unrelated bindings. If a managed instruction pointer is required, use its authorized file API
   with `baseRevisionId` and `baseHash`; preserve the role body and stop on comparison conflict.
8. Read the agent's bindings back, then require an actual native run to expose the expected semantic
   skill inventory and supporting files. Package availability does not prove script/tool
   eligibility. A script exported on `shupi` does not make a Mac-only command executable there.
   Pilot and behavior tests precede broader eligible-role assignment.

## Refresh, pins and rollback

Keep default bindings small. The pinned native runner limits argv to 64 arguments and each argument
to 4,096 UTF-8 bytes; each selected skill bundle adds a read root to two filesystem-policy
arguments. Catalog availability is not permission to attach the entire catalog to every run. A
21-skill addition failed launch; three shared entrypoints passed on the verified Dot baseline. This
is not a universal skill-count limit. Respect the byte-bound guard; do not bypass it or change the
runtime to force fit.

Choose only task-relevant techniques. Paperclip supports task links of the form:

```markdown
[Technique](skill://<company-skill-UUID>)
```

These select skills from issue title, description and non-deleted comments. Such links use the
current skill version, not an immutable version pin. Verify the current version matches the reviewed
ledger before dispatch; use explicit verified pins when historical version selection is required.
Old comments can retain selections, so use clean scoped issues and never infer selection from prose
alone.

Refresh deliberately after reviewed source changes: tests, `check`, export, independent inventory
comparison, preview, authorized publication, final-version readback, additive pin change, native-run
verification. Source -> export -> immutable Paperclip version -> agent pin -> observed run is the
coherence chain. OpenCode source -> separately approved Home Manager apply -> restarted runtime is a
different chain; do not patch installed managed files directly or claim activation from export
alone.

Before rollout, preserve previous skill keys/version pins and instruction revision/hash. On a failed
pilot, use verified authorized binding operations to restore the previous pins; newly added pilot
bindings require the deployed explicit removal operation, not a guessed replace-all payload. Restore
only affected instruction files/revisions through the documented restore/CAS API after comparing
current state. Verify bindings, instruction readback and a bounded run again. Retain historical
skill versions and rollback evidence. Do not delete catalog/history or revoke unrelated connections.

This is a manual publication procedure. No recurring synchronization daemon, background API
mutation, git commit or push is part of the exporter.
