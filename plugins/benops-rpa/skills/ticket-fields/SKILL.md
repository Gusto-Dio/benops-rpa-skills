---
name: ticket-fields
description: Use when starting work on, triaging, investigating, picking up, assigning, commenting on, or closing a BizTech support ticket (BT-xxxxx) — including before reading Orchestrator logs, before reading XAML, before opening a PR, and before moving a ticket to In Progress or Done. Also use when a ticket is missing Priority, Complexity, Process, Category of Break, Workaround Solutions, Story Points, Sprint, or Ticket Type, when a ticket has no Start date or Due date, or when those fields need auditing across several tickets.
argument-hint: <BT-key> [BT-key …]
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto]
allowed-tools: [mcp__claude_ai_Jira_Confluence__getJiraIssue, mcp__claude_ai_Jira_Confluence__editJiraIssue, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Jira_Confluence__getJiraIssueTypeMetaWithFields, mcp__claude_ai_Jira_Confluence__getTransitionsForJiraIssue, mcp__claude_ai_Jira_Confluence__transitionJiraIssue, mcp__claude_ai_Jira_Confluence__addCommentToJiraIssue, mcp__claude_ai_Gsheets_Gusto__fetch, Read, AskUserQuestion, Skill]
---

# BT Ticket Fields

## Output Language
**Always respond in English** for anything written into Jira, regardless of the language used
in the conversation. Chat with the user in their language.

## Overview

Eight fields make BT support tickets reportable: Priority, Complexity, Process, Category of
Break, Workaround Solutions, Story Points, Sprint, Ticket Type?. They are filled from evidence
already in the ticket — the intake text names the bot and states a priority — so they can be
set before any investigation, and they are what makes the ticket findable afterwards.

Core principle: **the fields are part of picking up the ticket, not part of closing it.**
A ticket in progress with empty fields is invisible to every report the team runs.

**The writes go one field at a time, in the team's stated order.** Two Jira automations key off
these fields — one sets Start date, one sets Due date — so a single combined `editJiraIssue`,
which gives Jira no ordering at all, is what leaves a ticket fully filled with no dates. See
step 6 for the order and step 8 for the Due date repair.

## The Gate

**Set the eight fields before doing anything else to a BT ticket.**

Before pulling Orchestrator logs, before reading XAML, before proposing a fix, before opening
a PR — the fields go in first. They cost one Jira read and a short ordered sequence of writes.

This applies when the ticket is already `In Progress`, when someone else is assigned, and
when you were only asked "what's wrong with BT-75245". Answering a question about a ticket is
working on the ticket.

**Violating the letter of this rule is violating the spirit of it.**

## Workflow

1. **Read the ticket.** Fetch `summary`, `description`, `comments`, `status`, `created`,
   `resolutiondate`, and all eight current values. The description is the Slack intake text: it
   names the bot in `*Impacted Automation*` and usually states `*Priority*`. `created` and
   `resolutiondate` are what Story Points is computed from; `status` decides whether Sprint is
   written at all.

2. **Read `references/field-map.md`.** Field ids, current option lists, the two legacy-option
   traps, and the per-field decision rules all live there. Do not fill these fields from
   memory of what the options were — Complexity's option list already changed once.

3. **Derive all eight.** Every value traces to something in the ticket or to a rule in the
   field map. If a value cannot be derived, that field is the one to ask about — not all eight.

4. **Discover the active sprint and write it.** Query `sprint in openSprints()` and read the
   numeric id; never type a sprint name.

   **Ticket open → write the active sprint, unconditionally.** Overwrite a stale one. This
   skill runs when someone *picks the ticket up*, so by definition the work is happening in
   the current sprint; a carried-over ticket still pointing at last sprint is wrong, not
   history worth preserving.

   **Ticket `Done`/closed → leave Sprint alone.** Adding a finished ticket to the active
   sprint inflates its committed scope and distorts velocity. A closed sprint on a closed
   ticket is correct and is not a gap to fill.

5. **Show the eight values in a table and ask for confirmation** before writing. One
   `AskUserQuestion` or a plain yes/no — the user is accountable for these values, and
   Priority in particular overrules the person who reported the issue. Say in the same breath
   which Status you are about to move the ticket to.

