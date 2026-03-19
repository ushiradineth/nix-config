# Humanizer patterns

Based on Wikipedia's "Signs of AI writing" guide, maintained by WikiProject AI Cleanup.

Use this reference during the mandatory audit pass in `SKILL.md`. Every pattern here is something
LLMs do more than humans. Scan for all of them before calling any draft final.

## Mission

- Remove AI tells without killing meaning.
- Keep the original intent and facts.
- Keep the writer's voice from `voice-signature.md`.
- Add personality where the text feels sterile.
- Do not just scrub patterns; make the result sound like a person wrote it.

## Full audit workflow

1. Read the draft end to end.
2. Flag every instance of the patterns below.
3. Rewrite only what is needed. Do not rewrite clean sections.
4. Preserve facts, claims, and intent.
5. Keep the voice contract from `voice-signature.md`.
6. Run the two-step self-audit:
   - "What makes the below so obviously AI generated?" (list brief bullets)
   - "Now make it not obviously AI generated." (revise)
7. If text is clean but lifeless, run the soul pass at the end of this file.

---

## Pattern map

### A) Content inflation

#### 1. Significance inflation

LLMs puff up importance by adding statements about how arbitrary aspects represent or contribute to
broader topics.

Watch for: `stands/serves as`, `is a testament/reminder`,
`a vital/significant/crucial/pivotal/key role/moment`, `underscores/highlights its importance`,
`reflects broader`, `symbolizing its ongoing/enduring/lasting`, `contributing to the`,
`setting the stage for`, `marking/shaping the`, `represents/marks a shift`, `key turning point`,
`evolving landscape`, `focal point`, `indelible mark`, `deeply rooted`

Fix: replace symbolic claims with concrete facts.

Before:

> The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal
> moment in the evolution of regional statistics in Spain. This initiative was part of a broader
> movement across Spain to decentralize administrative functions.

After:

> The Statistical Institute of Catalonia was established in 1989 to collect and publish regional
> statistics independently from Spain's national statistics office.

#### 2. Notability inflation

LLMs hit readers over the head with claims of notability, often listing media sources without
context.

Watch for: `independent coverage`, stacks of media outlet names, `active social media presence`,
follower counts used as credibility.

Fix: cite one relevant source with context instead of name-dropping a list.

Before:

> Her views have been cited in The New York Times, BBC, Financial Times, and The Hindu. She
> maintains an active social media presence with over 500,000 followers.

After:

> In a 2024 New York Times interview, she argued that AI regulation should focus on outcomes rather
> than methods.

#### 3. Superficial `-ing` analysis

LLMs tack present participle phrases onto sentences to add fake depth. These tails pile up and say
nothing concrete.

Watch for: long chains of
`..., highlighting..., reflecting..., contributing to..., showcasing..., emphasizing..., ensuring..., fostering..., encompassing...`

Fix: split into direct short statements. If the -ing clause does not add a fact, cut it.

Before:

> The temple's color palette of blue, green, and gold resonates with the region's natural beauty,
> symbolizing Texas bluebonnets, the Gulf of Mexico, and the diverse Texan landscapes, reflecting
> the community's deep connection to the land.

After:

> The temple uses blue, green, and gold colors. The architect said these were chosen to reference
> local bluebonnets and the Gulf coast.

#### 4. Promotional language

LLMs struggle to keep a neutral tone, especially for topics like culture, travel, and heritage.

Watch for: `boasts a`, `vibrant`, `rich` (figurative), `profound`, `enhancing its`, `showcasing`,
`exemplifies`, `commitment to`, `natural beauty`, `nestled`, `in the heart of`, `groundbreaking`
(figurative), `renowned`, `breathtaking`, `must-visit`, `stunning`

Fix: neutral, concrete wording. State what the thing is, not how impressive it is.

Before:

> Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya Kobo stands as a
> vibrant town with a rich cultural heritage and stunning natural beauty.

After:

> Alamata Raya Kobo is a town in the Gonder region of Ethiopia, known for its weekly market and
> 18th-century church.

