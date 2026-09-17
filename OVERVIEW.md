# BenOps RPA Skills — Team Overview

How our Claude Code skills are structured, why we moved to a plugin, and how any team member can install everything in two commands.

---

## The Problem We Solved

Before this repo, skills lived as loose `.md` files on each engineer's machine:

```
~/.claude/commands/
  morning.md
  analyze.md
  followup.md
  ...
```

No version control. No history. Onboarding = "send me your files."

---

## The Solution: A Versioned Plugin

We modeled this after how Gusto's own teams (`usp-shared`, `sfdc-shared`) distribute Claude Code plugins — a GitHub repo with a defined structure that Claude Code's plugin system understands.

### Repository Structure

```
benops-rpa-skills/
│
├── .claude-plugin/
│   └── marketplace.json        ← registers this repo as a Claude Code marketplace
│
└── plugins/
    └── benops-rpa/             ← the plugin
        ├── .claude-plugin/
        │   └── plugin.json     ← manifest: name, version, list of skills
        ├── CHANGELOG.md
        ├── README.md
        ├── hooks/                   ← runs automatically, nothing to invoke
        │   ├── hooks.json           ← which event fires which script
        │   └── bt-ticket-fields-gate.sh
        └── skills/
            ├── morning/
            │   └── SKILL.md
            ├── analyze/
            │   └── SKILL.md
            ├── benops-ticket-investigation/
            │   ├── SKILL.md
            │   └── references/
            │       ├── orchestrator-log-queries.md
            │       └── investigation-rules.md
            ├── ticket-fields/
            │   ├── SKILL.md
            │   └── references/
            │       └── field-map.md ← Jira field ids, option lists, write shapes
            └── ... (4 more skills)
```

### Key Files Explained

**`marketplace.json`** — tells Claude Code this repo is a plugin store. Without it, `claude plugins marketplace add` fails.

**`plugin.json`** — the plugin manifest. Declares name, version, and the full list of skills. This is what shows up in `claude plugins list`:
```
❯ benops-rpa@benops-rpa-skills
    Version: 1.3.0
    Status: ✔ enabled
```

**`SKILL.md`** — the skill content. Each file starts with a YAML frontmatter block that tells Claude Code what the skill does and what it's allowed to use:
```yaml
---
name: morning
description: Daily briefing — reads Slack, Jira, and GitHub in parallel
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, slackgustoofficialmcp]
allowed-tools: [mcp__claude_ai_Slack_Gusto_Offical__slack_search_public_and_private, ...]
---
```

**`references/`** — for complex skills, heavy technical content (API queries, rule tables) lives here instead of in the main `SKILL.md`. Keeps skills readable without losing detail.

---

## What Changed in Each Skill

### Frontmatter fields (added to every skill)

| Field | What it does | Example |
|---|---|---|
| `sdlc_phases` | Tags the skill by lifecycle phase | `[operate]` or `[test]` |
| `requires_mcp` | Declares which MCP connectors are needed | `[jiraconfluencegusto, githubgusto]` |
| `allowed-tools` | Restricts what tools the skill can call | `[mcp__slack__search, Skill, Agent]` |

`allowed-tools` is the most important — a skill that only needs to read Slack and Jira shouldn't be able to edit files or run shell commands. This makes skills auditable and safe to share.

### Config section (added to user-facing skills)

Skills that contain personal values (`morning`, `followup`, `benops-sync`, `benops-ticket-investigation`) now have a **Config table** at the top of the skill body:

```markdown
## Config
Update these values when deploying for a different user.

| Key | Value |
|---|---|
| My name        | `Diogenes` |
| My Slack handle | `@diogenes` |
| GitHub login   | `Gusto-Dio` |
| ...            | ...         |
```

All personal references in the execution steps point to Config keys — nothing is hardcoded in the logic. A new team member only needs to update the Config table; the rest of the skill works as-is.

---

## Before vs After

