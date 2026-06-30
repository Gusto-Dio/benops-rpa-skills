---
name: benops-sync
description: Use to sync the BenOps RPA Hub Notion page with current GitHub PR statuses, Jira ticket statuses, library versions, migration progress, and broken bot status. Call daily via /morning or standalone.
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, notiongusto, gsheetsgusto]
allowed-tools: [mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__pull_request_read, mcp__claude_ai_Github-Gusto__get_file_contents, mcp__claude_ai_Github-Gusto__get_repository_tree, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Notion_Gusto__notion-query-data-sources, mcp__claude_ai_Notion_Gusto__notion-update-page, mcp__claude_ai_Notion_Gusto__notion-fetch, mcp__claude_ai_Notion_Gusto__notion-create-pages, mcp__claude_ai_Gsheets_Gusto__fetch, mcp__claude_ai_Gsheets_Gusto__get_metadata, Bash(uip *)]
---

# /benops-sync — BenOps Notion Hub Sync

Sync the BenOps RPA Hub Notion page with current GitHub PR statuses, Jira ticket statuses, library versions, migration progress, and broken bot status.

> **Language rule:** Every value written to Notion — field values, notes, PR strings, status labels, timestamps — must be in English. Never write Portuguese into any Notion field.

## Config
Update when roster, repo, or DB IDs change.

| Key | Value |
|---|---|
| Hub page ID | `35dad673c6c281ca9beed83cf58fdb22` |
| Processes DB ID | `ba7266d884b6425c9fc0036b483bd8d0` |
| Library DB ID | `de5770484c4949e9844cee53b7b35527` |
| Library DB data source ID | `27a0a131-61fe-4a8e-9101-3b83290c7718` |
| Migration Process DB ID | `91ca8364dbe7465c8b2970a9e08e115e` |
| Migration Process DB data source ID | `8f76f0bf-d36a-4df9-b3ee-66a0c2b4d533` |
| Broken Bots DB ID | `c49448fc6f874ddab5e3ab623b75f08d` |
| Broken Bots DB data source ID | `f1bce4c4-0e36-4102-8b4e-82cb3fee6bc0` |
| GitHub repo | `Gusto/biztech-uipath-rpa` |
| Orchestrator Libraries feed | `https://cloud.uipath.com/gustoinc/Production/orchestrator_/odata/Libraries?$top=100` |
| Jira project | `BT` |
| Team members (Jira usernames) | `currentUser(), "oscar.nunez", "ahsen", "harinath"` |
| Migration Process spreadsheet ID | `1Fx5Yt8Up3JhpPFhbokRXbQgr7UiTA38dGClY3Oxzoi8` |
| Broken Bots spreadsheet ID | `1cdD4q1wZqUvfqRIalBAglbm_ky9Pbr7O_4bkaIFsa9g` |

---

## Execution Plan

### STEP 0 — Orchestrator login check

Run the following health check **before any other step**:

```bash
uip user
```

If the command fails or returns no user → run:

```bash
uip login
```

> Tell the user: "Orchestrator login required. Please run `! uip login` in the prompt to authenticate via browser, then confirm when done."
> Wait for user confirmation before continuing.

After confirming login (or if `uip user` succeeded), validate the production tenant:

```bash
uip or jobs list --folder-path "Benefits/CarrierAutomation" --limit 1
```

- If `Data` is non-empty → production tenant confirmed, proceed.
- If `Data` is empty → wrong tenant (probably staging). Tell the user:
  > "uip is authenticated but pointing to the wrong tenant. Please run `! uip login` to re-authenticate and select the **Production** org, then confirm."
  > Wait for user confirmation, then re-run the validation before proceeding.

---

### STEP 1 — Fetch current state (run all in parallel)

**1a.** Open PRs: `mcp__claude_ai_Github-Gusto__list_pull_requests`
- owner: `Gusto`, repo: `biztech-uipath-rpa`, state: `open`

**1b.** Recently closed/merged PRs (last 7 days): same tool, state: `closed`

**1c.** BenOps Jira tickets: `mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql`
- JQL: `project = BT AND assignee in (currentUser(), "oscar.nunez", "ahsen", "harinath") AND updated >= -30d ORDER BY updated DESC`
- Fields per ticket: `key`, `summary`, `status`, `issuetype`, `resolutiondate`, `created`, `assignee`

**1d.** ALL Library DB rows: `mcp__claude_ai_Notion_Gusto__notion-query-data-sources`
- Query: `SELECT * FROM "collection://27a0a131-61fe-4a8e-9101-3b83290c7718"`
- Capture per row: `id`, `Library`, `GitHub Version`, `Orchestrator Version`, `Status`

**1e.** ALL Migration Process DB rows: `mcp__claude_ai_Notion_Gusto__notion-query-data-sources`
- Query: `SELECT * FROM "collection://8f76f0bf-d36a-4df9-b3ee-66a0c2b4d533"`
- Capture per row: `id`, `Process Name`, `Type`, `Resource`, `Migrated to Modern`, `Date of Migration`, `Status`

