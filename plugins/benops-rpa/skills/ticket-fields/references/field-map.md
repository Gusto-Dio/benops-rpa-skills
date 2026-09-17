# BT field map — verified against Jira, 2026-08-27

Site: `gustohq.atlassian.net` · cloudId `3fd33630-4e39-4689-ad04-db32e3843117`
Project: **BT** ("Biz Tech", id 10022, `service_desk`). Support tickets arrive as issue type
**Task** (id 10009) — auto-created from `#biztech-automations-support` Slack threads.

Everything below was read from `getJiraIssueTypeMetaWithFields(BT, 10009, requiredFieldsOnly=false)`
and cross-checked against 49 real tickets. Re-verify before trusting it (see "Re-verifying").

---

## The eight fields

| # | Field | ID | Type | Accepted values |
|---|-------|-----|------|-----------------|
| 1 | Priority | `priority` | priority | `Critical` (10001), `High` (2), `Medium` (3), `Low` (4) — default `Low` |
| 2 | Complexity | `customfield_10137` | select | `S` `M` `L` `XL` — **only these** |
| 3 | Process | `customfield_13519` | select | `Automation Ops` `Benefits` `Group Submission` `Member Level` `Packet Collection` `Reconciliation` |
| 4 | Category of Break | `customfield_17533` | **free text** | no validation — vocabulary is ours to enforce |
| 5 | Workaround Solutions | `customfield_17536` | textarea (ADF) | free text |
| 6 | Story Points | `customfield_10041` | number | `0.5` `1` `2` `3` `5` `8` observed |
| 7 | Sprint | `customfield_10020` | gh-sprint | numeric sprint **id**, as an array |
| 8 | Ticket Type? | `customfield_10397` | select | `Enhancement` (34313), `Support` (34314) — **only these** |

Note the exact Jira labels differ from how the team says them: the field is **"Workaround Solutions"**
(not "Work Around solutions") and **"Ticket Type?"** — with the question mark.

---

## Two traps that will fail your write

### Trap 1 — Complexity has orphaned legacy options

49 sampled tickets contain `Moderate` (25), `Difficult` (4), `Easy` (1) alongside `S`/`M`/`L`.
Those are **dead options left on old issues**; the current option list is `S`/`M`/`L`/`XL` only.

The cutover is clean and datable:

```
Easy / Moderate / Difficult   →  BT-73371 … BT-74721   (legacy)
S / M / L / XL                →  BT-74720 … BT-75260   (current)
```

Writing `Moderate` today is rejected by field validation. If you copy the value from a
neighbouring older ticket, you will write a dead option.

### Trap 2 — Ticket Type? has the same problem

`Issue` (BT-73383, BT-73457) and `Request` (BT-73427) appear on tickets up to BT-73457.
They are not in the current option list. Only `Enhancement` and `Support` are valid.

---

## Per-field decision rules

### 1. Priority — lift it, don't invent it

Intake text posted from Slack almost always states it:

```
Hi @biztech-automation-oncall
*Priority*: Low
*Impacted Automation*: `Anthem_MemberUpdates`
*Issue:* Spike in cases failing for 'Error on carrier portal' …
```

→ BT-75245 carries `Priority = Low`. The requester's stated priority is the default.

- Mirror the stated priority, matching case to the Jira option (`medium` → `Medium`).
- No priority stated → `Medium` if production cases are failing now, `Low` otherwise.
- **`Critical` needs explicit human confirmation.** It is unused across all 49 sampled
  tickets; setting it pages people. Ask first.
- Raising or lowering the requester's stated priority is allowed, but say why in the ticket
  comment — you are overruling the person who reported it.

### 2. Complexity — cost to fix, not severity

| | Meaning |
|---|---|
| `S` | Config/data only: asset value, password, trigger toggle, queue re-run. No XAML edit. |
| `M` | One process, a few activities: selector repair, added wait, changed condition. |
| `L` | Multiple processes, or a shared Library change, or unclear root cause. |
| `XL` | Framework/architecture, carrier re-integration, or a cross-team dependency. |