6. **Write in the order below, one call per step. Never batch them.**
   Two Jira automations read these writes, and both are order-sensitive — the full evidence is
   in `references/field-map.md` under *The write order*. A single combined `editJiraIssue`
   gives Jira no order at all, which is how a ticket ends up with every field set and no dates.

   This is the team's order, as circulated by the PM. Follow it.

   | # | Write | Note |
   |---|---|---|
   | 1 | **Priority** | |
   | 2 | **Process** | |
   | 3 | **Complexity** | |
   | 4 | **Story Points** | |
   | 5 | **Status → `In Progress`** (transition **41**) | fires the **Start date** automation |
   | 6 | **Sprint**, **Ticket Type?** | not in the stated order; safe here |
   | 7 | **Workaround Solutions**, **Category of Break** | the team fills these last |

   **Only transition a ticket you are actually picking up**, and only if it is not already in a
   working status. `Under investigation` (111) does **not** fire either automation, so it is
   not a substitute for `In Progress`.

   **One consequence to expect, and repair.** The Due date automation triggers on a **Story
   Points** change and writes `Start date + Story Points days`. In this order Story Points is
   written at step 4, before Start date exists, so the rule is skipped — and it does not retry,
   because Story Points never moves again on its own. Step 8 handles that.

   Evidence for the mechanism is in `references/field-map.md` under *The write order*: BT-75719
   wrote Story Points 34 s before the transition and has no Due date to this day, while BT-75657
   and BT-75495 wrote it afterwards and both got one.

7. **Verify with a focused read — including both dates.** The `editJiraIssue` response echoes
   the issue back but contains **none of the custom fields you just wrote**; it is not evidence.
   Shape errors are atomic: Jira rejects every field and writes nothing, listing each problem
   with its `expectedShape` in one `problems` array — fix from that array rather than guessing
   one field per retry.

   Read back the eight **plus `customfield_10015` (Start date) and `duedate`**. The automations
   land ~2.2–2.7 s after their trigger, so if a date is still empty, re-read once before
   concluding it failed.

8. **If Due date is empty, nudge Story Points once — then stop.** Start date now exists, so
   re-writing Story Points gives the Due date rule its trigger with the input it needs. Write
   the same value back and re-read.

   If it is still empty after that, **say so plainly and name the cause** — Jira may not record
   a same-value write as a change, and there is no way to force the rule from outside. Do not
   invent a Due date by hand: a human-written `duedate` is indistinguishable from the
   automation's in reports, and it hides the fact that the rule never fired.

9. **Report what was set and what was left.** Name any field you could not derive and say why,
   and state whether both dates landed. If Due date did not, that is worth mentioning out loud
   rather than burying — it is the thing the order exists to produce.

Then, and only then, continue to whatever was actually asked.

## Standalone vs. inside an investigation

- **Standalone:** `/ticket-fields BT-75245`, or several keys to audit and backfill a batch.
  With several keys, derive and confirm per ticket — one bad batch write is eight bad tickets.
- **Inside `benops-rpa:benops-ticket-investigation`:** this is that skill's Phase 0. Run this
  first, then hand off. That skill's Iron Rule — logs before code — still holds; this gate sits
  in front of it, and the two do not compete: fields come from the intake text, not from logs.
- **Inside `benops-rpa:benops-triage-agent`:** that skill sets Story Points as
  `customfield_10016`, which is not BT's Story Points field, and forbids writing Sprint. Both
  points are addressed in the field map. Let this skill own the eight fields.

## Refining after investigation

Two fields legitimately change once the root cause is known: **Category of Break** and
**Complexity**. Update them then — that is not a failure of the first pass, it is the point of
a first pass that was cheap.

Do not use "I'll know more later" as a reason to leave them blank now. An initial
`Portal UI Changes` corrected to `Process Logic Errors` on day two is worth more than two days
of blank.

## Quick Reference

Listed **in write order** — the order is part of the answer, not a table sort.

