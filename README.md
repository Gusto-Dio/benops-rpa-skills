# benops-rpa-skills

Claude Code skills for the BenOps RPA team at Gusto.

## Structure

```
benops-rpa-skills/
└── plugins/
    └── benops-rpa/
        ├── .claude-plugin/
        │   └── plugin.json         ← metadata, MCP deps, version
        ├── skills/
        │   ├── analyze/SKILL.md
        │   ├── benops-rpa-setup/SKILL.md
        │   ├── benops-sync/SKILL.md
        │   ├── benops-ticket-investigation/
        │   │   ├── SKILL.md
        │   │   └── references/
        │   │       ├── orchestrator-log-queries.md
        │   │       └── investigation-rules.md
        │   ├── benops-triage-agent/SKILL.md
        │   ├── followup/SKILL.md
        │   ├── morning/SKILL.md
        │   ├── ticket-fields/
        │   │   ├── SKILL.md
        │   │   └── references/
        │   │       └── field-map.md ← BT Jira field ids, option lists, write shapes
        │   └── uipath-test-cases-from-ticket/SKILL.md
        ├── hooks/                   ← fire automatically, nothing to invoke
        │   ├── hooks.json
        │   └── bt-ticket-fields-gate.sh
        ├── CHANGELOG.md
        └── README.md               ← plugin-level docs
```

## Installing a skill

Run the command below in the VDI terminal, replacing `<skill-name>` with the folder name:

```powershell
$skillName = "<skill-name>"
$base = "https://raw.githubusercontent.com/Gusto-Dio/benops-rpa-skills/main/plugins/benops-rpa/skills"
Invoke-WebRequest -Uri "$base/$skillName/SKILL.md" -OutFile "$env:USERPROFILE\.claude\commands\$skillName.md"
```

Then open Claude Code and type `/<skill-name>` to invoke it.

## Available skills

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

## Adding a new skill

1. Create `plugins/benops-rpa/skills/<name>/SKILL.md` with frontmatter (`name`, `description`, `sdlc_phases`, `allowed-tools`)
2. Add a component entry to `plugins/benops-rpa/.claude-plugin/plugin.json`
3. Add a row to the table above and to `plugins/benops-rpa/README.md`
4. Bump `version` in `plugin.json` (MINOR for new skills, PATCH for fixes)
5. Add an entry to `plugins/benops-rpa/CHANGELOG.md`