A P1 outage fixed by rotating a password is `S`. Severity lives in Priority.

**Backfilling a legacy value: translate, do not re-judge.** `Easy → S`, `Moderate → M`,
`Difficult → L`. Someone already made the sizing call; the dead value is a vocabulary problem,
not a wrong estimate. Re-deriving from the ticket text quietly overwrites their judgement with
yours on a ticket that is usually already closed. Only re-judge if the original is obviously
impossible (e.g. `Easy` on a ticket that took three weeks).

### 3. Process — scope first, then the bot name

**Ask how wide the blast radius is before you look at the bot name.**

`Benefits` is the value for work that **spans more than one process family** — a shared login
flow, a library activity like `SearchForGroup`, a carrier portal change, a credential or account
problem that hits Member Level *and* Group Submission bots together. Confirmed by the skill
owner on 2026-09-01.

That resolves what looks like inconsistency in the history: `BSCA_Terminations`,
`Beam_NewHireEnrollment_Modern` and `Anthem_CA_GroupSubmission_NewPlan` each appear under both
`Benefits` and their specific bucket. Those are not contradictions — the `Benefits` rows are the
shared/library-level tickets, the specific rows are the bot-level ones.

| Scope | Process |
|---|---|
| Spans two or more families — shared login, portal-wide change, library activity, shared credential | **`Benefits`** |
| Not a benefits carrier bot at all — robot VM, Orchestrator platform, infra | `Automation Ops` |

Only once the ticket is confined to a **single** family, match the bot in
`*Impacted Automation*` against the **trailing qualifier**, which wins over anything earlier:

| Bot name contains (checked in this order) | Process |
|---|---|
| `_Reconciliation` | `Reconciliation` |
| `_PacketCollection` | `Packet Collection` |
| `MemberUpdates`, `_Terminations`, `MemberLevel`, `NewHireEnrollment` | `Member Level` |
| `GroupSubmission`, `GroupSubmissions`, `GroupLevel`, `_Renewal` | `Group Submission` |

Order matters: `BSCA_GroupSubmissions_MemberLevel` → `Member Level`, because the trailing
qualifier is `MemberLevel`.

**The tell for `Benefits` is that no bot is named.** Tickets like "Anthem portal login flow is
changed" or "Anthem portal navigation to group search selectors were changed" describe the
portal or a shared workflow, not one automation — those are `Benefits`. On 2026-09-01 four such
tickets (BT-74839, BT-74763, BT-74699, BT-74698) were first written as `Automation Ops` and
corrected: `Automation Ops` is for things that are not carrier automation at all, and a
portal-wide Anthem change is very much carrier automation.

### 4. Category of Break — the canonical five

Source of truth: the **"Broken Bots"** sheet
(`1cdD4q1wZqUvfqRIalBAglbm_ky9Pbr7O_4bkaIFsa9g`, owner Sri Perinkolam) — the sheet these
`customfield_175xx` fields were created from. Its column uses exactly five values,
comma-separated when more than one applies:

| Value | Use when |
|---|---|
| `Portal UI Changes` | Carrier portal HTML/selectors changed; element not found; new popup or consent screen; layout moved. |
| `Process Logic Errors` | Bot code is wrong: bad condition, wrong mapping, wrong dropdown pick, unhandled case. Portal is fine. |
| `Login Issues` | Credentials, MFA, password rotation, shared-credential concurrency, session/token failures. |
| `INFRA ISSUE` | File server, AWS/bucket permissions, robot VM, network, Orchestrator platform. Note the SHOUTING — that is the sheet's spelling. |
| `Data Issues` | Source data missing or wrong: Salesforce field empty, queue item malformed, carrier file unparseable. |

Multi-value example, straight from the sheet:
`BCBS_TX_GroupSubmissions_MemberLevel_Modern` → `Process Logic Errors, Portal UI Changes, Login Issues`