| | Before | After |
|---|---|---|
| **Install for new member** | "Send me your files" | 2 commands (see below) |
| **Update** | Replace files manually | `claude plugins update benops-rpa@benops-rpa-skills` |
| **Version** | None | Semantic versioning + CHANGELOG |
| **Security** | Skill can use any tool | `allowed-tools` limits surface |
| **Dependencies** | Implicit | `requires_mcp` declares them explicitly |
| **History** | Local git only | GitHub, visible to the whole team |

---

## Installing (New Team Member)

```powershell
# Step 1 — Add the repo as a marketplace (one time)
claude plugins marketplace add Gusto-Dio/benops-rpa-skills

# Step 2 — Install the plugin
claude plugins install benops-rpa@benops-rpa-skills

# Future updates
claude plugins update benops-rpa@benops-rpa-skills
```

That's it. All 8 skills are available immediately.

---

## Available Skills

| Skill | Invocation | Purpose |
|---|---|---|
| `morning` | `/morning` | Daily briefing — Slack + Jira + GitHub priority sweep |
| `analyze` | `/analyze` | Review current branch for XAML issues before PR |
| `benops-ticket-investigation` | `/benops-ticket-investigation BT-XXXXX` | Production failure investigation — Orchestrator logs first |
| `benops-triage-agent` | `/benops-triage-agent BT-XXXXX` | First-response triage for support tickets |
| `benops-sync` | `/benops-sync` | Sync BenOps Notion Hub with current PR and Jira statuses |
| `followup` | `/followup` | Daily status update to Sri/Oscar via Slack |
| `benops-rpa-setup` | `/benops-rpa-setup` | Interactive VDI setup for new team members |
| `ticket-fields` | `/ticket-fields BT-XXXXX` | Fill the eight reportable fields on a BT ticket |
| `uipath-test-cases-from-ticket` | `/uipath-test-cases-from-ticket BT-XXXXX` | Create Staging test cases from a Jira ticket |

There is also one **hook**, which you never invoke: mention a `BT-xxxxx` in any prompt and it
reminds Claude to run `ticket-fields` first. See below.

---

## Using `ticket-fields`

### What it is for

Eight fields on a BT ticket are what the team's reports read: **Priority, Complexity, Process,
Category of Break, Workaround Solutions, Story Points, Sprint, Ticket Type?**. A ticket you are
actively working with those fields empty is invisible to every one of those reports.

The design principle is that **the fields belong to picking the ticket up, not to closing it.**
Filled at close, they were never used for anything.

### How to use it

```
/ticket-fields BT-75245                    # one ticket
/ticket-fields BT-74698 BT-74699 BT-74666  # a batch to backfill
```

You can also just mention the ticket in a normal prompt. The hook will notice the key and
prompt Claude to run this first — you do not have to remember the command.

It **reads the current values before writing**, so running it twice is harmless. If everything
is already filled it will tell you and stop.

Claude derives all eight, **shows you a table, and waits for confirmation before writing.** You
are accountable for these values — in particular Priority, where writing a value overrules the
person who reported the issue. Check the table rather than waving it through.

### The order it writes in, and why it matters

Two Jira automations key off these fields, so the skill writes **one field at a time, in a fixed
order** rather than all at once:

1. Process → 2. Complexity → 3. Story Points
4. **Status → `In Progress`** — this is what sets the **Start date**
5. **Priority** — this is what sets the **Due date**
6. Sprint, Ticket Type? → 7. Workaround Solutions, Category of Break

**Priority goes after the Status change, not before it.** The Due date automation fires on a
Priority change and computes from the Start date, so a Priority set while the ticket is still
`New` produces no Due date at all — the ticket ends up fully filled with no dates on it. That
is the failure the order is there to avoid, and it is why this differs from the sequence
circulated in Slack. The changelogs behind it are in
`skills/ticket-fields/references/field-map.md` under *The write order*.

Two related gotchas worth knowing by hand:

- **`Under investigation` is not a substitute for `In Progress`.** It fires neither automation,
  so a ticket parked there never gets dates.
- After the writes, the skill re-reads the eight **plus both dates** and tells you whether they
  landed. The automations take 1–9 seconds, so "not there yet" and "did not fire" look the same
  for a moment.

### What each field means here

