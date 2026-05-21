# benops-rpa-skills

Claude Code skills for the BenOps RPA team at Gusto.

## Structure

Each skill lives in its own subfolder. The folder name is the skill name.

```
benops-rpa-skills/
├── analyze/
│   └── SKILL.md          # Review current branch changes for XAML issues before PR
├── benops-rpa-setup/
│   └── SKILL.md          # VDI setup for new team members
├── benops-sync/
│   └── SKILL.md          # Daily sync of BenOps Notion Hub with GitHub PRs + Jira
├── benops-ticket-investigation/
│   └── SKILL.md          # Structured investigation for production failures
├── benops-triage-agent/
│   └── SKILL.md          # First-response triage for a BenOps RPA support ticket
├── followup/
│   └── SKILL.md          # Daily status update to Sri/Oscar via Slack
├── morning/
│   └── SKILL.md          # Daily briefing: Slack + Jira + GitHub priority sweep
└── uipath-test-cases-from-ticket/
    └── SKILL.md          # Create Staging test cases from a Jira ticket
```

## Installing a skill

Run the two commands below in the VDI terminal, replacing `<skill-name>` with the folder name:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\commands\<skill-name>"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Gusto-Dio/benops-rpa-skills/main/<skill-name>/SKILL.md" -OutFile "$env:USERPROFILE\.claude\commands\<skill-name>.md"
```

Then open Claude Code and type `/<skill-name>` to invoke it.

## Available skills

| Skill | Description | Invoke |
|---|---|---|
| `analyze` | Reviews current branch diff for XAML issues, naming conventions, selector quality, and uncommitted modifications — run before any PR | `/analyze` |
| `benops-rpa-setup` | Interactive VDI setup for new BenOps RPA team members — installs tools, plugins, and configures MCPs | `/benops-rpa-setup` |
| `benops-sync` | Syncs the BenOps RPA Hub Notion page with current GitHub PR statuses and Jira ticket statuses — call daily via `/morning` or standalone | `/benops-sync` |
| `benops-ticket-investigation` | Structured investigation workflow for production failures — enforces Orchestrator logs before XAML code analysis | `/benops-ticket-investigation BT-XXXXX` |
| `benops-triage-agent` | First-response triage for a BenOps RPA support ticket — reads Slack thread + Jira, diagnoses Production, posts business-facing update | `/benops-triage-agent BT-XXXXX` |
| `followup` | Composes and sends daily status update to Sri/Oscar via Slack — reads Sheets queue, open PRs, and Jira | `/followup` |
| `morning` | Daily briefing: priority contacts sweep (Jonathan/Oscar/Sri), Slack alerts, active Jira tickets, open PRs, next ticket suggestion | `/morning` |
| `uipath-test-cases-from-ticket` | Creates UiPath Staging test cases from a Jira ticket — samples Production queue items and launches recreator job | `/uipath-test-cases-from-ticket BT-XXXXX` |

## Adding a new skill

1. Create a subfolder with the skill name: `my-new-skill/`
2. Add a `SKILL.md` file following the [agentskills.io spec](https://agentskills.io/specification)
3. Add a row to the table above
