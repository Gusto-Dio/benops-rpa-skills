---
name: benops-sync
description: Use to sync the BenOps RPA Hub Notion page with current GitHub PR statuses and Jira ticket statuses. Call daily via /morning or standalone.
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, notiongusto]
allowed-tools: [mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__pull_request_read, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Notion_Gusto__notion-query-data-sources, mcp__claude_ai_Notion_Gusto__notion-update-page, mcp__claude_ai_Notion_Gusto__notion-fetch]
---

# /benops-sync — BenOps Notion Hub Sync

Sync the BenOps RPA Hub Notion page with current GitHub PR statuses and Jira ticket statuses.
Respond in English. All tool calls remain in English.

## Config
Update team members when the roster changes.

| Key | Value |
|---|---|
| Hub page ID | `35dad673c6c281ca9beed83cf58fdb22` |
| Processes DB ID | `ba7266d884b6425c9fc0036b483bd8d0` |
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

### STEP 2 — Fetch Processes database rows

Use `mcp__claude_ai_Notion_Gusto__notion-query-data-sources` on Config: Processes DB ID to get all current rows with their page IDs and current field values.

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

### STEP 4 — Apply updates

For each row with a status change:
Use `mcp__claude_ai_Notion_Gusto__notion-update-page` (page ID from Step 2) to update:
- `Status` → new derived status value
- `PR Number` → PR number + state string, e.g. "#2683 Open — Changes Requested" or "#2683 Merged"
- `Last Synced` → today's date in ISO 8601 format (YYYY-MM-DD)

### STEP 5 — Update hub home timestamp

Use `mcp__claude_ai_Notion_Gusto__notion-update-page` on Config: Hub page ID:
Replace the line `Synced daily via /benops-sync · Last synced: —` (or whatever the current timestamp is) with:
`Synced daily via /benops-sync · Last synced: YYYY-MM-DD HH:MM`

### STEP 6 — Report

Output:
```
### BenOps Sync complete
- X processes checked
- Y statuses updated: [list process names with status change]
- Timestamp updated on hub page
```

If no status changes detected: output "No status changes detected."
