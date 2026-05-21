# benops-rpa

Claude Code plugin for the BenOps RPA team at Gusto.

## Skills

| Skill | Phase | Description | Invoke |
|---|---|---|---|
| `analyze` | test | Review branch changes for XAML issues before PR | `/analyze` |
| `benops-rpa-setup` | operate | Interactive VDI setup for new team members | `/benops-rpa-setup` |
| `benops-sync` | operate | Sync BenOps Notion Hub with GitHub PRs + Jira | `/benops-sync` |
| `benops-ticket-investigation` | operate | Structured production failure investigation | `/benops-ticket-investigation BT-XXXXX` |
| `benops-triage-agent` | operate | First-response triage for a support ticket | `/benops-triage-agent BT-XXXXX` |
| `followup` | operate | Daily status update to Sri/Oscar via Slack | `/followup` |
| `morning` | operate | Daily briefing: Slack + Jira + GitHub | `/morning` |
| `uipath-test-cases-from-ticket` | test | Create Staging test cases from a Jira ticket | `/uipath-test-cases-from-ticket BT-XXXXX` |

## MCP Requirements

| MCP | Skills that use it |
|---|---|
| Jira | `morning`, `followup`, `benops-sync`, `benops-ticket-investigation`, `benops-triage-agent`, `uipath-test-cases-from-ticket` |
| GitHub | `morning`, `followup`, `benops-sync`, `benops-ticket-investigation`, `benops-triage-agent` |
| Slack | `morning`, `followup`, `benops-triage-agent` |
| Notion | `benops-sync` |
| Google Sheets | `followup` |

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with the required frontmatter (`name`, `description`, `sdlc_phases`, `allowed-tools`)
2. Add a component entry to `.claude-plugin/plugin.json`
3. Add a row to the table above
4. Bump `version` in `plugin.json` (MINOR for new skills, PATCH for fixes)
5. Add an entry to `CHANGELOG.md`
