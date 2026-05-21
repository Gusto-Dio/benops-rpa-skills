---
name: benops-sync
description: Use to sync the BenOps RPA Hub Notion page with current GitHub PR statuses, Jira ticket statuses, and incident records. Call daily via /morning or standalone.
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, notiongusto]
allowed-tools: [mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__pull_request_read, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Notion_Gusto__notion-query-data-sources, mcp__claude_ai_Notion_Gusto__notion-update-page, mcp__claude_ai_Notion_Gusto__notion-fetch, mcp__claude_ai_Notion_Gusto__notion-create-pages]
---

# /benops-sync — BenOps Notion Hub Sync

Sync the BenOps RPA Hub Notion page with current GitHub PR statuses, Jira ticket statuses, and incident records.
Respond in English. All tool calls remain in English.

## Config
Update team members when the roster changes.

| Key | Value |
|---|---|
| Hub page ID | `35dad673c6c281ca9beed83cf58fdb22` |
| Processes DB ID | `ba7266d884b6425c9fc0036b483bd8d0` |
| Incidents DB ID | `5c5a55e5b865443ba41f31b19f8ea7b1` |
| GitHub repo | `Gusto/biztech-uipath-rpa` |
| Jira project | `BT` |
| Team members (Jira usernames) | `currentUser(), "oscar.nunez", "ahsen", "harinath"` |

---

## Execution Plan

### STEP 1 — Fetch current state (run in parallel)

1. Fetch all open PRs: `mcp__claude_ai_Github-Gusto__list_pull_requests` (owner: Gusto, repo: biztech-uipath-rpa, state: open)
2. Fetch recently merged PRs (last 7 days): same tool, state: closed
3. Fetch BenOps Jira tickets: `mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql`
   JQL: `project = BT AND assignee in (Config: Team members) AND updated >= -30d ORDER BY updated DESC`
   Fields to capture per ticket: `key`, `summary`, `status`, `issuetype`, `resolutiondate`, `created`, `assignee`

### STEP 2 — Fetch Processes database rows

Use `mcp__claude_ai_Notion_Gusto__notion-query-data-sources` on Config: Processes DB ID to get all current rows with their page IDs and current field values (including the `Jira Ticket` field for cross-referencing in Steps 3 and 5).

### STEP 3 — Build update map

For each row in Processes that has a non-empty Jira Ticket field:
1. Find matching Jira ticket in Step 1 results → get Jira status
2. Find matching PR in Step 1 PR lists by looking for `[BT-XXXXX]` in PR title → get PR state and review status
3. Derive new Status using this exact mapping:
   - Jira status = Done AND PR merged → "Deployed to Prod"
   - Jira status = Done AND PR open → "Ready for Deployment"
   - PR has review state = CHANGES_REQUESTED → "Pending Review"
   - PR open AND has review requests pending → "Pending Review"
   - Jira status = In Progress AND PR open → "In Progress"
   - Jira status = In Progress AND no PR found → "In Progress"
   - No Jira ticket match found AND no PR match found → skip (no update)
4. If derived status equals current Notion status → skip (no update needed)

### STEP 4 — Apply Processes updates

For each row with a status change:
Use `mcp__claude_ai_Notion_Gusto__notion-update-page` (page ID from Step 2) to update:
- `Status` → new derived status value
- `PR Number` → PR number + state string, e.g. "#2683 Open — Changes Requested" or "#2683 Merged"
- `Last Synced` → today's date in ISO 8601 format (YYYY-MM-DD)

### STEP 5 — Sync Incidents database

Populate the Incidents DB with new incident records from Bug tickets (any status — pending and resolved).

**5a. Fetch existing Incidents DB rows**
Use `mcp__claude_ai_Notion_Gusto__notion-query-data-sources` on Config: Incidents DB ID.
Collect all existing values from the `Jira Ticket` field to build a deduplication set.

**5b. Identify new incidents**
From Step 1 Jira results, filter tickets matching:
- `issuetype.name = "Bug"` (any status — pending and resolved are both tracked)

For each matching ticket, check: does its key (e.g. `BT-72018`) already exist in the Incidents DB `Jira Ticket` field?
- If YES → skip (already recorded)
- If NO → it is a new incident to create

**5c. Resolve Process name**
For each new incident ticket key, look up the Processes DB rows (Step 2) for a row whose `Jira Ticket` field matches the ticket key. If found, capture the Process row's name. If not found, leave Process blank.

**5d. Create new incident rows**
For each new incident, use `mcp__claude_ai_Notion_Gusto__notion-create-pages` with:
- Parent: Config: Incidents DB ID
- Properties:
  - `Title` (title): Jira ticket summary
  - `Date` (date): `resolutiondate` if the ticket is Done; otherwise the ticket `created` date (ISO 8601, e.g. `2026-05-21`)
  - `Process` (rich_text): process name from 5c, or blank
  - `Jira Ticket` (rich_text): ticket key (e.g. `BT-72018`)
  - `Root Cause` (rich_text): leave blank — fill manually
  - `Fix Applied` (rich_text): leave blank — fill manually

### STEP 6 — Update hub home timestamp

Use `mcp__claude_ai_Notion_Gusto__notion-update-page` on Config: Hub page ID:
Replace the line `Synced daily via /benops-sync · Last synced: —` (or whatever the current timestamp is) with:
`Synced daily via /benops-sync · Last synced: YYYY-MM-DD HH:MM`

### STEP 7 — Report

Output:
```
### BenOps Sync complete
- X processes checked, Y statuses updated: [list process names with status change]
- Z new incidents recorded: [list ticket keys + summaries]
- Timestamp updated on hub page
```

If no status changes and no new incidents: output "No changes detected."
If new incidents were created, remind: "Root Cause and Fix Applied fields are blank — fill in manually on the Incidents page."
