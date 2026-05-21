---
name: followup
description: Send daily status update to Sri/Oscar via Slack. Reads Sheets queue, open PRs, and Jira tickets to compose a concise English update.
---

# /followup — Status Update to Sri

Send a concise daily status update via Slack. The user chooses the destination before sending.
Respond entirely in Portuguese (our conversation language). All Slack messages must be in English.

## Key identifiers
- Diogenes's Slack user ID: U0ARX71R5FS
- Sri Perinkolam: U07KMNHHFB6
- Oscar Nuñez: U05UYA9S4G7
- Group DM (Diogenes + Sri + Oscar): C0AV2UULSER
- BizTech RPA channel: C0AFP67B5AQ
- GitHub login: Gusto-Dio
- Jira Cloud ID: 3fd33630-4e39-4689-ad04-db32e3843117
- Sheets ID: 1jb2atbGZXusvwDCh9a8DocVnhe4QaU_Hcm2rl2Ue0T0
- Sheet tab: RPA BenOps Nov 2025

---

## Execution Plan

### STEP 1 — Gather context (run in parallel)

**A) Google Sheets — work queue**
Fetch the sheet tab " RPA BenOps Nov 2025" from spreadsheet `1jb2atbGZXusvwDCh9a8DocVnhe4QaU_Hcm2rl2Ue0T0`.
Filter rows where column E (Resource responsible) contains "Diogenes" (case-insensitive).
From those rows, extract:
- Column A: Ticket ID
- Column C: Priority
- Column K: Status
- Column P: Current Jira tkt (if filled)

Classify each ticket:
- **Current** — Status contains "In Progress" or "In Dev" or similar active state
- **Next** — Status is empty, "To Do", "Ready", "Backlog", or "Not Started"
- **Done** — Status is "Done" or "Completed" → EXCLUDE from the update

**B) GitHub — open PRs by Gusto-Dio**
Call list_pull_requests: owner=Gusto, repo=biztech-uipath-rpa, state=open, sort=updated, direction=desc, perPage=50.
Filter to PRs where author.login == "Gusto-Dio". Take the 3 most recent.
For each, get:
- PR number and title
- Review status: approved / changes requested / awaiting re-review / awaiting review
- CI status: passing / failing / pending

Use pull_request_read to verify each PR is still open (state == "open"). Discard merged/closed.

To determine review status:
- Latest review is "changes_requested" AND most recent comment/commit is by "Gusto-Dio" → "awaiting re-review"
- Latest review is "changes_requested" AND no response from Gusto-Dio after → "changes requested"
- Latest review is "approved" → "approved"
- No reviews yet → "awaiting review"

**C) Jira — active tickets**
Query: `assignee = currentUser() AND status in ("In Progress", "In Review") ORDER BY updated DESC`
Fields: summary, status, priority, updated

---

### STEP 2 — Determine current state

Based on the data:
- If there is a **current ticket** in the Sheets queue → Diogenes is actively working on it
- If all Sheets tickets are **Done** or there is no active ticket → Diogenes may be ready to pick up the next one
- List **next tickets** (up to 3) ordered by Priority (High first)

---

### STEP 3 — Compose the status message

Write a brief English message for Sri. Keep it factual and concise:

```
Hi Sri,

Here's my status for today (DATE):

*Currently working on:*
• [Ticket ID] — [short description] — [Jira link if available]
[If nothing active: "Finished current work and ready to pick up the next ticket."]

*PRs in flight:*
• #XXXX [PR title] — [review status] — [CI status]
[If none: omit this section]

*Up next (queue):*
• [Ticket ID] — [short description] — Priority: [High/Medium/Low]
[list up to 3 next tickets, or omit if queue is empty]

*Blockers:*
[Any PR with "changes requested" where Diogenes has NOT yet responded, or any stale Jira ticket. If none: omit this section.]

— Diogenes
```

---

### STEP 4 — Present draft and ask destination

Show the composed message to the user in Portuguese, then ask where to send:

"Aqui está o rascunho — para onde quer enviar?

**1.** DM para a Sri apenas
**2.** Grupo (eu, Sri e Oscar)
**3.** Canal #biztech-rpa"

Show the full draft message below the question.

Wait for the user's choice and any edits. Accept numeric answers (1, 2, 3) or natural language ("só pra sri", "grupo", "canal").

---

### STEP 5 — Send via Slack

Based on the chosen destination, send the message using slack_send_message:

**Option 1 — DM to Sri:**
Send to channel_id: U07KMNHHFB6

**Option 2 — Group DM (Diogenes + Sri + Oscar):**
Send to channel_id: C0AV2UULSER

**Option 3 — Channel:**
Send to channel_id: C0AFP67B5AQ

After sending, return the Slack message link and confirm in Portuguese:
- Option 1: "Enviado para a Sri ✓"
- Option 2: "Enviado para o grupo (Sri + Oscar) ✓"
- Option 3: "Enviado no canal ✓"
