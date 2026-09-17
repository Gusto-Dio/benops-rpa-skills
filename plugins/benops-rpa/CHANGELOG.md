# Changelog

All notable changes to this plugin are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: PATCH for bug fixes, MINOR for new skills, MAJOR for breaking changes.

## [1.5.1] — 2026-09-17

### Changed
- `ticket-fields`: writes **one field per call in a fixed order** instead of one combined `editJiraIssue`, so the two `Automation for Jira` rules that set **Start date** and **Due date** both fire. Order is Priority → Process → Complexity → **Status (`In Progress`, transition 41)** → **Story Points** → Sprint, Ticket Type? → Workaround Solutions, Category of Break
- `ticket-fields`: **Story Points is now written after the Status transition** — the only field whose position is forced. The Due date rule triggers on a Story Points change and writes `duedate = Start date + Story Points days`, skipping silently when Start date is empty and never retrying. Evidenced on BT-75657 (priority `Low`, never changed, Due date landed 2.19 s after Story Points) and BT-75495, against BT-75719 (Story Points 34 s before the transition — no Due date). Priority is not the trigger; it is written near Story Points during triage, which is what makes it look like one
- `ticket-fields`: transitions the ticket to `In Progress` when it is being picked up, and notes that `Under investigation` (111) fires neither automation
- `ticket-fields`: the verify read now covers `customfield_10015` (Start date) and `duedate` as well as the eight, and allows for the 1–9 s automation delay
- `ticket-fields`: `allowed-tools` gains `getTransitionsForJiraIssue` and `transitionJiraIssue`; description mentions a missing Start/Due date as a trigger

### Added
- `ticket-fields/references/field-map.md`: *The write order, and the two automations it feeds* — the trigger for each rule and the four changelogs it was derived from
- `ticket-fields/references/field-map.md`: *Transitions* — the BT transition ids (41 In Progress, 111 Under investigation, 71 Done, …) and the three fields the Done transition validates, which this skill does not set and so cannot close a ticket
- `OVERVIEW.md`: the write order and its two gotchas, in the team guide

## [1.5.0] — 2026-09-01

### Added
- `ticket-fields`: new skill. Fills the eight reportable fields on a BT support ticket — Priority, Complexity, Process, Category of Break, Workaround Solutions, Story Points, Sprint, Ticket Type?. Reads current values first, so it is idempotent; shows a table and waits for confirmation before writing; re-reads the eight afterwards to confirm the write landed
- `ticket-fields/references/field-map.md`: the Jira field ids, current option lists, per-field decision rules, and the API write shape for each field type. Verified against live `createmeta` and per-issue `editmeta` on project BT
- **First hook in this plugin.** `hooks/hooks.json` + `hooks/bt-ticket-fields-gate.sh` on `UserPromptSubmit`: when a prompt mentions a `BT-xxxxx`, adds a note pointing at `ticket-fields`. Non-blocking, pure bash, no external dependencies, strips path-bearing payload fields before matching
- `README.md`: `Hooks` and `Adding a hook` sections
- `OVERVIEW.md`: `Using ticket-fields` — team guide covering the eight fields, the two dead-option-list traps, and how to silence the hook

### Changed
- `benops-ticket-investigation`: added Phase 0 — invoke `ticket-fields` before pulling logs. Fields come from the intake text and the ticket's own dates, so this does not weaken the logs-before-code rule. Added `Skill` to `allowed-tools`
- `benops-triage-agent`: hands the eight reportable fields to `ticket-fields` so a single skill owns the field ids and option lists; notes BT's Story Points as `customfield_10041` and Sprint as `customfield_10020`
- `benops-triage-agent`: states that its companion `uipath-benops-triage` skill installs separately and is not part of this plugin, and to stop rather than improvise `uip` command shapes if it is absent
- `benops-triage-agent`: clarified that the `editJiraIssue` response returns only default read fields, so a focused `getJiraIssue` is the only confirmation a write landed