**Do not copy the style of existing Jira values.** The field currently holds 32 distinct
strings across 49 tickets — `Portal Issue` / `Portal issue` / `Web Portal issues` are three
spellings of one thing, and `Enchance` and `Upcoming Renwals Toggle not selected` are in
there too. That mess is why this vocabulary is closed. Normalise to the five.

If the ticket is an enhancement and nothing is broken, this field is still not free text —
write `None — enhancement, no break`.

### 5. Workaround Solutions — what BenOps does *until* the fix ships

**Jira pre-fills this field with an empty template.** `createmeta` reports
`hasDefaultValue: true`, and on a real ticket (BT-75096) the stored value is:

```
1.
2.
3.
```

That is blank wearing a hat. It renders as content, it is non-null to any report counting
filled fields, and it is easy to skim past. **Treat `1. / 2. / 3.` — and any variant that is
just bare numbering — as empty and overwrite it.**


This is not the code fix. It is the interim instruction for the business team while the ticket
is open. Concretely: manual portal entry, re-run after a credential reset, hold the cases,
process a subset.

- One or two lines, imperative, addressed to the requester.
- `None — cases will queue until the fix deploys` is a legitimate and common answer.
- Blank is not. Blank means nobody decided what happens to today's cases.

**This field will not accept a plain string, even with `contentFormat: 'markdown'`.** It must
be a full Atlassian Document Format object:

```json
{"customfield_17536": {
  "type": "doc", "version": 1,
  "content": [{"type": "paragraph",
               "content": [{"type": "text", "text": "Hold affected cases; …"}]}]}}
```

Passing a string gives
`"Operation value must be an Atlassian Document (see the Atlassian Document Format)"`.

`customfield_17533` (Category of Break) is a `textfield`, not a `textarea`, and **does** take a
plain string — so the two adjacent free-text fields take different shapes. Do not copy one to
the other.

### 6. Story Points — elapsed days the ticket stayed open

**One story point = one calendar day open.** Set by the skill owner on 2026-08-31: Story Points
on BT measures *how long the ticket was open*, not effort or difficulty. Effort lives in
Complexity; this field is duration.

```
SP = round( (resolutiondate - created) / 1 day ),  minimum 1
```

Fetch `created` and `resolutiondate` and compute — do not eyeball it. For a ticket still open,
measure to today and update it when the ticket closes.

Worked examples from the 2026-08-31 backfill:

| Ticket | created → resolved | Elapsed | SP |
|---|---|---|---|
| BT-74700 | 08-03 → 08-10 | 7.06 d | `7` |
| BT-74763 | 08-05 → 08-10 | 5.04 d | `5` |
| BT-75048 | 08-18 → 08-21 | 2.74 d | `3` |
| BT-74699 | 08-03 → 08-04 | 1.13 d | `1` |

Calendar days, not business days — the rule is elapsed time, and business-day counting would
disagree in both directions (BT-74839 is 3.10 calendar days but 2 business days; BT-74699 is
1.13 calendar days but 2 business days).

**This will produce values outside the team's historical vocabulary.** Observed in the 49-ticket
sample: `0.5, 1, 2, 3, 4, 5, 8`. A duration rule yields `7`, `6`, `11` and so on. That is
expected — the field is no longer an estimate, so it is not confined to a planning scale. Do not
round to the nearest Fibonacci-looking number.

Calendar days, and that is also the **consistent** choice — see below.

#### Story Points does not affect the overdue calculation

Checked 2026-09-01, because the obvious worry is that a duration-based Story Point makes a
ticket look like it blew its due date. It cannot:

- **Overdue is computed from `duedate` vs `resolutiondate`, and nothing reads Story Points.**
  `Exceeded Time` (`customfield_13298`) = `resolutiondate − duedate` in **plain calendar days**
  — verified exactly on 10 tickets (BT-74700 `−4`, BT-75189 `−5`, BT-75117 `−3`, BT-75245 `−2`,
  BT-75230 `−2`, BT-75048 `−1`, BT-75030 `−1`, BT-74698 `0`, BT-74666 `0`, BT-75119 `0`).
  `Exceeded Estimated Date` (`customfield_13297`) is the Yes/No flag over it.