**1f.** ALL Broken Bots DB rows: `mcp__claude_ai_Notion_Gusto__notion-query-data-sources`
- Query: `SELECT * FROM "collection://f1bce4c4-0e36-4102-8b4e-82cb3fee6bc0"`
- Capture per row: `id`, `Process Name`, `Carrier`, `Status`

---

### STEP 2 — Fetch Processes DB rows

Use `mcp__claude_ai_Notion_Gusto__notion-query-data-sources` on Config: Processes DB ID.
Capture all rows with: page `id`, `Process`, `Status`, `PR Number`, `Jira Ticket`, `Last Synced`.

---

### STEP 3 — Build Processes update map

For each Processes row with a non-empty `Jira Ticket` field:
1. Find matching Jira ticket from Step 1c by ticket key → get Jira `status`
2. Find matching PR from Steps 1a/1b by searching for `[BT-XXXXX]` in PR title → get PR state and review status
3. Derive new Status:

| Condition | Derived Status |
|---|---|
| Jira = Done AND PR merged | `"Deployed to Prod"` |
| Jira = Done AND PR open | `"Ready for Deployment"` |
| PR review state = CHANGES_REQUESTED | `"Pending Review"` |
| PR open AND has pending review requests | `"Pending Review"` |
| Jira = In Progress AND PR open | `"In Progress"` |
| Jira = In Progress AND no PR found | `"In Progress"` |
| No Jira match AND no PR match | skip — no update |

4. If derived status equals current Notion status → skip

---

### STEP 4 — Apply Processes updates

For each row with a status change, use `mcp__claude_ai_Notion_Gusto__notion-update-page`:
- `Status` → derived status
- `PR Number` → e.g. `"#2683 Open — Changes Requested"` or `"#2683 Merged"`
- `date:Last Synced:start` → today's date (YYYY-MM-DD)

---

### STEP 5 — Sync Library DB

**5a. Fetch Orchestrator versions**

```bash
uip orchestrator library list --output json
```

If unavailable, fetch via REST: GET Config: Orchestrator Libraries feed.

> ⚠️ Do NOT use `uip package list` — reads from Processes feed and returns stale versions.

Capture: `{ packageName → orchVersion }` map.

**5b. Fetch GitHub library folders (parallel with 5a)**

Use `mcp__claude_ai_Github-Gusto__get_repository_tree` to list root-level directories:
- owner: `Gusto`, repo: `biztech-uipath-rpa`, recursive: `false`

Filter entries where the name starts with `Gusto_` — these are library packages.

For each matching folder, read `{folderName}/project.json` via `mcp__claude_ai_Github-Gusto__get_file_contents` and extract `projectVersion`. If not found → version = `""`.

Capture: `{ packageName → githubVersion }` map.

**5c. Find new libraries**

Union all package names from 5a + 5b.
Any name NOT found in Library DB rows (Step 1d) → new library to create.

**5d. Derive Status for all libraries** (existing and new)

| Condition | Status |
|---|---|
| GitHub version = Orchestrator version | `"Up to Date"` |
| GitHub version > Orchestrator version (semver) | `"Behind"` |
| Orchestrator version > GitHub version (semver) | `"Orch Ahead"` |
| GitHub version exists, Orchestrator empty | `"Not Deployed"` |
| Orchestrator version exists, GitHub empty | `"Orchestrator Only"` |

**5e. Update existing Library DB rows**

For each existing row where `GitHub Version`, `Orchestrator Version`, or `Status` changed, use `mcp__claude_ai_Notion_Gusto__notion-update-page` to update the changed fields.
Skip rows with no change.

**5f. Create new Library rows**

For each new library from 5c, use `mcp__claude_ai_Notion_Gusto__notion-create-pages`:
- Parent database: Config: Library DB ID
- Properties:
  - `Library` (title): package name
  - `GitHub Version` (text): from 5b, or empty
  - `Orchestrator Version` (text): from 5a, or empty
  - `Status` (select): derived from 5d
  - Leave `Framework`, `Type`, `BenOps`, `Depends On`, `Notes` blank — fill manually

---

### STEP 6 — Sync Migration Process DB

**6a. Fetch Google Sheets source data**

Use `mcp__claude_ai_Gsheets_Gusto__fetch` for each tab of Config: Migration Process spreadsheet ID.
Tabs to fetch: `GroupSubmission`, `MemberSubmission`, `Reconciliation`, `PacketCollection`.

Capture per row: `Process Name`, `Type`, `Resource`, `Migrated to Modern`, `Date of Migration`, `Status`, `Dependencies`, `Comments`.

Build a deduplicated master list by `Process Name` across all 4 tabs.
If the same process name appears in multiple tabs, keep the first occurrence (tab order above).

**6b. Find new bots (in spreadsheet but not in Notion)**

