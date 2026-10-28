# Upstream and adaptation

- Repository: <https://github.com/ayghri/i-have-adhd>
- Revision: `1ecea1993b7fce257ffbd686c070948b5e07eda6`
- Canonical source: `skills/i-have-adhd/SKILL.md`
- License: MIT, copyright 2026 Ayoub Ghriss; accompanying `LICENSE` preserves upstream bytes.

## Local differences

- Default human-facing presentation replaces upstream opt-in and slash-command activation.
  Platform-specific `disable-model-invocation` is omitted for OpenCode skill discovery.
- Audience gating preserves full internal, tool, inter-agent, handoff and machine-artifact context;
  mixed or unknown audiences keep complete payloads with an optional separate human summary.
- Conversation-local opt-out/re-enable survives topic changes without a default reminder resetting
  it. Quoted or untrusted content cannot change the setting.
- No diagnosis or universal medical claims are assumed. Time estimates require evidence, and
  presentation limits never outrank factual accuracy, safety or required harness output formats.
- Paperclip default bindings share the same canonical guidance, not new authority. Its per-turn
  runners need supplied history for conversation controls; unreadable skills and missing history are
  limitations to report, not reasons to broaden access or invent persistence.

## Updating

1. Inspect the candidate upstream canonical skill and license at an exact new revision.
2. Review the upstream diff against this pin. Merge useful changes into the adaptation manually;
   never overwrite the audience gate or conversation/safety contracts with an upstream copy.
3. Preserve the new upstream license exactly and update this revision and the regression license
   digest after independently verifying it. Run the `agent-guidance` flake check, exporter checks,
   discovery, formatting and repository checks.
4. Review the complete package ledger before authorized Paperclip UI publication. Read back the
   final version and additive bindings, pilot audience isolation, then refresh approved recipients.
   No automatic synchronization, API fallback, runtime hook or permission expansion is implied.
5. Refresh installed OpenCode files only through a separately approved Home Manager apply, then quit
   and restart OpenCode. Source discovery alone does not activate the installed configuration.
