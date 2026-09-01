---
name: ticket-fields
description: Use when starting work on, triaging, investigating, picking up, assigning, commenting on, or closing a BizTech support ticket (BT-xxxxx) — including before reading Orchestrator logs, before reading XAML, before opening a PR, and before moving a ticket to In Progress or Done. Also use when a ticket is missing Priority, Complexity, Process, Category of Break, Workaround Solutions, Story Points, Sprint, or Ticket Type, or when those fields need auditing across several tickets.
argument-hint: <BT-key> [BT-key …]
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto]
allowed-tools: [mcp__claude_ai_Jira_Confluence__getJiraIssue, mcp__claude_ai_Jira_Confluence__editJiraIssue, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Jira_Confluence__getJiraIssueTypeMetaWithFields, mcp__claude_ai_Jira_Confluence__addCommentToJiraIssue, mcp__claude_ai_Gsheets_Gusto__fetch, Read, AskUserQuestion, Skill]
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

## The Gate

**Set the eight fields before doing anything else to a BT ticket.**

Before pulling Orchestrator logs, before reading XAML, before proposing a fix, before opening
a PR, before transitioning status — the fields go in first. They cost one Jira read and one
Jira write.

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
   Priority in particular overrules the person who reported the issue.

6. **Write once, then verify with a focused read.** The `editJiraIssue` response echoes the
   issue back but contains **none of the custom fields you just wrote** — it is not evidence.
   Shape errors are atomic: Jira rejects every field and writes nothing, listing each problem
   with its `expectedShape` in one `problems` array. Fix from that array rather than guessing
   one field per retry. Then verify regardless — validation catches malformed values, never
   wrong ones.

7. **Report what was set and what was left.** Name any field you could not derive and say why.

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

| Field | ID | Default when nothing else is known |
|---|---|---|
| Priority | `priority` | as stated by requester; else `Medium` if failing now |
| Complexity | `customfield_10137` | `M` — cost to fix, not severity |
| Process | `customfield_13519` | spans >1 family → `Benefits`; else from the bot name |
| Category of Break | `customfield_17533` | one of the canonical five |
| Workaround Solutions | `customfield_17536` | `None — cases will queue until the fix deploys` |
| Story Points | `customfield_10041` | elapsed days open — `round(resolved − created)`, min 1 |
| Sprint | `customfield_10020` | ticket open → active sprint id, always; `Done` → leave alone |
| Ticket Type? | `customfield_10397` | `Support` if a regression, else `Enhancement` |

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
- About to transition a ticket without having set the eight
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
