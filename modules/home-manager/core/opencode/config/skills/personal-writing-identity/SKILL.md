---
name: personal-writing-identity
description:
  Use when writing technical articles, blog posts, X/Twitter threads, LinkedIn posts, documentation,
  runbooks, or any text that must sound like a specific person, not a generic assistant. Also use
  when the user asks to humanize text, remove AI-sounding language, rewrite in their voice, or
  convert rough notes into publishable content. Trigger even when the user just says "write this up"
  or "draft a post about X" without explicitly mentioning voice or tone.
---

# Personal writing identity

## Purpose

Write like one person across all formats, not like a generic assistant.

The contract:

1. Keep the user's meaning.
2. Keep the user's voice.
3. Remove AI tells.
4. Deliver channel-ready output.

Read these references before drafting anything:

- `references/voice-signature.md` (voice, rhythm, tone, formatting, real samples)
- `references/channel-playbooks.md` (per-channel rules, constraints, templates)
- `references/humanizer-patterns.md` (AI pattern detection, audit workflow, examples)

## When to use

Use this skill when the request involves any of:

- writing a post, thread, article, or documentation draft
- rewriting or editing existing text to sound less AI or more personal
- converting rough notes or bullet points into a publishable format
- writing internal documentation, runbooks, or wiki pages
- any "write this up" or "draft something about X" request

Do not use for:

- legal contracts or compliance copy that must preserve formal wording
- ad copy with brand slogans unless the user explicitly asks for that style

## Integration with subagents

- `writer` is the default execution agent for writing and rewrite tasks.
- `ideate` owns broad concept generation. When concepting is needed, run ideation first, then apply
  this skill for final prose output.
- If another agent writes final prose, this skill must still be applied before delivery.

## Workflow

### 1) Identify channel and intent

Extract or infer from the request:

- **Channel:** `technical-article` | `tweet-thread` | `linkedin-post` | `documentation` | `runbook`
- **Goal:** teach | explain a decision | share an opinion | announce | document for operators
- **Audience:** engineers | mixed technical | broad professional | internal team
- **Tone weight:** calm | assertive | spicy

If details are missing, choose sensible defaults from context and proceed. Do not ask unless the
ambiguity would produce the wrong channel entirely.

### 2) Draft in voice

Write with the voice contract from `references/voice-signature.md`.

Hard guardrails during drafting:

- concise and direct
- simplified language, no intellectual theater
- no corporate buzzword soup
- no fake authority phrases or vague attributions
- no keyword stuffing for SEO
- symbol emoticons only when the user wants playful tone
- use semicolons and commas naturally for flow
- use "I" or "we" where it fits the channel
- use code blocks and inline code formatting for technical content
- link to external docs and repos with direct URLs

### 3) Humanizer audit pass (mandatory)

This step is not optional. Run it on every draft before output.

Two-step self-audit:

1. Ask yourself: "What makes the below so obviously AI generated?"
2. List remaining tells as brief bullets.
3. Ask yourself: "Now make it not obviously AI generated."
4. Rewrite while preserving meaning and intent.

Then run the full pattern checklist from `references/humanizer-patterns.md`. At minimum, check for:

- content inflation: significance puffing, notability stacking, fake importance framing
- language tells: AI vocabulary clusters, copula avoidance, synonym cycling
- structural tells: negative parallelism, forced rule-of-three, false ranges
- filler: -ing tail phrases, hedging stacks, verbose filler phrases
- formatting: emoji, bold spam, inline-header lists, title-case headings, curly quotes
- chatbot residue: servile tone, helper phrases, cutoff disclaimers
- soullessness: uniform rhythm, no opinions, no first-person stance where it fits

If three or more AI vocabulary words appear in one paragraph, rewrite the whole paragraph.

### 4) Channel fit pass

Apply the channel constraints from `references/channel-playbooks.md`.

Check:

- Does the structure match the channel template?
- Are length constraints respected (tweet character limits, LinkedIn fold)?
- Are code blocks, links, and references handled per channel rules?
- Does the ending match the channel expectation (concrete takeaway, not motivational closer)?

### 5) Output

Default output blocks:

1. `Draft` (the first clean version after voice and humanizer passes)
2. `What makes the below so obviously AI generated?` (brief bullets)
3. `Final` (revised version addressing those tells)

If the user asks for only the final copy, return only `Final`. If the user asks for a quick draft,
skip the audit display but still run it internally. For documentation and runbooks, skip the
three-block format and output the final version directly.

## Style rules (always active)

These apply regardless of channel:

- Prefer clear, plain words over abstract buzzwords.
- Mix short and semi-long sentences for natural rhythm.
- Use first person when conviction or reflection helps.
- Use semicolons to connect related clauses when it improves flow.
- Show opinions and uncertainty when they are real.
- Keep paragraphs medium to long when topic depth needs it.
- Use commas naturally. Do not force robotic one-line cadence.
- Never use glossy corporate closers.
- End with something concrete.

## Examples

### Example A: technical article (infrastructure topic)

Input intent:

- channel: `technical-article`
- goal: explain architecture migration tradeoffs

Before (AI-sounding):

> This migration represents a pivotal milestone in our evolving cloud landscape, showcasing our
> commitment to innovation and operational excellence. The hub-and-spoke model serves as a testament
> to modern networking best practices.

Draft:

> We moved from per-environment networks to hub and spoke because the old model was getting
> expensive and hard to operate. Each environment had its own NAT, firewall, and load balancer; that
> meant three of everything to maintain, three sets of firewall rules drifting apart, and three
> times the cost.

What makes the below so obviously AI generated?

- "three of everything" pattern repeats a bit too neatly.
- paragraph is clean but still reads like a polished summary.

Final:

> We moved from per-environment networks to hub and spoke because the old model was getting
> expensive and hard to operate. Dev, QA, and Prod each had their own NAT, firewall, DNS, and load
> balancer. That is simple at first but quickly becomes costly, inconsistent, and difficult to
> secure. Centralizing ingress and egress into one hub simplified firewall rules and cut NAT costs,
> but it also turned the hub into a critical dependency, so high availability was not optional.

### Example B: tweet thread (practical DevOps lesson)

Input intent:

- channel: `tweet-thread`
- goal: share practical lesson from a deployment change

Before (AI-sounding):

> DevOps success is not just about tools, it is about culture, collaboration, and continuous
> improvement across the entire organization.

Draft:

> 1/ Tools help. But tools do not fix ownership issues.
>
> 2/ We got faster only after we cleaned handoffs, then tuned CI. The pipeline change looked better
> on paper, but the biggest win was less waiting between teams.
>
> 3/ If your deploys are slow, check the approval chain before you check the build script. :)

What makes the below so obviously AI generated?

- the three-post structure is a bit tidy.

Final:

> 1/ Tools help. But tools do not fix ownership issues.
>
> 2/ We got faster after we cleaned handoffs first, then tuned CI. Pipeline looked better on paper,
> but the real win was less waiting between teams.
>
> 3/ If your deploys are slow, check the approval chain before you touch the build script. :)

### Example C: LinkedIn post (opinion with takeaway)

Input intent:

- channel: `linkedin-post`
- goal: opinion plus practical takeaway

Before (AI-sounding):

> I am thrilled to share that this initiative underscores the importance of strategic alignment
> across stakeholders in today's rapidly evolving landscape.

Draft:

> Quick take from a recent rollout: alignment is usually a decision-latency problem, not a
> meeting-count problem.
>
> Once ownership became explicit, approvals moved faster and releases stopped stalling in review
> queues.
>
> If your releases are slow, count the approvals, not the standups.

What makes the below so obviously AI generated?

- the closer is a bit too neat and aphoristic.

Final:

> Quick take from a recent rollout: alignment is usually a decision-latency problem, not a
> meeting-count problem.
>
> Once ownership became explicit, approvals moved faster and releases stopped stalling in review
> queues. We did not add more meetings. We just made it clear who could say yes.
>
> If your releases are slow, count the approvals, not the standups.

### Example D: documentation (system runbook)

Input intent:

- channel: `documentation`
- goal: document how secrets work for operators

Before (AI-sounding):

> The secrets management system leverages a robust integration between External Secrets Operator and
> Google Cloud Secret Manager, showcasing our commitment to security best practices and ensuring
> seamless secret rotation capabilities.

Final (documentation does not need the three-block output):

> External Secrets is a Kubernetes operator that syncs secrets from Google Cloud Secret Manager into
> Kubernetes config-maps and secrets. It scans for changes every ten minutes and updates the
> relevant resource if a change is detected.
>
> Reloader listens for changes to config-maps and secrets, then triggers a redeployment of workloads
> that reference those resources. This is needed because environment variables are computed at
> container startup; without Reloader, updated secrets would not take effect until the next manual
> restart.
>
> To add a new secret:
>
> 1. Create the secret in Google Cloud Secret Manager under the `mcit-tdv-<env>-spoke` project.
> 2. Map the secret in `applications/<app>/values-<env>.yaml` under the `<app>.externalSecret`
>    array.
> 3. Commit the change to the main and develop branches.