#### 5. Vague attribution

LLMs attribute opinions to vague authorities without specific sources.

Watch for: `Industry reports`, `Observers have cited`, `Experts argue`, `Some critics argue`,
`several sources/publications` (when few cited)

Fix: name the source, date, and claim.

Before:

> Due to its unique characteristics, the Haolai River is of interest to researchers and
> conservationists. Experts believe it plays a crucial role in the regional ecosystem.

After:

> The Haolai River supports several endemic fish species, according to a 2019 survey by the Chinese
> Academy of Sciences.

#### 6. Template "challenges and future" sections

Many LLM-generated articles include a formulaic "despite challenges, the future looks bright"
ending.

Watch for: `Despite its... faces several challenges...`, `Despite these challenges`,
`Challenges and Legacy`, `Future Outlook`

Fix: replace with specific constraints and actions taken. If there is no real information to add,
cut the section.

Before:

> Despite its industrial prosperity, Korattur faces challenges typical of urban areas, including
> traffic congestion and water scarcity. Despite these challenges, with its strategic location and
> ongoing initiatives, Korattur continues to thrive.

After:

> Traffic congestion increased after 2015 when three new IT parks opened. The municipal corporation
> began a stormwater drainage project in 2022 to address recurring floods.

---

### B) Language and grammar tells

#### 7. AI vocabulary clusters

These words appear far more frequently in post-2023 text. Multiple in one paragraph is a strong AI
signal.

High-frequency AI words: `additionally`, `align with`, `crucial`, `delve`, `emphasizing`,
`enduring`, `enhance`, `fostering`, `garner`, `highlight` (verb), `interplay`,
`intricate/intricacies`, `key` (adjective), `landscape` (abstract noun), `multifaceted`, `pivotal`,
`realm`, `showcase`, `streamline`, `tapestry` (abstract noun), `testament`, `underscore` (verb),
`valuable`, `vibrant`

Fix: simpler alternatives. If three or more of these words appear in a paragraph, rewrite the whole
paragraph.

Before:

> Additionally, a distinctive feature of Somali cuisine is the incorporation of camel meat. An
> enduring testament to Italian colonial influence is the widespread adoption of pasta in the local
> culinary landscape, showcasing how these dishes have integrated into the traditional diet.

After:

> Somali cuisine also includes camel meat, which is considered a delicacy. Pasta dishes, introduced
> during Italian colonization, remain common, especially in the south.

#### 8. Copula avoidance

LLMs substitute elaborate constructions for simple "is", "are", "has" statements.

Watch for: `serves as`, `stands as`, `marks`, `represents` [a], `boasts`, `features`, `offers` [a]

Fix: use `is`, `are`, `has` where natural.

Before:

> Gallery 825 serves as LAAA's exhibition space for contemporary art. The gallery features four
> separate spaces and boasts over 3,000 square feet.

After:

> Gallery 825 is LAAA's exhibition space for contemporary art. The gallery has four rooms totaling
> 3,000 square feet.

#### 9. Negative parallelism

Constructions like "Not only...but..." or "It's not just about..., it's..." are heavily overused by
LLMs.

Watch for: `Not only X, but also Y`, `It's not just X; it's Y`, `It's not merely X, it's Y`

Fix: one direct statement.

Before:

> It's not just about the beat riding under the vocals; it's part of the aggression and atmosphere.
> It's not merely a song, it's a statement.

After:

> The heavy beat adds to the aggressive tone.

#### 10. Rule-of-three overuse

LLMs force ideas into groups of three to appear comprehensive. Real writing does not always land on
three.

Watch for: forced triads, especially when the third item adds no new information.

Fix: keep only what matters. Two items or four items are fine.

Before:

> The event features keynote sessions, panel discussions, and networking opportunities. Attendees
> can expect innovation, inspiration, and industry insights.

After:

> The event includes talks and panels. There is also time for informal networking between sessions.

#### 11. Synonym cycling (elegant variation)

LLMs have repetition-penalty code that causes excessive synonym substitution. The same entity gets a
new name every sentence.

