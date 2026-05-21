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
| `uipath-test-cases-from-ticket` | `/uipath-test-cases-from-ticket BT-XXXXX` | Create Staging test cases from a Jira ticket |

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