| Field | Rule |
|---|---|
| **Priority** | Mirror what the requester wrote in the intake text (`*Priority*: medium`). `Critical` needs a human decision — it pages people. |
| **Complexity** | Cost to fix, **not** severity. `S` config only, `M` one process, `L` several bots or a Library change, `XL` framework or cross-team. A P1 outage fixed by a password reset is `S`. |
| **Process** | Scope first. Spans more than one family — shared login, a library activity, a portal-wide change → **`Benefits`**. Not carrier automation at all → `Automation Ops`. One family only → derive from the bot name's trailing part (`BSCA_GroupSubmissions_MemberLevel` → `Member Level`). |
| **Category of Break** | Exactly five values, comma-separated when several apply: `Portal UI Changes`, `Process Logic Errors`, `Login Issues`, `INFRA ISSUE`, `Data Issues`. From Sri's "Broken Bots" sheet, which is where these fields came from. |
| **Workaround Solutions** | What BenOps does **until** the fix ships — not the code fix. `None — cases will queue until the fix deploys` is a real answer. Blank is not. |
| **Story Points** | Days the ticket was open: `round(resolved − created)`, minimum 1. **Duration, not effort** — effort is Complexity. |
| **Sprint** | Ticket open → the active sprint, always. Ticket `Done` → left alone. |
| **Ticket Type?** | `Support` if something regressed, `Enhancement` if the bot never handled the case — even when it arrives as an escalation. |

Full detail, including the exact Jira field ids and API write shapes, is in
`skills/ticket-fields/references/field-map.md`. You do not need to read it; Claude does.

### Two traps it exists to avoid

**Old tickets carry dead option values.** Complexity used to be `Easy`/`Moderate`/`Difficult`
and Ticket Type? used to include `Issue`/`Request`. Those options were replaced — the current
lists are `S`/`M`/`L`/`XL` and `Enhancement`/`Support`. Copying a value off a similar older
ticket now fails Jira validation. Half of a 49-ticket sample still holds the dead values.

**A successful write is not proof.** Jira's edit response echoes back only the default fields
and none of the custom ones. The skill always re-reads the eight afterwards to confirm. If you
ever fill these by hand through the API, do the same.

### The hook

`hooks/bt-ticket-fields-gate.sh`, on `UserPromptSubmit`. When your prompt contains a
`BT-xxxxx`, it adds a note to Claude's context pointing at this skill.

- **Non-blocking by design.** It can never stop a prompt — including "what did we decide on
  BT-75245?". A hook that blocks on a false match is worse than no hook.
- **It only reads the prompt text.** Say "fix this Anthem bot" without a key and it stays quiet.
  That is a known limit, accepted deliberately: catching work at the moment a tool runs would
  need a `PreToolUse` gate, which is more intrusive than the team wanted.
- Paths in the payload are stripped before matching, so working in a folder named after a ticket
  does not trigger it.
- To silence it for yourself, disable the plugin's hooks in `/config`. No repo change needed.

### Where it sits in the other workflows

- **`benops-ticket-investigation`** runs it as Phase 0. That does not conflict with the Iron
  Rule — logs come before *code*, and these fields come from the intake text and the ticket's
  own dates, so nothing is guessed early.
- **`benops-triage-agent`** delegates the eight fields here rather than writing them itself, so
  one skill owns the field ids and the current option lists.

---

## Extending This Plugin

To add a new skill:

1. Create `plugins/benops-rpa/skills/<skill-name>/SKILL.md`
2. Add the skill frontmatter (`name`, `description`, `sdlc_phases`, `allowed-tools`)
3. Add an entry to `plugin.json` under `pages.components`
4. Bump the version in `plugin.json` and add an entry to `CHANGELOG.md`
5. Push — team members run `claude plugins update benops-rpa@benops-rpa-skills`

---

## Reference

- Plugin repo: `github.com/Gusto-Dio/benops-rpa-skills` (private)
- Pattern reference: `github.com/Gusto/usp-shared` (how Gusto's USP team does the same thing)
- Claude Code plugin docs: `claude plugins --help`