- **The due date is not business-day based.** Two land on weekends — BT-75048 due **Sat**
  2026-08-22, BT-75230 due **Sun** 2026-08-30. A business-day SLA cannot produce a Saturday.
- **The due date is not formula-derived either.** `created → duedate` gaps run
  +0, +1, +3, +4, +7, +8, +10, +11, +14 with no relation to Priority. It is set by hand per
  ticket, which is also why many tickets have none at all (3 of the 7 in the 2026-09-01
  backfill had `duedate: null`).

So calendar days for Story Points matches the unit the due-date machinery already uses, and
switching to business days would introduce the mismatch rather than remove it.

BT also has **`Resolution Time`** (`customfield_13296`), which looks purpose-built for duration
but is unreliable: BT-74700 holds `3` against 7.06 actual days, BT-75117 holds `3` against 11.1,
BT-75030 holds `2` against 9.0 — and BT-75260 holds `−5` while still unresolved. Do not read
from it and do not write it unless asked.

### 7. Sprint — read the active one, never type a name

BT tickets are pulled onto **board 336**, which runs BBO-named sprints. Verified active sprint
on 2026-08-27: id **31300**, `BBO FY27 Q2 C3 S9 (8/23-9/5)`, ends 2026-09-06.

Sprint ids are not guessable and the name is not accepted. Discover it every time:

```
searchJiraIssuesUsingJql(
  jql    = 'project = BT AND sprint in openSprints() ORDER BY updated DESC',
  fields = ['key', 'customfield_10020'],
  maxResults = 3
)
```

Read `customfield_10020[].id` where `state == "active"`. If the three tickets disagree on the
active sprint id, stop and ask — do not pick one.

**Write it as a bare number, not an array:** `{"customfield_10020": 31300}`.

This is asymmetric and catches everyone: Sprint **reads back** as an array of objects
(`[{"id": 31300, "name": "BBO FY27 …", "state": "active"}]`) but **writes** as a single
number. Passing back the shape you read gives:

```
"errorMessages": ["Number value expected as the Sprint id."]
"errors": {"customfield_10020": "The Sprint (id) must be a number"}
```

Unlike the other seven, Sprint is not a description of the ticket — it is a claim about which
two weeks of team capacity the work sits in. **Status decides whether you touch it:**

- **Ticket open → write the active sprint, unconditionally, overwriting a stale one.** This
  skill fires when someone picks the ticket up, so the work is happening now, in the current
  sprint. A carried-over ticket still pointing at last sprint is stale, not history.
- **Ticket `Done`/closed → leave it alone.** Adding a finished ticket to the active sprint
  inflates that sprint's committed scope and distorts velocity.

A closed sprint on a closed ticket is correct and not a gap to fill: BT-75096 is `Done` and
holds sprint 31299, `BBO FY27 Q2 C3 S8 (8/9-8/22)`, `state: closed`. Leave it.

### 8. Ticket Type? — Support or Enhancement

- `Support` — something that used to work is broken, or is failing now. 32 of 49 sampled.
- `Enhancement` — new capability, new carrier, new field, a "can the bot also…" request.

The tell is whether there is a regression. "The bot never handled this case" is `Enhancement`
even when it arrives as an angry escalation.

---

## The write order, and the two automations it feeds

Two `Automation for Jira` rules watch these fields. Neither rule definition is readable through
this connector, so both were established from issue changelogs — the automation's own edits
appear under the `Automation for Jira` app account, and the engine answers in a consistent
**2.2–2.7 s**, which is what lets you tell trigger from coincidence.

