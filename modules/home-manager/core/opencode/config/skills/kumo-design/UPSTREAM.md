# Upstream

- Repository: <https://github.com/cloudflare/kumo>
- Revision: `cdb7e0fd930b9ecadc4904b0f153b42ab4d7e273`
- Canonical source: `skills/kumo-design/SKILL.md`
- Skill Git blob: `1960396c37dd082072f9fa884d004c0017b03973`
- License: MIT, copyright 2026 Cloudflare, Inc.; `LICENSE` copies the repository root license.
- License Git blob: `631c4d3e0ae173bb364ceafd3d8f8e9fef869e8b`
- Requested installer command: `npx skills add cloudflare/kumo@kumo-design`.

## Local differences

None in `SKILL.md` or `LICENSE`; both preserve upstream bytes. This provenance file is local. The
skill is copied into the Home Manager-managed OpenCode configuration instead of running the
installer, so no other agents or global configuration are modified. Prettier excludes the upstream
skill to preserve its bytes; the Paperclip capability manifest excludes it from exports.

## Updating

1. Inspect the complete upstream skill tree and root license at an exact candidate revision.
2. Review changes against this pin before replacing the vendored files. Preserve the full skill tree
   and license, then update the revision and blob identifiers above.
3. Verify `git hash-object SKILL.md LICENSE` against the pinned blobs and run `just check` from the
   repository root.
4. Applying Home Manager and restarting OpenCode are separate operator actions; a source update does
   not activate the installed configuration.
