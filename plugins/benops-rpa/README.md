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
| `ticket-fields` | operate | Fill the eight reportable fields on a BT ticket | `/ticket-fields BT-XXXXX` |
| `uipath-test-cases-from-ticket` | test | Create Staging test cases from a Jira ticket | `/uipath-test-cases-from-ticket BT-XXXXX` |

## MCP Requirements

| MCP | Skills that use it |
|---|---|
| Jira | `morning`, `followup`, `benops-sync`, `benops-ticket-investigation`, `benops-triage-agent`, `ticket-fields`, `uipath-test-cases-from-ticket` |
| GitHub | `morning`, `followup`, `benops-sync`, `benops-ticket-investigation`, `benops-triage-agent` |
| Slack | `morning`, `followup`, `benops-triage-agent` |
| Notion | `benops-sync` |
| Google Sheets | `followup` |

## Hooks

| Event | Script | What it does |
|---|---|---|
| `UserPromptSubmit` | `hooks/bt-ticket-fields-gate.sh` | Sees a `BT-xxxxx` in your prompt → reminds the agent to run `ticket-fields` first |

Wired up by `hooks/hooks.json`; Claude Code discovers it automatically when the plugin is
enabled. **Non-blocking** — it adds a note to the agent's context and nothing else, so it can
never stop a prompt from running.

It only reads the prompt text. Mention the ticket key and it fires; say "fix this Anthem bot"
without a key and it stays quiet. Filesystem paths in the payload are stripped before matching,
so working in a folder named after a ticket does not trigger it.

To turn it off for yourself, disable the plugin's hooks in `/config`, or add a
`UserPromptSubmit` matcher in your own `settings.json` — it does not need to be edited here.

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with the required frontmatter (`name`, `description`, `sdlc_phases`, `allowed-tools`)
2. Add a component entry to `.claude-plugin/plugin.json`
3. Add a row to the table above
4. Bump `version` in `plugin.json` (MINOR for new skills, PATCH for fixes)
5. Add an entry to `CHANGELOG.md`

## Adding a hook

1. Create `hooks/<name>.sh` — pure bash, no `jq`/`node`/`python`, and it must `exit 0` on every
   path. A hook that dies on a missing dependency breaks every prompt for everyone.
2. Register it in `hooks/hooks.json` as `bash "${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh"` — never an
   absolute path, or it works only on the machine that wrote it.
3. Add a component entry (`"type": "hook"`) to `.claude-plugin/plugin.json` and a row above.
4. Test it by piping realistic payloads in: `echo '{"prompt":"..."}' | bash hooks/<name>.sh`.
   Cover the no-match, malformed-input and empty-stdin cases, not just the happy path.