| # | Field | ID | Default when nothing else is known |
|---|---|---|---|
| 1 | Priority | `priority` | as stated by requester; else `Medium` if failing now |
| 2 | Process | `customfield_13519` | spans >1 family → `Benefits`; else from the bot name |
| 3 | Complexity | `customfield_10137` | `M` — cost to fix, not severity |
| 4 | Story Points | `customfield_10041` | elapsed days open — `round(resolved − created)`, min 1 |
| 5 | **Status** | transition **41** → `In Progress` | only when picking the ticket up; fires **Start date** |
| 6 | Sprint | `customfield_10020` | ticket open → active sprint id, always; `Done` → leave alone |
| 6 | Ticket Type? | `customfield_10397` | `Support` if a regression, else `Enhancement` |
| 7 | Workaround Solutions | `customfield_17536` | `None — cases will queue until the fix deploys` |
| 7 | Category of Break | `customfield_17533` | one of the canonical five |
| 8 | *(repair)* Story Points again | `customfield_10041` | only if `duedate` came back empty |

Story Points does double duty: it is the team's record of how long the ticket was open **and**
the number of days the Due date automation adds to Start date. Those agree by construction —
one point per day — so the Due date is "started on X, expected to take N days".

Canonical Category of Break, comma-separated when several apply:
`Portal UI Changes` · `Process Logic Errors` · `Login Issues` · `INFRA ISSUE` · `Data Issues`

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll fill them when I close the ticket" | The fields exist to make in-flight work visible. Filled at close, they were never used. |
| "I don't know the root cause yet" | Six of eight come straight off the ticket — intake text plus its own dates. Only Category of Break and Complexity depend on the cause, and both get refined later — see above. |
| "The user just asked me a quick question about it" | Answering a question about a ticket is working on the ticket. Gate applies. |
| "Someone else is assigned" | The gate is per ticket, not per person. Fill them and say so. |
| "It's already In Progress, too late" | Then it is overdue, not exempt. |
| "I'll copy the values from a similar ticket" | Neighbouring tickets carry dead options — `Moderate` and `Issue` no longer validate. Read the field map. |
| "Workaround Solutions doesn't apply here" | `None — cases will queue until the fix deploys` is the answer. Blank means nobody decided what happens to today's cases. |
| "Workaround Solutions already has content" | Check what it is. Jira pre-fills it with an empty `1. / 2. / 3.` template that reads as filled to both you and any report. Treat the template as blank. |
| "It's an enhancement, nothing is broken" | Write `None — enhancement, no break`. The field is still not blank. |
| "Logs first — the investigation skill says so" | Logs before *code*. Fields come from intake text, not logs. No conflict. |
| "The ticket is about to be closed anyway" | Closed tickets are what the reports read. |

## Red Flags — STOP

- About to call `uip`, read a `.xaml`, or open a PR for a BT key whose fields you have not read
- About to put all the fields in **one** `editJiraIssue` call — that is the order bug
- About to write a `duedate` by hand because the automation did not fire — it is
  indistinguishable from the automation's in reports and hides that the rule never ran
- About to use `Under investigation` (111) as the working status — it fires neither automation
- About to call the write done without re-reading `customfield_10015` and `duedate`
- About to write `Moderate`, `Difficult`, `Easy`, `Issue`, or `Request` into a select field
- About to write a sprint **name** instead of a numeric id
- About to move a `Done` ticket into the active sprint
- About to pick a single Process family for a ticket that names no bot — that is `Benefits`
- About to leave Workaround Solutions blank, or accept its `1. / 2. / 3.` default as filled
- About to treat an `editJiraIssue` success response as proof the fields landed

**All of these mean: stop, read `references/field-map.md`, then proceed.**

## Common Mistakes

- **Conflating Complexity with Priority.** A P1 outage fixed by a password rotation is `S`.
- **Treating Story Points as effort.** On BT it is *duration* — days the ticket stayed open.
  Effort is Complexity. Compute Story Points from `created`/`resolutiondate`; never estimate it.
- **Setting `Critical`.** Unused across all 49 sampled tickets; it pages people. Confirm first.
- **Bare strings into select fields.** They need `{"value": "..."}`; `priority` needs `{"name": "..."}`.
- **Writing eight fields to eight tickets in one unconfirmed sweep.** Confirm per ticket.
- **Trusting this skill's option lists after a rejection.** Re-read the metadata; the field map
  has the call.
