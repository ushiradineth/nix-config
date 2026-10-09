# Organization growth

## Start from outcomes

Use this order when expanding the organization:

1. Define the recurring outcome and why current ownership fails.
2. Improve the issue, instructions, skill, or routine if that is enough.
3. Add a specialist only when separate ownership or permissions improve reliability.
4. Add management layers only when coordination load is observable.

An org chart is not progress. Durable outputs, resolved decisions, reliable routines, and shorter
user feedback loops are progress.

## Work structure

- **Goals** hold durable outcomes and priorities.
- **Projects** group work with a coherent deliverable or operating area.
- **Issues** are bounded units with an owner, completion evidence, and final disposition.
- **Child issues** delegate independent work without losing the parent outcome.
- **Routines** repeat proven procedures; they are not a substitute for an undefined process.
- **Interactions and approvals** carry decisions that require the user or a reviewer.
- **Artifacts and documents** preserve reusable outputs and accepted plans.

Keep one accountable owner per issue. Delegation does not remove the parent owner's responsibility
to integrate evidence and close the outcome.

## Hiring decision

Create an agent only when at least one is true:

- the work recurs and needs durable ownership;
- it requires a distinct permission or data boundary;
- it needs specialist instructions and evaluation;
- independent review materially reduces risk;
- Dot's coordination quality is falling because it is doing specialist execution.

Do not hire an agent merely because a task has a job-like title. For sporadic work, assign an
existing agent a bounded issue with the right skill.

Before hiring, produce a role contract from `agents-and-dot.md` and one acceptance task. Ask for
approval when the role changes budgets, access, manager structure, or recurring activity.

## Delegation through Dot

Dot should remain the user's front door while specialists own execution. A healthy flow is:

1. Dot clarifies the outcome and material ambiguity.
2. Dot answers directly or creates a scoped issue.
3. Dot delegates independent specialist work as child issues.
4. Specialists leave durable evidence and a clear disposition.
5. Dot integrates results, surfaces decisions, and reports the outcome to the user.

Do not make the user coordinate agents manually. Do not let Dot conceal agent failures or report a
plan as completed work.

## Routines

Turn a procedure into a routine only after one successful manual run. Define:

- owner and beneficiary;
- schedule and timezone;
- read versus write authority;
- inputs and connections;
- expected artifact or state change;
- timeout, retry, and budget limits;
- failure notification and escalation;
- pause or retirement condition.

For checks such as official connector availability, avoid noisy duplicate tasks. Update one durable
task or artifact, and pause the routine once its migration condition has been met.

## Organization review

Periodically review:

- goals without active projects or owners;
- projects with no current next action;
- blocked issues without a named unblock owner;
- recurring work still performed manually;
- routines that fail, duplicate work, or no longer affect decisions;
- agents with overlapping roles or no durable output;
- connections and secrets with no active consumer;
- expensive model use on work a smaller model handles reliably;
- small-model failures that justify stronger routing;
- pending approvals and decisions that stall several branches of work.

Make one narrow correction at a time and measure whether the work improves. Avoid broad org
restructures without evidence.
