# Channel playbooks

Each channel has different constraints and expectations. Pick the right one before drafting and
follow its rules throughout.

---

## Technical article

### Purpose

- Teach clearly.
- Explain tradeoffs honestly.
- Leave the reader with practical actions or working code.

### Constraints

- No hard word limit, but respect the reader's time. Cut sections that repeat what was already said.
- Include code blocks with language tags when showing configuration or commands.
- Link to external references and GitHub repos for full source.

### Recommended structure

1. Problem context in plain language
2. Prerequisites (if the reader needs background or tools)
3. Constraints and why they mattered
4. Chosen approach and why
5. What changed in practice (with code, config, or diagrams)
6. Tradeoffs and edge cases
7. Practical checklist, further reading, or next steps

### Rules

- Use concrete implementation details over abstract claims.
- Include at least one failure mode, caveat, or tradeoff section.
- Do not over-polish the tone. Keep it grounded.
- Use comparison tables when contrasting two approaches.
- Reference external docs with direct links, not "see the docs".
- Code blocks should be real and runnable, not pseudo-code placeholders.

---

## Tweet thread

### Purpose

- Hook fast.
- Deliver one clear idea per post.
- Keep momentum without fluff.

### Constraints

- Each post: 280 characters max. Plan for this during drafting.
- Thread length: 3-8 posts. Shorter is better unless the idea genuinely needs more.
- Number posts if the thread is longer than 3 posts (1/, 2/, etc.).
- No hashtag spam. One or two relevant tags maximum, and only if they add real reach.

### Recommended structure

1. Hook with clear stance or pain point (post 1 must stand alone)
2. Context in one short post
3. 3-6 posts with practical points
4. Close with a sharp takeaway or question

### Rules

- Keep sentences tight.
- Prefer plain verbs.
- Avoid fake hype and overuse of "game changer" language.
- If adding personality, symbol emoticons only (`:)` `:D` etc.).
- Do not use "thread" or "a thread" in the first post. Just start.
- Each post should make sense on its own if someone sees only that one in their feed.

---

## LinkedIn post

### Purpose

- Share a practical professional lesson.
- Balance story and technical credibility.
- Keep it scannable on mobile.

### Constraints

- Aim for 150-300 words. LinkedIn truncates after ~210 characters with "see more", so the first two
  lines must hook.
- No hashtag walls. Three relevant tags maximum, placed at the end.
- Line breaks matter on LinkedIn. Use them to keep the post scannable on mobile.

### Recommended structure

1. One-line opening take (this is what shows before the fold)
2. Short context paragraph
3. Specific lesson with example
4. Tradeoff or counterpoint
5. Practical close, optionally with a direct question tied to a specific decision

### Rules

- No brag-heavy opening ("I am thrilled to announce...").
- No corporate boilerplate.
- No generic CTA like "What do you think?" unless tied to a specific decision the reader actually
  faces.
- Avoid "I'm excited to share" and "proud to announce" openers.
- Do not tag 15 people for engagement farming.

---

## Documentation and runbooks

### Purpose

- Give a team member everything they need to understand or operate a system.
- Be a reliable reference that does not go stale by being vague.

### Constraints

- No word limit, but organize aggressively with headers so readers can jump to what they need.
- Every section should answer "what do I need to do" or "what do I need to know".
- Assume the reader knows the tech stack basics but not the project-specific wiring.

### Recommended structure

1. Overview: what this system/tool is and why it exists (2-3 sentences max)
2. Architecture or flow: how the pieces connect
3. Configuration: what to set, where, and why
4. Operations: how to deploy, how to debug, how to recover
5. Secrets and credentials: where they live, how to rotate (without exposing actual values)
6. References: links to upstream docs, related internal docs

### Rules

- Use code blocks for every command, config snippet, or file path.
- Use inline code for config keys, branch names, namespace names, tool names.
- Include the exact command to run, not "run the deploy script".
- Structure with sub-headers so the document works as a reference, not just a narrative.
- If a section has steps, number them.
- If a section has options, use bullets.
- Include "how to debug" sections. These are the most valuable part of any runbook.
- When explaining how components connect, state the flow explicitly: "A sends to B, B writes to C".
- Do not add motivational framing. This is a reference document, not an article.

---

## Confluence and internal wiki

### Purpose

- Same as documentation, but adapted for teams that use Confluence or similar wiki tools.

### Constraints

- Follows the same rules as documentation and runbooks.
- Use Confluence-native formatting (info panels, expand macros) when it helps readability.
- Keep pages focused on one topic. Link to related pages instead of duplicating content.

### Rules

- Same as documentation and runbooks above.
- Add a "last updated" note or rely on Confluence's built-in version history.
- If a page has TODO sections, mark them clearly so they are not mistaken for complete content.

---

## References handling (all channels)

When linking to external resources:

- Prefer direct links to specific pages, not top-level homepages.
- Format: `[Descriptive text](URL)` in articles and docs. Bare URLs are fine in runbooks.
- Group references at the end of a section or in a dedicated "further reading" section.
- If linking to a GitHub repo, link to the specific directory or file when possible.
- Do not use "click here" as link text.

---

## Output templates

Use these templates when the user asks for fast generation.

### Technical article template

```
Title:

Problem:

Prerequisites:

What we changed:

Why this approach:

Tradeoffs:

What I would do differently:

References:
```

### Tweet thread template

```
Post 1 (hook):

Post 2 (context):

Post 3:
Post 4:
Post 5:

Final post (takeaway):
```

### LinkedIn template

```
Opening take:

Context:

Main lesson:

Tradeoff or counterpoint:

Close:
```

### Documentation template

```
## Overview

## Architecture / how it works

## Configuration

## Deployment / operations

## Debugging

## Secrets and credentials

## References
```
