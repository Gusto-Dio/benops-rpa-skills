---
name: morning
description: Daily briefing — reads Slack, Jira, and GitHub in parallel. Covers priority contacts (Jonathan, Oscar, Sri), alerts, active tickets, open PRs, and next ticket suggestion.
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, slackgustoofficialmcp]
allowed-tools: [mcp__claude_ai_Slack_Gusto_Offical__slack_search_public_and_private, mcp__claude_ai_Slack_Gusto_Offical__slack_read_channel, mcp__claude_ai_Slack_Gusto_Offical__slack_read_thread, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Jira_Confluence__getJiraIssue, mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__pull_request_read, Skill, Agent]
---

# /morning — Daily Briefing

Run a structured daily briefing by reading Slack, Jira, and GitHub in parallel.
Respond entirely in Portuguese (our conversation language). All tool calls and external content remain in English.

## Config
Update these values when deploying for a different user.

| Key | Value |
|---|---|
| My Slack handle | `@diogenes` |
| My Jira username | `diogenes.ribeiro` |
| Priority contacts | Jonathan Boice, Oscar Nunez, Sri |
| Jira Cloud ID | `3fd33630-4e39-4689-ad04-db32e3843117` |
| GitHub login | `Gusto-Dio` |

---

## Execution Plan

Run the following steps using parallel sub-agents where possible.

---

### STEP 1 — Priority Contacts Sweep (highest priority, run first)

Search Slack and other tools for any activity from these three people:
- **Jonathan Boice**
- **Oscar Nunez**
- **Sri** (search for "Sri" as first name)

For each person, check:
1. Did they send me a direct message in the last 24h?
2. Did they mention me (`@diogenes`) in any channel in the last 24h?
3. Did they comment on any of my GitHub PRs?
4. Did they assign a Jira ticket to me or mention me in a ticket comment?
5. Did they share a document, Confluence page, or Sheets link that requires my review or validation?

For each finding, capture: who sent it, what it is, where (channel/tool), and what action it likely requires from me.

---

### STEP 2 — Slack Overview (last 16 hours)

Search the following Slack channels for relevant activity:
- Any channel related to BizTech, RPA, automation, or carrier integrations
- Any channel where I was mentioned (`@diogenes`) or DMs sent to me
- Look for: incident alerts, urgent bugs, deployment failures, process failures, PR review requests

Capture: channel name, sender, summary of message, required action if any.

---

### STEP 3 — Jira Board

Query Jira for:
1. My tickets with status `In Progress` or `In Review`
2. Tickets assigned to me with status `To Do` or `Ready` (sorted by priority)
3. Tickets where I was mentioned in a comment in the last 24h
4. Any ticket updated or commented on by Jonathan Boice, Oscar Nunez, or Sri

For each ticket: ID, title, status, last update, and what the next action is.

---

### STEP 4 — GitHub PRs

Check the `Gusto/biztech-uipath-rpa` repository for:
1. My open PRs — check CI status (Buildkite), review requests, and pending comments
2. PRs where I was requested as reviewer
3. Any PR comments or reviews from Jonathan Boice, Oscar Nunez, or Sri in the last 24h

---

### STEP 5 — Synthesize and Present

Present the briefing in this exact structure (in Portuguese):

```
## Bom dia, Diogenes 👋

### 🔴 Ação imediata (contatos prioritários)
[List findings from Step 1 — any message/ticket/PR from Jonathan Boice, Oscar Nunez, or Sri]
[If none: "Nada de Jonathan, Oscar ou Sri nas últimas 24h."]

### ⚡ Urgências e alertas
[Incidents, broken bots, urgent Slack messages, CI failures]
[If none: "Nenhuma urgência identificada."]

### 📋 Tickets ativos
[In Progress tickets with current status and next action]

### 📬 PRs aguardando ação
[Open PRs with CI status and pending reviews]

### 📌 Próximo ticket sugerido
[Top priority To Do ticket with brief reason why]

### 📅 Resumo do dia
[2-3 sentences: what to focus on today, in what order, and why]
```

Keep each section tight — one line per item where possible. If a section is empty, say so in one line rather than omitting it.

Do not include raw message dumps or full ticket descriptions. Summarize to the minimum needed for me to decide what to do next.

Always end the briefing with this fixed block, exactly as written:

```
### 🛠️ Suas ferramentas
/morning · /benops-ticket-investigation BT-XXXXX · /analyze · /followup · /benops-sync
```

If the **Urgências e alertas** section contains any broken bot, Orchestrator failure, or unexplained error, add this line immediately after that section (not in the fixed block):

> "Para diagnosticar: use `superpowers:systematic-debugging` — protocolo estruturado de causa raiz."

---

### STEP 6 — Sync BenOps Notion Hub

After presenting the briefing, run `/benops-sync` to update the Processes database.
This step runs silently — if sync completes with no changes, append only one line to the briefing:
> "🔄 BenOps Hub sincronizado."
If there were status changes, append the full sync summary block from `/benops-sync` output.