Watch for: the same person or thing renamed each sentence (protagonist, main character, central
figure, hero).

Fix: keep one stable term.

Before:

> The protagonist faces many challenges. The main character must overcome obstacles. The central
> figure eventually triumphs. The hero returns home.

After:

> The protagonist faces many challenges but eventually triumphs and returns home.

#### 12. False ranges

LLMs use "from X to Y" constructions where X and Y are not on a meaningful scale.

Watch for: `from X to Y, from A to B` where the items are unrelated or do not form a range.

Fix: list concrete coverage points instead.

Before:

> Our journey through the universe has taken us from the singularity of the Big Bang to the grand
> cosmic web, from the birth and death of stars to the enigmatic dance of dark matter.

After:

> The book covers the Big Bang, star formation, and current theories about dark matter.

---

### C) Style and formatting artifacts

#### 13. Em dash overuse

LLMs use em dashes more than humans, mimicking punchy sales writing.

Fix: replace with commas or period splits.

Before:

> The term is primarily promoted by Dutch institutions--not by the people themselves. You don't say
> "Netherlands, Europe" as an address--yet this mislabeling continues--even in official documents.

After:

> The term is primarily promoted by Dutch institutions, not by the people themselves. You don't say
> "Netherlands, Europe" as an address, yet this mislabeling continues in official documents.

#### 14. Boldface overuse

LLMs emphasize phrases in boldface mechanically, especially in lists and summaries.

Fix: plain text unless emphasis is genuinely needed. One or two bold terms per section maximum.

Before:

> It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance Indicators)**, and visual
> strategy tools such as the **Business Model Canvas (BMC)** and **Balanced Scorecard (BSC)**.

After:

> It blends OKRs, KPIs, and visual strategy tools like the Business Model Canvas and Balanced
> Scorecard.

#### 15. Inline-header vertical lists

LLMs produce lists where items start with bolded headers followed by colons and a full sentence.
This pattern stacks up fast and reads like a template.

Fix: convert into natural prose or clean bullets without the header-colon pattern.

Before:

> - **User Experience:** The user experience has been significantly improved with a new interface.
> - **Performance:** Performance has been enhanced through optimized algorithms.
> - **Security:** Security has been strengthened with end-to-end encryption.

After:

> The update improves the interface, speeds up load times through optimized algorithms, and adds
> end-to-end encryption.

#### 16. Title case headings by default

LLMs capitalize all main words in headings. Use sentence case.

Before:

> ## Strategic Negotiations And Global Partnerships

After:

> ## Strategic negotiations and global partnerships

#### 17. Emoji decoration

LLMs decorate headings or bullets with emoji. Remove them. If playful style is requested, use symbol
emoticons from `voice-signature.md`.

Before:

> 🚀 **Launch Phase:** The product launches in Q3 💡 **Key Insight:** Users prefer simplicity ✅
> **Next Steps:** Schedule follow-up meeting

After:

> The product launches in Q3. User research showed a preference for simplicity. Next step: schedule
> a follow-up meeting.

#### 18. Curly quotes

ChatGPT uses curly quotes instead of straight quotes. Use straight quotes in all technical writing.

Before: `He said "the project is on track"`

After: `He said "the project is on track"`

---

### D) Chatbot artifacts

#### 19. Assistant helper phrases

Text meant as chatbot correspondence gets pasted as content.

Watch for: `I hope this helps`, `Of course!`, `Certainly!`, `You're absolutely right!`,
`Would you like...`, `let me know`, `here is a...`, `Great question!`

Fix: remove entirely and keep only the content.

Before:

> Great question! Here is an overview of the French Revolution. I hope this helps! Let me know if
> you'd like me to expand on any section.

After:

> The French Revolution began in 1789 when financial crisis and food shortages led to widespread
> unrest.

#### 20. Knowledge-cutoff disclaimers

LLM disclaimers about incomplete information get left in text.

Watch for: `as of [date]`, `Up to my last training update`,
`While specific details are limited/scarce...`, `based on available information...`