| Automation | Trigger | Writes |
|---|---|---|
| **Start date** | the transition **to `In Progress`** (id **41**) | `customfield_10015` = today, ~2.4 s later |
| **Due date** | a change to **Story Points** (`customfield_10041`) | `duedate` = **Start date + Story Points days**, ~2.2–2.7 s later |

**The Due date rule is skipped, silently, when Start date is empty — and it never retries.**
Story Points does not change again on its own, so nothing fires it a second time. That is the
whole failure mode: a ticket with every field filled and no Due date on it.

### Priority is not the trigger

It looks like one, because triage writes Priority and Story Points within seconds of each other.
Three things rule it out:

- **BT-75657** — priority `Low`, and **never changed once** across a 29-entry history. Due date
  landed anyway, 2.19 s after Story Points:

```
14:33:59.520  Diógenes      status New → In Progress
14:34:01.954  Automation    Start date → 11/Sep/26            (+2.43 s)
14:34:23.913  Diógenes      Story Points → 1
14:34:26.100  Automation    duedate → 2026-09-12              (+2.19 s)
```
  `Start date 09-11 + Story Points 1 = 09-12`.

- **BT-75495** — same shape, priority never touched: Story Points `3` → `duedate` 2.44 s later,
  `09-10 + 3 = 09-13`. Complexity had been set 59 s earlier, so it is not the trigger either.

- **Latency** — on BT-75738 the gap from the priority change to the Due date write was
  **1.02 s**, faster than the same engine's own Start date write on the same ticket (2.39 s).
  A rule cannot answer faster than its own engine; Story Points, 2.73 s earlier, is the trigger.

### The arithmetic, checked across tickets

`duedate = Start date + Story Points` calendar days:

| Ticket | Start | SP | Due | |
|---|---|---|---|---|
| BT-75657 | 09-11 | 1 | 09-12 | ✓ |
| BT-75501 | 09-09 | 1 | 09-10 | ✓ |
| BT-75495 | 09-10 | 3 | 09-13 | ✓ |
| BT-75422 | 09-03 | 1 | 09-04 | ✓ |
| BT-75372 | 09-02 | 3 | 09-05 | ✓ |
| BT-75355 | 09-01 | 1 | 09-02 | ✓ |
| BT-75245 | 08-28 | 5 | 09-02 | ✓ |
| BT-75117 | 08-28 | 6 | 09-03 | ✓ |

Tickets where Story Points or Start date was edited *after* the write do not fit, as expected.

### The failures, explained

- **BT-75719** — Story Points set at 07:38:35, **34 s before** the transition at 07:39:09. Start
  date did not exist yet, the rule was skipped, Story Points never moved again. Start date is
  set; `duedate` is still null.
- **BT-75732** — parked in `Under investigation` (111) with all four fields filled. That status
  fires **neither** rule, so neither date exists.

### What the skill does with this

**The team's order stands** — Priority, Process, Complexity, Story Points, Status, then
Workaround Solutions and Category of Break. That was the skill owner's decision on 2026-09-17,
after the mechanism above was put in front of him. Do not quietly reorder it.

That order writes Story Points at position 4, before Start date exists, so the Due date rule is
skipped on the first pass. The skill therefore **re-writes Story Points once after the
transition** (step 8 of the workflow) to give the rule its trigger with Start date present, and
reports honestly when the Due date still does not appear.

- **`In Progress` (41) specifically** for Start date. The other working statuses do not fire it.
- **One field per call.** A combined `editJiraIssue` gives Jira no ordering at all, which is the
  mechanism behind "every field filled, no dates".
- **A same-value write may not register as a change**, in which case the nudge does nothing.
  There is no way to force the rule from outside. The reliable manual repair is to move Story
  Points to a different value and back, with Start date already present.
- **Never hand-write `duedate`.** A human-written date is indistinguishable from the
  automation's in any report, and it conceals that the rule never ran.

**The durable fix is on the rule side, not ours:** if the Due date rule set Start date itself
when it is missing — or triggered on the transition as well as on Story Points — the ordering
would stop mattering for everyone, including people filling tickets by hand in the UI. That is
worth raising with whoever owns the two rules.

