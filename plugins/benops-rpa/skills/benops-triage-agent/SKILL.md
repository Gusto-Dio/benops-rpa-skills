---
name: benops-triage-agent
description: First-response triage for a BenOps RPA ticket. Reads Slack thread + JIRA ticket, diagnoses Production via uip + repo, optionally disables triggers (with confirmation), delegates the reportable fields to ticket-fields, posts business-facing Slack update and developer-handoff JIRA comment. Idempotent across reruns.
argument-hint: <BT-key | Slack-permalink>
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, slackgustoofficialmcp, githubgusto]
allowed-tools: [Bash(uip *), Read, Glob, Grep, mcp__claude_ai_Slack_Gusto_Offical__slack_read_thread, mcp__claude_ai_Slack_Gusto_Offical__slack_search_public_and_private, mcp__claude_ai_Slack_Gusto_Offical__slack_send_message, mcp__claude_ai_Jira_Confluence__getJiraIssue, mcp__claude_ai_Jira_Confluence__editJiraIssue, mcp__claude_ai_Jira_Confluence__addCommentToJiraIssue, mcp__claude_ai_Github-Gusto__pull_request_read, AskUserQuestion, Skill]
---

Invoke the `uipath-benops-triage` skill to triage the ticket identified by `$ARGUMENTS`.

The argument may be either a BT-key (e.g. `BT-72636`) or a Slack permalink that points to the originating thread in `#biztech-automations-support`. If empty, ask the user for one before proceeding.

Follow the full workflow in `~/.claude/skills/uipath-benops-triage/SKILL.md` end-to-end, including any `references/` files that skill ships alongside itself. Do not improvise on the verified `uip`, JIRA, Slack, or GitHub command shapes.

**That companion skill is installed separately and does not ship in this plugin** — neither it nor its `references/` live here. Check it is present before you start. If it is missing, say so plainly and stop: improvising `uip` command shapes against the Production tenant is exactly the risk this skill exists to remove.

Hard reminders before you start:

- Never call `uip login tenant set`. Pass `--tenant Production` per command.
- Never disable a trigger without explicit two-step confirmation (structured `AskUserQuestion` + textual `yes` in chat).
- **Leave the eight reportable fields to the `ticket-fields` skill** — Priority, Complexity, Process, Category of Break, Workaround Solutions, Story Points, Sprint, Ticket Type?. Invoke it rather than writing them here, so one skill owns the field ids and the current option lists. On **BT**, Story Points is `customfield_10041` and Sprint is `customfield_10020`.
- The `editJiraIssue` response is not evidence and cannot be suppressed — it echoes only the default read fields, none of the custom fields you wrote. Verify with a focused `getJiraIssue(fields=[...])`.
- All Slack posts go in-thread (`thread_ts` set). Never broadcast.
- All written output (Slack + JIRA) is English regardless of the on-call's working language.