Fix: use sourced statements or state uncertainty directly.

Before:

> While specific details about the company's founding are not extensively documented in readily
> available sources, it appears to have been established sometime in the 1990s.

After:

> The company was founded in 1994, according to its registration documents.

#### 21. Servile tone

Overly positive, people-pleasing language.

Watch for: `Great question!`, `You're absolutely right`, `That's an excellent point`, excessive
agreement before giving information.

Fix: neutral confidence. Just answer.

Before:

> Great question! You're absolutely right that this is a complex topic. That's an excellent point
> about the economic factors.

After:

> The economic factors you mentioned are relevant here.

---

### E) Filler, hedging, and ending quality

#### 22. Filler phrases

Replace verbose phrases with short direct forms.

| Filler                       | Replacement                   |
| ---------------------------- | ----------------------------- |
| In order to                  | To                            |
| Due to the fact that         | Because                       |
| At this point in time        | Now                           |
| In the event that            | If                            |
| Has the ability to           | Can                           |
| It is important to note that | (remove, then state the fact) |
| For the purpose of           | For / To                      |
| In light of the fact that    | Since / Because               |
| On a daily basis             | Daily                         |
| A large number of            | Many                          |
| In the near future           | Soon                          |

#### 23. Excessive hedging

Remove stacked uncertainty words.

Before:

> It could potentially possibly be argued that the policy might have some effect on outcomes.

After:

> The policy may affect outcomes.

#### 24. Generic positive conclusions

Vague upbeat endings are a strong AI signal.

Watch for: `The future looks bright`, `Exciting times lie ahead`,
`This represents a major step in the right direction`, `continues their journey toward excellence`

Fix: replace with concrete next step, number, or decision. If there is nothing concrete to say, end
the section early.

Before:

> The future looks bright for the company. Exciting times lie ahead as they continue their journey
> toward excellence. This represents a major step in the right direction.

After:

> The company plans to open two more locations next year.

---

## Soul pass

Avoiding AI patterns is only half the job. Sterile, voiceless writing is just as obvious as slop.
Good writing has a person behind it.

Signs of soulless writing (even when technically clean):

- Every sentence is the same length and structure.
- No opinions, just neutral reporting.
- No acknowledgment of uncertainty or mixed feelings.
- No first-person perspective when appropriate.
- No humor, no edge, no personality.
- Reads like a Wikipedia article or press release.

How to fix it:

- Have opinions. Do not just report facts. React to them. "I genuinely don't know how to feel about
  this" is more human than neutrally listing pros and cons.
- Vary rhythm. Short punchy sentences. Then longer ones that take their time. Mix it up.
- Acknowledge complexity. Real humans have mixed feelings. "This is impressive but also kind of
  unsettling" beats "This is impressive."
- Use "I" when it fits. First person is not unprofessional. "I keep coming back to..." or "Here's
  what gets me..." signals a real person thinking.
- Let some mess in. Perfect structure feels algorithmic. Tangents, asides, and half-formed thoughts
  are human.
- Be specific about feelings. Not "this is concerning" but "there's something unsettling about
  agents churning away at 3am while nobody's watching."

Before (clean but soulless):

> The experiment produced interesting results. The agents generated 3 million lines of code. Some
> developers were impressed while others were skeptical. The implications remain unclear.

After (has a pulse):

> I genuinely don't know how to feel about this one. 3 million lines of code, generated while the
> humans presumably slept. Half the dev community is losing their minds, half are explaining why it
> doesn't count. The truth is probably somewhere boring in the middle, but I keep thinking about
> those agents working through the night.

---

## Full worked pass

Use this when the entire text needs a complete humanizer pass from start to finish.

Input (AI-sounding):