**What is not established:** the rule definitions themselves are not readable from this
connector, so the triggers are inferred from authorship, latency and arithmetic across ten
tickets rather than read from configuration. Priority being an additional, redundant trigger on
the same rule has not been excluded — it is only proven to be neither necessary nor responsible
for the writes observed. Whoever owns the two rules can close that gap in a minute.

---

## Transitions

Status is not a field edit. Use `transitionJiraIssue`, and pass the **transition** id, which is
not the status id:

```
transitionJiraIssue(issueIdOrKey='BT-XXXXX', transition={"id": "41"})
```

All BT transitions are global, so any of these is reachable from any status. The ones that
matter here:

| Transition | Name | → status | Note |
|---|---|---|---|
| **41** | In Progress | `3` | the one that fires **Start date** |
| 111 | Under investigation | `10171` | fires **nothing** — not a substitute |
| 31 | New | `10033` | |
| 21 | Ready for Development | `10178` | |
| 181 | Ready for PR Review | `10080` | fires a separate `PR Review Date` automation |
| 51 | Ready for Testing | `10195` | |
| 121 | Awaiting Response From User | `10186` | |
| 81 | On Hold | `10062` | |
| 71 | **Done** | `10013` | see below — has validators |

Re-read the list rather than trusting these ids if a transition is rejected:
`getTransitionsForJiraIssue(issueIdOrKey=…, sortByOpsBarAndStatus=true)`.

### Done (71) demands three fields this skill does not set

The workflow rejects the transition outright — *"Please specify Complexity & Time Spent before
closing"* and *"Field BizTech Issue Category is required"* — until all three are present.
`/ticket-fields` sets Complexity but not the other two, so **it cannot close a ticket.**

| Field | Id | Shape |
|---|---|---|
| Time Spent | `customfield_11296` | select — `0-5 min (False Positive)` 17823, `5-15 min` 17827, `15-30 min` 17829, `30-60 min` 17830, `60 min +` 17831 |
| BizTech Issue Category | `customfield_11224` | **cascading** — `{"id": parent, "child": {"id": child}}`. Parents include Bug 17204, FAQ 17205, Enhancement 17206, Task 17211 |
| Resolution | `resolution` | `{"id": "10000"}` = Done. 43 options exist, one of them literally `DO NOT USE` |

Read the allowed values off the transition itself —
`getTransitionsForJiraIssue(transitionId='71', expand='transitions.fields')`. The project's
create-meta does **not** list them.

---

## The write call

Write these **one field per call, in the order above**. The combined form below is kept only to
document the per-field shapes — do not send it as one call:

```
editJiraIssue(
  cloudId      = '3fd33630-4e39-4689-ad04-db32e3843117',
  issueIdOrKey = 'BT-XXXXX',
  fields = {
    "priority":          { "name": "Medium" },
    "customfield_10137": { "value": "M" },
    "customfield_13519": { "value": "Member Level" },
    "customfield_17533": "Portal UI Changes, Login Issues",
    "customfield_17536": { "type": "doc", "version": 1,
                           "content": [{ "type": "paragraph", "content": [
                             { "type": "text", "text": "Hold affected cases; BenOps to enter manually if urgent." }]}]},
    "customfield_10041": 3,
    "customfield_10020": 31300,
    "customfield_10397": { "value": "Support" }
  }
)
```

Shapes that bite — **four of these were wrong on the first real attempt**, so trust the table,
not intuition:

| Field | Correct | Wrong, and rejected |
|---|---|---|
| select (`10137`, `13519`, `10397`) | `{"value": "M"}` | bare string `"M"` |
| `priority` | `{"name": "Medium"}` | `{"value": "Medium"}` |
| Sprint `10020` | bare number `31300` | `[31300]`, or the sprint name |
| Workaround `17536` (textarea) | full ADF object | plain string, even with `contentFormat: 'markdown'` |
| Category of Break `17533` (textfield) | plain string | — takes a string, unlike `17536` |
| Story Points `10041` | number `3` | string `"3"` |