## [1.4.0] — 2026-05-21

### Changed
- `benops-sync`: added Incidents DB sync (STEP 5) — on each run, queries Jira for `issuetype = Bug` tickets (any status, last 30d), checks against existing Incidents DB rows by `Jira Ticket` field, and creates new rows for unrecorded incidents
- `benops-sync`: added `Incidents DB ID` to Config section
- `benops-sync`: added `notion-create-pages` to `allowed-tools`
- `benops-sync`: STEP numbering updated (Incidents = 5, timestamp = 6, report = 7)
- `benops-sync`: report now includes count of new incidents recorded; reminds to fill Root Cause and Fix Applied manually

## [1.3.0] — 2026-05-21

### Changed
- `analyze`: removed hardcoded absolute path (`C:\Users\...`) from all git and Select-String commands — now runs from CWD; works for any team member
- `analyze`: output template changed from Portuguese to English
- `morning`: all personal references (`@diogenes`, `Diogenes`, `Jonathan Boice`, etc.) moved out of execution steps — body now references Config keys only; output English
- `followup`: added `My name` and `Sheets name filter` to Config; removed hardcoded `"Diogenes"` from filter and signature; output English
- `benops-sync`: added `Config` section with Hub page ID, Processes DB ID, GitHub repo, Jira project, and team members (Jira usernames); output English; removed hardcoded JQL usernames from execution steps

## [1.2.0] — 2026-05-21

### Added
- `benops-ticket-investigation`: Phase 0 — on trigger, automatically updates the BenOps tracking spreadsheet:
  - Sets Status (column K) → `"In Progress"`
  - Sets `Dev Start Date` column → today's date (`YYYY-MM-DD`)
  - Non-blocking: if ticket not found in sheet, investigation continues and a warning is appended to the fix proposal
- `benops-ticket-investigation`: `Config` section with Sheets ID, tab name, and column mapping
- `gsheetsgusto` added to `requires_mcp`
- `mcp__claude_ai_Gsheets_Gusto__fetch` and `mcp__claude_ai_Gsheets_Gusto__update` added to `allowed-tools`

## [1.1.1] — 2026-05-21

### Fixed
- `marketplace.json`: changed plugin path key from `path` to `source` (e.g., `"source": "./plugins/benops-rpa"`) — required by Claude Code v2.1.146+ for plugin discovery
- `marketplace.json`: added `version` field and simplified `owner` to `{ "name": "..." }` matching `usp-shared` pattern
- `plugin.json`: removed MCP object arrays from `mcp` fields (replaced with `[]`) for compatibility with current Claude Code version

## [1.1.0] — 2026-05-21

### Added
- `plugin.json` with MCP dependencies declared per skill (`required` flag)
- `allowed-tools` declarations in all skill frontmatter — restricts each skill to its intended tool surface
- `requires_mcp` declarations in all skills that use external MCPs
- `sdlc_phases` tags for lifecycle categorization (`test`, `operate`)
- `references/` directory for `benops-ticket-investigation` with extracted procedure docs:
  - `references/orchestrator-log-queries.md` — REST API query sequence, tenant IDs, error pattern table
  - `references/investigation-rules.md` — red flags and common mistakes
- `Config` section in `morning` and `followup` skills — all user-specific IDs now clearly documented and overridable
- Plugin-level `README.md` and `CHANGELOG.md`

### Changed
- `benops-ticket-investigation/SKILL.md` condensed from ~200 to ~80 lines — detailed procedures moved to `references/`
- `followup/SKILL.md` — "Key identifiers" section replaced with structured `Config` table
- Repo restructured: all skills moved from flat root into `plugins/benops-rpa/skills/`

## [1.0.0] — 2026-05-21

### Added
- Initial release with 8 skills: `analyze`, `benops-rpa-setup`, `benops-sync`, `benops-ticket-investigation`, `benops-triage-agent`, `followup`, `morning`, `uipath-test-cases-from-ticket`