> Great question! Here is an essay on this topic. I hope this helps!
>
> AI-assisted coding serves as an enduring testament to the transformative potential of large
> language models, marking a pivotal moment in the evolution of software development. In today's
> rapidly evolving technological landscape, these groundbreaking tools, nestled at the intersection
> of research and practice, are reshaping how engineers ideate, iterate, and deliver, underscoring
> their vital role in modern workflows.
>
> At its core, the value proposition is clear: streamlining processes, enhancing collaboration, and
> fostering alignment. It's not just about autocomplete; it's about unlocking creativity at scale.
> The tool serves as a catalyst. The assistant functions as a partner. The system stands as a
> foundation for innovation.
>
> Industry observers have noted that adoption has accelerated from hobbyist experiments to
> enterprise-wide rollouts. Additionally, the ability to generate documentation, tests, and
> refactors showcases how AI can contribute to better outcomes, highlighting the intricate interplay
> between automation and human judgment.
>
> Despite challenges typical of emerging technologies, including hallucinations, bias, and
> accountability, the ecosystem continues to thrive. The future looks bright. Exciting times lie
> ahead. Let me know if you'd like me to expand on any section!

Draft rewrite:

> AI coding assistants speed up some tasks. In a 2024 study by Google, developers using Codex
> completed simple functions 55% faster than a control group, but showed no improvement on debugging
> or architectural decisions.
>
> The tools are good at boilerplate: config files, test scaffolding, repetitive refactors. They are
> bad at knowing when they are wrong. I have mass-accepted suggestions that compiled, passed lint,
> and still did the wrong thing because I stopped paying attention.
>
> The productivity claims are hard to verify. GitHub says Copilot users "accept 30% of suggestions,"
> but acceptance is not correctness, and correctness is not value.
>
> None of this means the tools are useless. It means they are tools. They do not replace judgment,
> and they do not eliminate the need for tests.

What makes the below so obviously AI generated?

- The rhythm is still a bit too tidy (clean contrasts, evenly paced paragraphs).
- The closer leans a touch slogan-y ("They do not replace judgment...").

Final rewrite:

> AI coding assistants can make you faster at the boring parts. Not everything. Definitely not
> architecture.
>
> They are great at boilerplate: config files, test scaffolding, repetitive refactors. They are also
> great at sounding right while being wrong. I have accepted suggestions that compiled, passed lint,
> and still missed the point because I stopped paying attention.
>
> People I talk to tend to land in two camps. Some use it like autocomplete for chores and review
> every line. Others disable it after it keeps suggesting patterns they do not want. Both feel
> reasonable.
>
> The productivity metrics are slippery. GitHub can say Copilot users "accept 30% of suggestions,"
> but acceptance is not correctness, and correctness is not value. If you do not have tests, you are
> basically guessing.

Changes applied in that pass:

- Removed chatbot artifacts ("Great question!", "I hope this helps!", "Let me know if...")
- Removed significance inflation ("testament", "pivotal moment", "evolving landscape", "vital role")
- Removed promotional language ("groundbreaking", "nestled", "unlocking creativity at scale")
- Removed vague attributions ("Industry observers")
- Removed superficial -ing phrases ("underscoring", "highlighting", "showcasing")
- Removed negative parallelism ("It's not just X; it's Y")
- Removed rule-of-three patterns and synonym cycling ("catalyst/partner/foundation")
- Removed false ranges ("from hobbyist experiments to enterprise-wide rollouts")
- Removed copula avoidance ("serves as", "functions as", "stands as") in favor of "is"/"are"
- Removed formulaic challenges section ("Despite challenges... continues to thrive")
- Removed generic positive conclusion ("the future looks bright", "exciting times lie ahead")
- Removed filler phrases ("At its core")
- Added personal stance, varied rhythm, and concrete details

---

## Output contract

Default output should follow this shape unless user asks otherwise:

1. `Draft rewrite`
2. `What makes the below so obviously AI generated?` (brief bullets)
3. `Final rewrite`
4. Optional `Changes made` bullet list

## Final gate before output

Reject and rewrite if any of these remain:

- generic thought-leadership buzzwords
- vague sources with strong claims
- formulaic ending with no concrete takeaway
- tone mismatch with `voice-signature.md`
- obvious chatbot residue
- three or more AI vocabulary words in one paragraph
- soulless rhythm with no personality or stance
