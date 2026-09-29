# Upstream provenance

- Repository: https://github.com/cloudflare/security-audit-skill
- Revision: `c1c8a8c1471069fb0e188eeaff69b8e8db6564a8`
- License: MIT, copied in `LICENSE`
- Source directory: `skills/security-audit/`

The 20 files copied from the source directory are maintained byte-for-byte and must not be edited or
formatted locally. Repository-specific integration belongs outside those files.

## Update procedure

1. Fetch and review the intended upstream revision in `/tmp/security-audit-skill`.
2. Replace the vendored source-directory files while preserving their Git modes, and copy the root
   `LICENSE`.
3. Update the revision above.
4. Run the per-file byte comparison, upstream Node test suite, OpenCode discovery checks, and the
   repository validation gates.