**A rejected write is rejected atomically** — Jira validated all eight, reported two errors, and
wrote nothing. That is better than it sounds: you get every bad shape in one response rather
than one per round trip, and there is no partial state to clean up. Read the `problems` array;
it names each field, the reason, and the `expectedShape`.

**The `editJiraIssue` response is both noisy and useless — you cannot suppress it, so just
don't read it.** The MCP tool always returns the issue back, ~100 lines of project, reporter
and avatar URLs, and it returns only the *default* read fields — `summary`, `status`,
`priority`, `assignee` and so on. **None of the seven custom fields you just wrote appear in
it.** A success response is not evidence your write landed.

Verify with a focused read, always:

```
getJiraIssue(issueIdOrKey='BT-XXXXX', fields=[
  'priority','customfield_10137','customfield_13519','customfield_17533',
  'customfield_17536','customfield_10041','customfield_10020','customfield_10397'])
```

Observed on the first real write: **shape validation is atomic** — two bad fields meant all
eight were rejected and nothing was written. So a shape error cannot leave partial state.

The verify read still matters, for the failure that validation does *not* catch: a value that
is well-formed but wrong. `{"value": "Benefits"}` is a legal Process and will be accepted
silently. Validation checks shapes, not judgement.

---

## Dry-running a write

`editmeta` answers "would this write be accepted on *this* issue" without mutating anything —
it returns the option lists as scoped to that one ticket, plus whether each field is even on
its edit screen:

```
getJiraIssue(issueIdOrKey='BT-XXXXX', expand='editmeta', fields=[
  'priority','customfield_10137','customfield_13519','customfield_17533',
  'customfield_17536','customfield_10041','customfield_10020','customfield_10397'])
```

`editmeta` is filtered by the `fields` list you pass, so asking for `['summary']` returns
editmeta for `summary` alone. Pass all eight.

Verified this way on BT-75096, 2026-08-27: all eight are present with `operations: ["set"]`,
and the issue-level option lists match the project-level ones above — Complexity really is
`S`/`M`/`L`/`XL` at the point of writing, so `Moderate` fails here and not just in theory.

## Re-verifying this map

Field ids and option lists are Jira config and change without warning — Complexity's option
list already changed once, around BT-74721. When a write is rejected on a value this file
calls valid, re-read the metadata rather than guessing a synonym:

```
getJiraIssueTypeMetaWithFields(
  cloudId='3fd33630-4e39-4689-ad04-db32e3843117',
  projectIdOrKey='BT', issueTypeId='10009',
  requiredFieldsOnly=false, maxResults=200)
```

Then update this file and say in chat that it changed.

## Related fields, deliberately not written

Same 2026 batch as Category of Break, and part of the same sheet — left alone unless asked:

| Field | ID | Sheet column |
|---|---|---|
| Customer Impact | `customfield_17534` | Customer/Internal Impact |
| Total Volume | `customfield_17535` | Total Volume (Unique Tickets) |

Also present on BT and out of scope here: `Levels of Assignees` (`customfield_13520`, L1–L4),
`Reason` (`customfield_10311`), `Blocked/Paused` (`customfield_13092`),
`Resolution Time` (`customfield_13296`).

## Story Points collides with another skill

`benops-triage-agent` instructs: *"The skill writes only `customfield_10016` (Story Points)."*
On **BT**, Story Points is **`customfield_10041`** — that is the field carrying values on real
tickets (BT-75245 = 3), and `customfield_10016` is not on BT/Task's field screen at all.
`customfield_10016` is the Story Points field in other Gusto projects, BBO among them.

That skill also says *"Never set `customfield_10020` (Sprint)"*. This skill does set Sprint,
by explicit decision of the skill owner on 2026-08-27. If someone reinstates the prohibition,
change this skill rather than letting the two disagree silently.