For each bot in the spreadsheet master list, check if `Process Name` matches any row in Migration Process DB (Step 1e, case-insensitive).
- If no match → add to "to create" list

**6c. Derive migration status for existing Notion rows**

For each row in Migration Process DB (Step 1e):

| Condition | Derived Status |
|---|---|
| `Migrated to Modern` = true in Notion | skip — already final, no change |
| Jira ticket (Step 1c) summary contains process name AND status = Done | `"Migrated"` + capture `resolutiondate` as Date of Migration |
| Jira ticket matches AND status = In Progress | `"In Progress"` |
| Open PR title (Step 1a) contains process name | `"In Progress"` |
| None of the above | `"Pending"` |

If derived status = current Notion status → skip.

**6d. Update existing Migration Process rows**

For each row with a status change, use `mcp__claude_ai_Notion_Gusto__notion-update-page`:
- `Status` (select): derived status
- `Migrated to Modern` (checkbox): set `true` if derived status = `"Migrated"`
- `date:Date of Migration:start`: if `resolutiondate` was captured in 6c (ISO 8601, YYYY-MM-DD)

**6e. Create new Migration Process rows**

For each bot from 6b, use `mcp__claude_ai_Notion_Gusto__notion-create-pages`:
- Parent database: Config: Migration Process DB ID
- Properties (from spreadsheet row):
  - `Process Name` (title): process name
  - `Type` (select): from spreadsheet, if available
  - `Resource` (select): from spreadsheet, if available
  - `Migrated to Modern` (checkbox): from spreadsheet (true/false)
  - `date:Date of Migration:start`: from spreadsheet (ISO 8601), if available
  - `Status` (select): derive per 6c; if spreadsheet `Migrated to Modern` = true → `"Migrated"`, else derive from Jira/PRs
  - `Dependencies` (rich_text): from spreadsheet, if available
  - `Comments` (rich_text): from spreadsheet, if available

---

### STEP 7 — Sync Broken Bots DB

**7a. Fetch Google Sheets source data**

Use `mcp__claude_ai_Gsheets_Gusto__fetch` on Config: Broken Bots spreadsheet ID.
Capture per row: `Process Name`, `Carrier`, and any status or root cause fields available.

**7b. Build deduplication set**

Collect all existing Notion Broken Bots rows (Step 1f) as a set keyed by `Process Name + Carrier` (lowercase, trimmed).

**7c. Find new broken bots**

**Source 1 — Google Sheets:**
For each spreadsheet row, check if `Process Name + Carrier` is in the dedup set.
- If no match → add to "to create" list.

**Source 2 — Jira Bug tickets:**
From Step 1c, filter tickets where `issuetype = Bug`.
For each Bug ticket not matched to any existing Notion row (check if ticket summary contains any existing Process Name):
- If no match → add to "to create" list.

**Cross-source dedup:** if the same `Process Name` appears from both Sheets and Jira, only create one row.

**7d. Update existing Broken Bots rows**

For each existing Notion row, find a matching Jira Bug ticket (Step 1c, `issuetype = Bug`, check if ticket summary contains the Process Name):
- Ticket found AND status = Done → `Status` = `"Fixed"`
- Ticket found AND status ≠ Done → `Status` = `"Pending"`
- No ticket found → no change

Skip if derived status = current Notion status.

Use `mcp__claude_ai_Notion_Gusto__notion-update-page` for each changed row.

**7e. Create new Broken Bots rows**

For each new bot from 7c, use `mcp__claude_ai_Notion_Gusto__notion-create-pages`:
- Parent database: Config: Broken Bots DB ID
- Properties:
  - `Process Name` (title): process name
  - `Carrier` (select): carrier if available, else leave empty
  - `Status` (select): `"Fixed"` if Jira ticket is Done or spreadsheet indicates resolved; otherwise `"Pending"`
  - Leave `Priority`, `Root Cause`, `Contributing Factor`, `Volume`, `Impact`, `Key Learnings`, `Next Steps`, `Dependency` blank — fill manually

---

### STEP 8 — Update hub timestamp

Use `mcp__claude_ai_Notion_Gusto__notion-update-page` on Config: Hub page ID.
Replace the existing timestamp line with:
```
Synced daily via /benops-sync (GitHub PRs + Jira tickets) · Last synced: YYYY-MM-DD HH:MM
```

---

### STEP 9 — Report

Output in English:

```
### BenOps Sync complete
- Processes: X checked, Y statuses updated: [list process names + old → new status]
- Libraries: X checked, Y updated, Z new rows created: [list names + what changed]
- Migration Process: X bots checked, Y statuses updated, Z new rows created
- Broken Bots: X checked, Y statuses updated (A Fixed / B Pending), Z new rows created
- Timestamp updated on hub page
```

If no changes in any DB: output `No changes detected.`
If new rows were created: append `"New rows in [DB names] created with minimal data — fill blank fields manually."`
